// SPDX-License-Identifier: GPL-2.0-or-later
import Foundation

final class AirPrintBridge {
  enum State: Equatable { case stopped, starting, running, stopping, failed }
  private(set) var state: State = .stopped
  var onChange: ((State) -> Void)?
  private var server: Process?
  private var awake: Process?
  private var spool: URL?
  private var generation = 0
  private var monitor: Timer?
  private var checkingHost = false
  private lazy var host = AirPrintHost(root: runtimeRoot)
  private let port: Int
  private let runtimeRoot: String
  private let dryRunDirectory: URL?
  init(root: String = AirPrintBridge.root, dryRunDirectory: URL? = nil, port: Int = 8631) {
    self.port = port
    self.runtimeRoot = root
    self.dryRunDirectory = dryRunDirectory
  }
  static let serviceName = "Xerox Phaser 6010N via Mac"
  static let port = 8631
  static let root = "/Library/Printers/Phaser6010"

  private func change(_ value: State) {
    state = value
    onChange?(value)
  }
  func start() throws {
    guard server == nil else { return }
    for path in [
      runtimeRoot + "/bin/phaser-ipp-server", "/usr/libexec/cups/command/ippeveps",
      runtimeRoot + "/airprint/print-job.sh",
    ] {
      guard FileManager.default.isExecutableFile(atPath: path) else {
        throw CalibrationError(L("Installa il pacchetto aggiornato per usare AirPrint."))
      }
    }
    if dryRunDirectory == nil {
      let queue = try SystemCommand.run("/usr/bin/lpstat", ["-p", "Phaser6010"])
      let ppd = try? String(contentsOfFile: "/etc/cups/ppd/Phaser6010.ppd", encoding: .utf8)
      guard queue.status == 0, ppd?.contains("Xerox Phaser 6010N Community") == true else {
        throw CalibrationError(L("Configura prima la coda Phaser6010 nella sezione Stampante."))
      }
    }
    if dryRunDirectory == nil {
      guard FileManager.default.isExecutableFile(atPath: runtimeRoot + "/airprint/serve.sh") else {
        throw CalibrationError(L("Installa il pacchetto aggiornato per usare AirPrint."))
      }
      try host.start()
      change(.starting)
      if monitor == nil {
        monitor = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
          self?.refresh()
        }
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
        self?.refresh(force: true)
      }
      return
    }
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(
      "phaser-airprint-" + UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(
      at: folder, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
    let p = Process()
    p.executableURL = URL(fileURLWithPath: runtimeRoot + "/bin/phaser-ipp-server")
    p.arguments = [
      "-p", String(port), "-P", runtimeRoot + "/Phaser6010.ppd", "-c",
      runtimeRoot + "/airprint/print-job.sh", "-d", folder.path, "-r",
      dryRunDirectory == nil ? "_print,_universal" : "_phaser6010test",
      Self.serviceName,
    ]
    p.environment = [
      "PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "TMPDIR": folder.path, "HOME": NSHomeDirectory(),
      "LANG": "en_US.UTF-8",
    ]
    if let dryRunDirectory {
      p.environment?["PHASER_AIRPRINT_DRY_RUN_DIR"] = dryRunDirectory.path
    }
    // Discard server logs: they can contain document names and client addresses.
    p.standardOutput = FileHandle.nullDevice
    p.standardError = FileHandle.nullDevice
    generation += 1
    let token = generation
    p.terminationHandler = { [weak self] _ in
      DispatchQueue.main.async {
        guard let self, self.generation == token else { return }
        let requested = self.state == .stopping
        if self.awake?.isRunning == true { self.awake?.terminate() }
        self.awake = nil
        self.server = nil
        self.spool = nil
        try? FileManager.default.removeItem(at: folder)
        self.change(requested ? .stopped : .failed)
      }
    }
    do { try p.run() } catch {
      try? FileManager.default.removeItem(at: folder)
      throw error
    }
    server = p
    spool = folder
    change(.starting)
    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1.5) { [weak self] in
      let result = try? SystemCommand.run(
        "/usr/bin/ipptool",
        [
          "-q", "-T", "3", "ipp://localhost:\(self?.port ?? 8631)/ipp/print",
          "/usr/share/cups/ipptool/get-printer-attributes.test",
        ], timeout: 5)
      DispatchQueue.main.async {
        guard let self, self.generation == token, self.state == .starting, p.isRunning else {
          return
        }
        if result?.status == 0 {
          let awake = Process()
          awake.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
          awake.arguments = ["-i", "-w", String(p.processIdentifier)]
          try? awake.run()
          self.awake = awake
          self.change(.running)
        } else {
          self.change(.failed)
          p.terminate()
        }
      }
    }
  }
  func refresh(force: Bool = false) {
    guard dryRunDirectory == nil, !checkingHost, state != .stopping else { return }
    if state == .starting && !force { return }
    if monitor == nil {
      monitor = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
        self?.refresh(force: true)
      }
    }
    checkingHost = true
    let token = generation
    DispatchQueue.global(qos: .utility).async { [weak self] in
      guard let self else { return }
      let status = try? self.host.status()
      let ready =
        status?.running == true
        ? try? SystemCommand.run(
          "/usr/bin/ipptool",
          [
            "-q", "-T", "2", "ipp://localhost:8631/ipp/print",
            "/usr/share/cups/ipptool/get-printer-attributes.test",
          ], timeout: 3) : nil
      DispatchQueue.main.async {
        self.checkingHost = false
        guard self.generation == token, self.state != .stopping else { return }
        self.change(ready?.status == 0 ? .running : status?.loaded == true ? .failed : .stopped)
      }
    }
  }
  func stop() {
    if dryRunDirectory == nil {
      generation += 1
      change(.stopping)
      do {
        try host.stop()
        change(.stopped)
      } catch { change(.failed) }
      return
    }
    guard let p = server else {
      change(.stopped)
      return
    }
    change(.stopping)
    if p.isRunning { p.terminate() }
  }
  func stopForRemoval() throws {
    if dryRunDirectory == nil {
      generation += 1
      try host.stop()
      change(.stopped)
    } else {
      stop()
    }
  }
  func shutdown() {
    monitor?.invalidate()
    monitor = nil
    if dryRunDirectory == nil { return }  // Closing the GUI must preserve the launch agent.
    stop()
    if awake?.isRunning == true { awake?.terminate() }
    // No persistent service is installed; the app owns the child process.
  }
}
