// SPDX-License-Identifier: GPL-2.0-or-later
import Cocoa
import Darwin

struct DiscoveredPrinter: Codable {
  var name: String
  var ip: String
  var source: String
}
func normalizedIPv4(_ text: String) -> String? {
  let p = text.trimmingCharacters(in: .whitespacesAndNewlines).split(
    separator: ".", omittingEmptySubsequences: false)
  guard p.count == 4,
    p.allSatisfy({
      !$0.isEmpty && $0.count <= 3 && $0.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 })
        && (Int($0) ?? 256) <= 255
    })
  else { return nil }
  return p.map { String(Int($0)!) }.joined(separator: ".")
}
func isPhaser6010(_ text: String) -> Bool {
  let t = text.lowercased()
  return t.contains("6010") && (t.contains("xerox") || t.contains("phaser"))
}
// Minimal BER codec: response identity is taken only from SNMP octet strings.
enum SNMPIdentity {
  static func tlv(_ tag: UInt8, _ data: [UInt8]) -> [UInt8] {
    precondition(data.count < 128)
    return [tag, UInt8(data.count)] + data
  }
  static func request() -> [UInt8] {
    let oid: [UInt8] = [43, 6, 1, 2, 1, 25, 3, 2, 1, 3, 1]  // hrDeviceDescr.1
    let variable = tlv(0x30, tlv(6, oid) + [5, 0])
    let pdu = tlv(0xa0, [2, 2, 0x17, 0x7a, 2, 1, 0, 2, 1, 0] + tlv(0x30, variable))
    return tlv(0x30, [2, 1, 0] + tlv(4, Array("public".utf8)) + pdu)
  }
  static func identity(_ data: Data) -> String? {
    let b = Array(data)
    var strings: [String] = []
    func walk(_ begin: Int, _ end: Int, _ depth: Int) {
      guard depth < 10 else { return }
      var i = begin
      while i + 2 <= end {
        let tag = b[i]
        i += 1
        var n = Int(b[i])
        i += 1
        if n & 128 != 0 {
          let count = n & 127
          guard count > 0, count <= 4, i + count <= end else { return }
          n = 0
          for _ in 0..<count {
            n = (n << 8) | Int(b[i])
            i += 1
          }
        }
        guard n >= 0, n <= end - i else { return }
        if tag == 4, let s = String(bytes: b[i..<i + n], encoding: .utf8) { strings.append(s) }
        if tag & 0x20 != 0 { walk(i, i + n, depth + 1) }
        i += n
      }
    }
    walk(0, b.count, 0)
    return strings.first(where: isPhaser6010)
  }
  static func scan(knownIP: String?, found: @escaping (DiscoveredPrinter) -> Void) {
    DispatchQueue.global(qos: .utility).async {
      let fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
      guard fd >= 0 else { return }
      defer { close(fd) }
      var yes: Int32 = 1
      setsockopt(fd, SOL_SOCKET, SO_BROADCAST, &yes, socklen_t(MemoryLayout.size(ofValue: yes)))
      var timeout = timeval(tv_sec: 0, tv_usec: 250000)
      setsockopt(
        fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout.size(ofValue: timeout)))
      var targets = Set<String>()
      if let ip = knownIP, let valid = normalizedIPv4(ip) { targets.insert(valid) }
      var list: UnsafeMutablePointer<ifaddrs>?
      if getifaddrs(&list) == 0 {
        var p = list
        while let item = p {
          let a = item.pointee
          let flags = Int32(a.ifa_flags)
          if flags & IFF_UP != 0, flags & IFF_BROADCAST != 0, flags & IFF_LOOPBACK == 0,
            let dst = a.ifa_dstaddr, dst.pointee.sa_family == UInt8(AF_INET)
          {
            var address = UnsafeRawPointer(dst).assumingMemoryBound(to: sockaddr_in.self).pointee
              .sin_addr
            var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            if inet_ntop(AF_INET, &address, &buffer, socklen_t(buffer.count)) != nil {
              targets.insert(String(cString: buffer))
            }
          }
          p = a.ifa_next
        }
        freeifaddrs(list)
      }
      let packet = request()
      for ip in targets {
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = UInt16(161).bigEndian
        _ = ip.withCString { inet_pton(AF_INET, $0, &address.sin_addr) }
        _ = withUnsafePointer(to: &address) { p in
          p.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            sendto(fd, packet, packet.count, 0, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
          }
        }
      }
      let deadline = Date().addingTimeInterval(3)
      while Date() < deadline {
        var buffer = [UInt8](repeating: 0, count: 8192)
        var source = sockaddr_in()
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        let count = withUnsafeMutablePointer(to: &source) { p in
          p.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            recvfrom(fd, &buffer, buffer.count, 0, $0, &len)
          }
        }
        if count > 0, let name = identity(Data(buffer.prefix(count))) {
          var bytes = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
          var addr = source.sin_addr
          if inet_ntop(AF_INET, &addr, &bytes, socklen_t(bytes.count)) != nil {
            let printer = DiscoveredPrinter(
              name: name, ip: String(cString: bytes), source: "Rilevata in rete")
            DispatchQueue.main.async { found(printer) }
          }
        }
      }
    }
  }
}
final class PrinterDiscovery: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
  var onUpdate: (([DiscoveredPrinter], Bool) -> Void)?
  private var browsers: [NetServiceBrowser] = [], services: [NetService] = [],
    printers: [String: DiscoveredPrinter] = [:]
  private var timer: Timer?
  private var generation = 0
  private var searching = false
  func start(knownIP: String?) {
    stop()
    generation += 1
    let run = generation
    printers.removeAll()
    searching = true
    publish()
    for type in ["_pdl-datastream._tcp.", "_printer._tcp.", "_ipp._tcp.", "_ipps._tcp."] {
      let b = NetServiceBrowser()
      b.delegate = self
      browsers.append(b)
      b.searchForServices(ofType: type, inDomain: "local.")
    }
    SNMPIdentity.scan(knownIP: knownIP) { [weak self] p in
      guard let self = self, self.generation == run else { return }
      self.printers[p.ip] = p
      self.publish()
    }
    timer = Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { [weak self] _ in
      self?.searching = false
      self?.publish()
    }
  }
  func stop() {
    timer?.invalidate()
    browsers.forEach { $0.stop() }
    services.forEach { $0.stop() }
    browsers = []
    services = []
    searching = false
  }
  private func publish() {
    onUpdate?(
      printers.values.sorted { $0.ip.localizedStandardCompare($1.ip) == .orderedAscending },
      searching)
  }
  func netServiceBrowser(
    _ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool
  ) {
    services.append(service)
    service.delegate = self
    service.resolve(withTimeout: 4)
  }
  func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
    publish()
  }
  func netServiceDidResolveAddress(_ sender: NetService) {
    let txt = sender.txtRecordData().map { NetService.dictionary(fromTXTRecord: $0) } ?? [:]
    let identity = ([sender.name] + txt.values.compactMap { String(data: $0, encoding: .utf8) })
      .joined(separator: " ")
    guard isPhaser6010(identity) else { return }
    for data in sender.addresses ?? [] {
      guard data.count >= MemoryLayout<sockaddr_in>.size else { continue }
      let ip: String? = data.withUnsafeBytes { raw in
        guard let p = raw.baseAddress?.assumingMemoryBound(to: sockaddr_in.self),
          p.pointee.sin_family == sa_family_t(AF_INET)
        else { return nil }
        var a = p.pointee.sin_addr
        var bytes = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        guard inet_ntop(AF_INET, &a, &bytes, socklen_t(bytes.count)) != nil else { return nil }
        return String(cString: bytes)
      }
      if let ip = ip {
        printers[ip] = DiscoveredPrinter(name: sender.name, ip: ip, source: "Rilevata in rete")
        publish()
      }
    }
  }
}
