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
        "Componente di macOS non disponibile: \(URL(fileURLWithPath:path).lastPathComponent)")
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
    let watchdog = DispatchWorkItem { if process.isRunning { process.terminate() } }
    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout, execute: watchdog)
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    watchdog.cancel()
    guard data.count <= 262144 else { throw CalibrationError("Risposta troppo grande.") }
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
      throw CalibrationError("La risposta non identifica una Xerox Phaser 6010N compatibile.")
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
      throw CalibrationError("Inserisci un indirizzo IPv4 valido.")
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
          "Stato non disponibile. La stampante potrebbe non rispondere alle richieste di monitoraggio."
        )
      }
      response += result.text
      if !response.hasSuffix("\n") { response += "\n" }
    }
    return try parse(response)
  }
  var title: String {
    switch state {
    case "ready": return "Pronta"
    case "printing": return "Stampa in corso"
    case "warming": return "Riscaldamento"
    default: return "Raggiungibile"
    }
  }
  var lowColors: [String] { toners.filter { ($0.percent ?? 101) <= 10 }.map(\.color) }
}
