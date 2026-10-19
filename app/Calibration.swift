// SPDX-License-Identifier: GPL-2.0-or-later
import Foundation

struct Calibration: Equatable {
  var x: Double = 0, y: Double = 0, scaleX: Double = 100, scaleY: Double = 100
  static let directory = "/Library/Printers/Phaser6010"
  static func number(_ text: String) -> Double? {
    let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(
      of: ",", with: ".")
    guard let v = Double(normalized), v.isFinite else { return nil }
    return v
  }
  static func fixed(_ value: Double) -> String {
    String(format: "%.4f", locale: Locale(identifier: "en_US_POSIX"), value)
  }
  var valid: Bool {
    x.isFinite && y.isFinite && scaleX.isFinite && scaleY.isFinite && abs(x) <= 20 && abs(y) <= 20
      && (50...150).contains(scaleX) && (50...150).contains(scaleY)
  }
  static func load(directory: String = directory) -> Calibration {
    var c = Calibration()
    if let old = try? String(contentsOfFile: directory + "/horizontal-offset-mm", encoding: .utf8),
      let v = number(old), abs(v) <= 20
    {
      c.x = v
    }
    if let text = try? String(contentsOfFile: directory + "/calibration.conf", encoding: .utf8) {
      for line in text.split(separator: "\n") {
        let p = line.split(separator: "=", maxSplits: 1)
        guard p.count == 2, let v = number(String(p[1])) else { continue }
        switch p[0] {
        case "horizontal-mm": c.x = v
        case "vertical-mm": c.y = v
        case "scale-x-percent": c.scaleX = v
        case "scale-y-percent": c.scaleY = v
        default: break
        }
      }
    }
    return c.valid ? c : Calibration()
  }
  func corrected(
    width: Double?, height: Double?, left: Double?, right: Double?, top: Double?, bottom: Double?
  ) throws -> Calibration {
    var c = self
    for v in [width, height].compactMap({ $0 }) {
      guard v.isFinite, (50...150).contains(v) else {
        throw CalibrationError("Il lato del quadrato deve essere compreso tra 50 e 150 mm.")
      }
    }
    for v in [left, right, top, bottom].compactMap({ $0 }) {
      guard v.isFinite, (0...50).contains(v) else {
        throw CalibrationError("I margini devono essere compresi tra 0 e 50 mm.")
      }
    }
    if let w = width { c.scaleX = scaleX * 100 / w }
    if let h = height { c.scaleY = scaleY * 100 / h }
    if (left == nil) != (right == nil) || (top == nil) != (bottom == nil) {
      throw CalibrationError("Inserisci entrambi i margini della stessa coppia.")
    }
    if let l = left, let r = right { c.x += (r - l) / 2 }
    if let t = top, let b = bottom { c.y += (t - b) / 2 }
    guard c.valid else {
      throw CalibrationError(
        "Correzione fuori intervallo: massimo 20 mm e scala tra 50% e 150%. Controlla le misure.")
    }
    return c
  }
  var contents: String {
    "horizontal-mm=\(Self.fixed(x))\nvertical-mm=\(Self.fixed(y))\nscale-x-percent=\(Self.fixed(scaleX))\nscale-y-percent=\(Self.fixed(scaleY))\n"
  }
  var saveCommand: String {
    let entries = contents.split(separator: "\n").map { "'\($0)'" }.joined(separator: " ")
    return
      "umask 022; t=$(/usr/bin/mktemp /Library/Printers/Phaser6010/.calibration.XXXXXXXX) || exit 1; /usr/bin/printf '%s\\n' \(entries) > \"$t\" && /bin/chmod 644 \"$t\" && /bin/mv -f \"$t\" /Library/Printers/Phaser6010/calibration.conf"
  }
}
struct CalibrationError: Error, LocalizedError {
  let message: String
  init(_ message: String) { self.message = message }
  var errorDescription: String? { message }
}
