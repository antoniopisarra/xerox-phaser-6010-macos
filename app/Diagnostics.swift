// SPDX-License-Identifier: GPL-2.0-or-later
import Foundation

struct DiagnosticReport {
  static func text(calibration: Calibration, snapshot: PrinterSnapshot?) -> String {
    let version =
      Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
      ?? "development"
    var lines = [
      "Xerox Phaser 6010N for macOS - diagnostic report", "App: \(version)",
      "OS: \(ProcessInfo.processInfo.operatingSystemVersionString)",
      "Target: Apple Silicon / Ethernet / TCP 9100", "", "Calibration:", calibration.contents,
    ]
    for path in [
      "/Library/Printers/Phaser6010/filter/phaser6010",
      "/Library/Printers/Phaser6010/bin/foo2hbpl1", "/Library/Printers/Phaser6010/gs/bin/gs",
      "/usr/bin/snmpget",
    ] {
      lines.append(
        "\(URL(fileURLWithPath:path).lastPathComponent): \(FileManager.default.isExecutableFile(atPath:path) ? "available":"missing")"
      )
    }
    if let snapshot = snapshot {
      lines += ["", "Last printer response: \(snapshot.state)"]
      lines += snapshot.toners.map { "\($0.color): \($0.percent.map{String($0)+"%"} ?? "unknown")" }
    }
    lines += [
      "",
      "This report excludes document contents, job titles, usernames, printer addresses and serial numbers.",
      "SNMP status does not certify that a print job completed.",
    ]
    return lines.joined(separator: "\n") + "\n"
  }
}
