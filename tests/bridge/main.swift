// SPDX-License-Identifier: GPL-2.0-or-later
import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let output = root.appendingPathComponent("output")
if FileManager.default.fileExists(atPath: output.path) {
  try FileManager.default.removeItem(at: output)
}
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let bridge = AirPrintBridge(root: root.path, dryRunDirectory: output, port: 8633)
var events: [AirPrintBridge.State] = []
bridge.onChange = { events.append($0) }
func waitFor(_ state: AirPrintBridge.State) {
  let deadline = Date().addingTimeInterval(10)
  while bridge.state != state && Date() < deadline {
    RunLoop.main.run(until: Date().addingTimeInterval(0.05))
  }
  precondition(bridge.state == state, "Unexpected bridge state: \(bridge.state)")
}
try bridge.start()
waitFor(.running)
let a4 = try SystemCommand.run(
  "/usr/bin/ipptool", ["-q", "ipp://localhost:8633/ipp/print", "tests/airprint-validate-a4.test"])
precondition(a4.status == 0)
let create = try SystemCommand.run(
  "/usr/bin/ipptool",
  [
    "-C", "-q", "-f", CommandLine.arguments[2], "ipp://localhost:8633/ipp/print",
    "/usr/share/cups/ipptool/create-job.test",
  ])
precondition(create.status == 0)
let result = try SystemCommand.run(
  "/usr/bin/ipptool",
  [
    "-q", "-f", CommandLine.arguments[2], "ipp://localhost:8633/ipp/print",
    "/usr/share/cups/ipptool/print-job.test",
  ])
precondition(result.status == 0)
let deadline = Date().addingTimeInterval(10)
while (try FileManager.default.contentsOfDirectory(atPath: output.path)).isEmpty
  && Date() < deadline
{
  RunLoop.main.run(until: Date().addingTimeInterval(0.1))
}
let files = try FileManager.default.contentsOfDirectory(atPath: output.path)
precondition(!files.isEmpty)
bridge.stop()
waitFor(.stopped)
precondition(events.contains(.starting) && events.contains(.running) && events.contains(.stopping))
// Restart must release the port and create a fresh child/spool.
try bridge.start()
waitFor(.running)
bridge.stop()
waitFor(.stopped)
print(
  "PASS: actual app bridge IPP startup/readiness, dry-run PDF, stop and restart; no print job submitted."
)
