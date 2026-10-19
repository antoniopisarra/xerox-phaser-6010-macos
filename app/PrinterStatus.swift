import Darwin
// SPDX-License-Identifier: GPL-2.0-or-later
import Foundation

struct CommandResult {
  let status: Int32
  let text: String
}
enum SystemCommand {
  static func run(_ path: String, _ arguments: [String], timeout: TimeInterval = 5) throws
    -> CommandResult
  {
    guard FileManager.default.isExecutableFile(atPath: path) else {
      throw CalibrationError(
        L("Componente di macOS non disponibile: ") + URL(fileURLWithPath: path).lastPathComponent)
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: path)
    process.arguments = arguments
    process.environment = [
      "PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "LC_ALL": "C", "MIBS": "",
      "SNMPCONFPATH": "/dev/null",
    ]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    try process.run()
    let fd = pipe.fileHandleForReading.fileDescriptor
    let flags = fcntl(fd, F_GETFL)
    _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)
    let limit = 262144
    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 8192)
    let deadline = ProcessInfo.processInfo.systemUptime + max(0.05, timeout)
    var failure: String?
    var stopAt: TimeInterval?
    while true {
      let now = ProcessInfo.processInfo.systemUptime
      if failure == nil && now >= deadline {
        failure = L("Tempo di attesa del comando scaduto.")
      }
      if failure != nil && stopAt == nil {
        if process.isRunning { process.terminate() }
        stopAt = now + 0.25
      }
      if let stopAt, now >= stopAt, process.isRunning {
        _ = Darwin.kill(process.processIdentifier, SIGKILL)
      }
      if failure != nil && !process.isRunning { break }
      let count = Darwin.read(fd, &buffer, buffer.count)
      if count > 0 {
        if data.count + count <= limit && failure == nil {
          data.append(contentsOf: buffer.prefix(count))
        } else if failure == nil {
          failure = L("Risposta troppo grande.")
        }
      } else if !process.isRunning {
        break  // Do not wait forever for a descendant holding the pipe open.
      } else {
        var descriptor = pollfd(fd: fd, events: Int16(POLLIN | POLLHUP), revents: 0)
        if count == 0 { usleep(10_000) } else { _ = poll(&descriptor, 1, 20) }
      }
    }
    process.waitUntilExit()
    if let failure { throw CalibrationError(failure) }

    return CommandResult(
      status: process.terminationStatus, text: String(decoding: data, as: UTF8.self))
  }
}
struct Toner: Codable, Equatable {
  let color: String
  let percent: Int?
  static func percentage(level: Int?, maximum: Int?) -> Int? {
    guard let level = level, let maximum = maximum, level >= 0, maximum > 0, level <= maximum else {
      return nil
    }
    return Int((Double(level) * 100 / Double(maximum)).rounded())
  }
}
struct PrinterSnapshot: Codable {
  let state: String
  let toners: [Toner]
  let checkedAt: Date
  static let colors = ["cyan", "magenta", "yellow", "black"]
  static let unknownToners = colors.map { Toner(color: $0, percent: nil) }
  static func parse(_ text: String) throws -> PrinterSnapshot {
    let lines = text.split(whereSeparator: \.isNewline).map {
      String($0).trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(
        in: CharacterSet(charactersIn: "\""))
    }
    guard lines.count == 14, isPhaser6010(lines[0]) else {
      throw CalibrationError(L("La risposta non identifica una Xerox Phaser 6010N compatibile."))
    }
    let state: String
    switch Int(lines[1]) {
    case 3: state = "ready"
    case 4: state = "printing"
    case 5: state = "warming"
    default: state = "reachable"
    }
    var levels: [String: Int] = [:]
    for i in 0..<4 {
      let start = 2 + i * 3
      let color = lines[start + 2].lowercased()
      guard colors.contains(color) else { continue }
      if let value = Toner.percentage(level: Int(lines[start]), maximum: Int(lines[start + 1])) {
        levels[color] = value
      }
    }
    return PrinterSnapshot(
      state: state, toners: colors.map { Toner(color: $0, percent: levels[$0]) }, checkedAt: Date())
  }
  static func fetch(ip: String) throws -> PrinterSnapshot {
    guard let address = normalizedIPv4(ip) else {
      throw CalibrationError(L("Inserisci un indirizzo IPv4 valido."))
    }
    let identity = [".1.3.6.1.2.1.25.3.2.1.3.1", ".1.3.6.1.2.1.25.3.5.1.1.1"]
    var supplies: [String] = []
    for i in 1...4 {
      supplies += [
        ".1.3.6.1.2.1.43.11.1.1.9.1.\(i)", ".1.3.6.1.2.1.43.11.1.1.8.1.\(i)",
        ".1.3.6.1.2.1.43.12.1.1.4.1.\(i)",
      ]
    }
    // Keep legacy printer responses below their small SNMP message limit.
    var response = ""
    for oids in [identity, supplies] {
      let result = try SystemCommand.run(
        "/usr/bin/snmpget", ["-v1", "-c", "public", "-t", "1", "-r", "0", "-Oqve", address] + oids,
        timeout: 4)
      guard result.status == 0 else {
        throw CalibrationError(
          L(
            "Stato non disponibile. La stampante potrebbe non rispondere alle richieste di monitoraggio."
          )
        )
      }
      response += result.text
      if !response.hasSuffix("\n") { response += "\n" }
    }
    return try parse(response)
  }
  var title: String {
    switch state {
    case "ready": return L("Pronta")
    case "printing": return L("Stampa in corso")
    case "warming": return L("Riscaldamento")
    default: return L("Raggiungibile")
    }
  }
  var lowColors: [String] { toners.filter { ($0.percent ?? 101) <= 10 }.map(\.color) }
}
