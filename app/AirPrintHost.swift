import Darwin
// SPDX-License-Identifier: GPL-2.0-or-later
import Foundation

// A per-user launch agent owns the server independently of the configuration window.
final class AirPrintHost {
  static let label = "org.community.phaser6010.airprint"
  let home: URL
  let root: String
  let domain: String
  let command: (String, [String]) throws -> CommandResult
  init(
    home: URL = FileManager.default.homeDirectoryForCurrentUser,
    root: String = AirPrintBridge.root,
    command: @escaping (String, [String]) throws -> CommandResult = {
      try SystemCommand.run($0, $1)
    }
  ) {
    self.home = home
    self.root = root
    self.domain = "gui/\(getuid())"
    self.command = command
  }
  var target: String { domain + "/" + Self.label }
  var plist: URL { home.appendingPathComponent("Library/LaunchAgents/" + Self.label + ".plist") }
  var spool: URL {
    home.appendingPathComponent("Library/Caches/" + Self.label + "/spool", isDirectory: true)
  }
  var manifest: [String: Any] {
    [
      "Label": Self.label, "RunAtLoad": true, "KeepAlive": true, "ThrottleInterval": 10,
      "Umask": 0o077, "StandardOutPath": "/dev/null", "StandardErrorPath": "/dev/null",
      "ProgramArguments": ["/usr/bin/caffeinate", "-i", root + "/airprint/serve.sh", spool.path],
      "EnvironmentVariables": [
        "PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "HOME": home.path,
        "TMPDIR": spool.path, "LANG": "en_US.UTF-8",
      ],
    ]
  }
  func status() throws -> (loaded: Bool, running: Bool) {
    let result = try command("/bin/launchctl", ["print", target])
    return (result.status == 0, result.status == 0 && result.text.contains("state = running"))
  }
  func start() throws {
    let fm = FileManager.default
    try fm.createDirectory(at: plist.deletingLastPathComponent(), withIntermediateDirectories: true)
    try fm.createDirectory(
      at: spool, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    try fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: spool.path)
    let data = try PropertyListSerialization.data(
      fromPropertyList: manifest, format: .xml, options: 0)
    try data.write(to: plist, options: .atomic)
    try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: plist.path)
    let current = try status()
    let result = try command(
      "/bin/launchctl", current.loaded ? ["kickstart", target] : ["bootstrap", domain, plist.path])
    guard result.status == 0 else {
      throw CalibrationError(
        L(
          "Impossibile avviare AirPrint in background. Riapri l’app e riprova dopo l’accesso al Mac."
        ))
    }
  }
  func stop() throws {
    // Remove automatic login activation even if the service is currently down.
    if FileManager.default.fileExists(atPath: plist.path) {
      try FileManager.default.removeItem(at: plist)
    }
    if try status().loaded {
      let result = try command("/bin/launchctl", ["bootout", target])
      guard result.status == 0 else {
        throw CalibrationError(
          L("Impossibile arrestare AirPrint in background. Riprova tra qualche secondo."))
      }
    }
    if FileManager.default.fileExists(atPath: spool.path) {
      try FileManager.default.removeItem(at: spool)
    }
  }
}
