import Foundation

func close(_ a: Double, _ b: Double) { precondition(abs(a - b) < 0.0001, "\(a) != \(b)") }
let base = Calibration(x: -5, y: 0, scaleX: 100, scaleY: 100)
let center = try base.corrected(width: 100, height: 100, left: 10, right: 10, top: 10, bottom: 10)
precondition(center == base)
let moved = try base.corrected(width: nil, height: nil, left: 15, right: 5, top: 15, bottom: 5)
close(moved.x, -10)
close(moved.y, 5)
let scaled = try base.corrected(
  width: 102, height: 98, left: nil, right: nil, top: nil, bottom: nil)
close(scaled.scaleX, 10000 / 102)
close(scaled.scaleY, 10000 / 98)
do {
  _ = try base.corrected(width: nil, height: nil, left: 15, right: nil, top: nil, bottom: nil)
  fatalError("Missing pair accepted")
} catch {}
precondition(Calibration.number("-5,25") == (-5.25))
precondition(!Calibration(x: .nan).valid)
let folder = NSTemporaryDirectory() + "phaser-calibration-core-tests-" + UUID().uuidString
try? FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(atPath: folder) }
try "-5.00\n".write(toFile: folder + "/horizontal-offset-mm", atomically: true, encoding: .utf8)
close(Calibration.load(directory: folder).x, -5)
try moved.contents.write(toFile: folder + "/calibration.conf", atomically: true, encoding: .utf8)
precondition(Calibration.load(directory: folder) == moved)
print(
  "PASS: unchanged scale; cumulative X/Y centering; independent scales; validation; migration; settings round trip."
)
print(base.saveCommand)
precondition(normalizedIPv4("192.168.1.027") == "192.168.1.27")
precondition(normalizedIPv4("192.168.1.1;id") == nil)
precondition(isPhaser6010("Xerox Phaser 6010N"))
precondition(!isPhaser6010("Xerox WorkCentre 6015"))
let identity = SNMPIdentity.tlv(
  0x30, SNMPIdentity.tlv(4, Array("Xerox Phaser 6010N; Net 17.30".utf8)))
precondition(SNMPIdentity.identity(Data(identity)) != nil)
for p: [UInt8] in [
  [], [0x30], [0x30, 0x84, 0xff], [0x30, 0x80], [0x30, 0xff, 0xff], [4, 120, 0],
] { precondition(SNMPIdentity.identity(Data(p)) == nil) }
print("PASS: IPv4 normalization, device identity filtering and malformed SNMP packet handling.")

precondition(Toner.percentage(level: 25, maximum: 500) == 5)
precondition(Toner.percentage(level: 0, maximum: 500) == 0)
precondition(Toner.percentage(level: -3, maximum: 500) == nil)
precondition(Toner.percentage(level: 25, maximum: -2) == nil)
precondition(Toner.percentage(level: 600, maximum: 500) == nil)
let fixture = """
  "Xerox Phaser 6010N; Net 17.30"
  3
  25
  500
  "cyan"
  50
  500
  "magenta"
  150
  500
  "yellow"
  2000
  2000
  "black"
  """
let snapshot = try PrinterSnapshot.parse(fixture)
precondition(snapshot.toners.map(\.percent) == [5, 10, 30, 100])
precondition(snapshot.state == "ready")
do {
  _ = try PrinterSnapshot.parse("garbage")
  fatalError("Malformed status accepted")
} catch {}
let report = DiagnosticReport.text(calibration: base, snapshot: snapshot)
precondition(!report.contains("192.168."))
precondition(!report.contains(NSUserName()))
print(
  "PASS: toner percentages; unknown values; invalid response handling; private-data-free diagnostics."
)

precondition(AppLanguage.resolve(selection: "en\n", preferred: "it-IT") == "en")
precondition(AppLanguage.resolve(selection: "it\n", preferred: "en-US") == "it")
precondition(AppLanguage.resolve(selection: "invalid", preferred: "it-IT") == "it")
let oldLanguage = UserDefaults.standard.object(forKey: "interfaceLanguage")
UserDefaults.standard.set("en", forKey: "interfaceLanguage")
precondition(L("Stampante") == "Printer")
precondition(L("Calibrazione") == "Calibration")
precondition(
  L("Orizzontale: − sinistra / + destra   ·   Verticale: − alto / + basso").contains("+ down"))
UserDefaults.standard.set("it", forKey: "interfaceLanguage")
precondition(L("Stampante") == "Stampante")
if let oldLanguage {
  UserDefaults.standard.set(oldLanguage, forKey: "interfaceLanguage")
} else {
  UserDefaults.standard.removeObject(forKey: "interfaceLanguage")
}
print("PASS: installed language parsing, locale fallback, English/Italian UI translation.")

precondition(
  !isDirectPrinterService(type: "_ipp._tcp.", port: 8631, identity: "Xerox Phaser 6010N via Mac"))
precondition(
  !isDirectPrinterService(type: "_pdl-datastream._tcp.", port: 8631, identity: "Xerox Phaser 6010N")
)
precondition(
  isDirectPrinterService(type: "_pdl-datastream._tcp.", port: 9100, identity: "Xerox Phaser 6010N"))
precondition(
  !isDirectPrinterService(type: "_pdl-datastream._tcp.", port: 9100, identity: "Another printer"))
let ok = try SystemCommand.run("/bin/echo", ["bounded-output"])
precondition(ok.status == 0 && ok.text == "bounded-output\n")
let started = ProcessInfo.processInfo.systemUptime
do {
  _ = try SystemCommand.run("/bin/sh", ["-c", "trap '' TERM; while :; do :; done"], timeout: 0.1)
  fatalError("Unbounded command accepted")
} catch {}
precondition(ProcessInfo.processInfo.systemUptime - started < 2)
do {
  _ = try SystemCommand.run("/usr/bin/yes", [], timeout: 3)
  fatalError("Unbounded output accepted")
} catch {}
print(
  "PASS: direct-hardware discovery; bounded command output; hard timeout for a TERM-resistant child."
)

let hostHome = URL(fileURLWithPath: "build/tests/agent-home", isDirectory: true)
try? FileManager.default.removeItem(at: hostHome)
var agentLoaded = false
var agentCalls: [[String]] = []
let agentRunner: (String, [String]) throws -> CommandResult = { path, args in
  precondition(path == "/bin/launchctl")
  agentCalls.append(args)
  switch args.first {
  case "print":
    return CommandResult(
      status: agentLoaded ? 0 : 113, text: agentLoaded ? "state = running\n" : "")
  case "bootstrap": agentLoaded = true
  case "bootout": agentLoaded = false
  default: break
  }
  return CommandResult(status: 0, text: "")
}
let agent = AirPrintHost(home: hostHome, root: "/Library/Printers/Phaser6010", command: agentRunner)
try agent.start()
precondition(agentLoaded && FileManager.default.fileExists(atPath: agent.plist.path))
let plistData = try Data(contentsOf: agent.plist)
let manifest =
  try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil)
  as! [String: Any]
let arguments = manifest["ProgramArguments"] as! [String]
precondition(arguments.first == "/usr/bin/caffeinate" && arguments[1] == "-i")
precondition(!arguments.prefix(2).contains("-d") && !arguments.prefix(2).contains("-u"))
precondition(manifest["RunAtLoad"] as? Bool == true && manifest["KeepAlive"] as? Bool == true)
let attrs = try FileManager.default.attributesOfItem(atPath: agent.plist.path)
precondition((attrs[.posixPermissions] as! NSNumber).intValue == 0o600)
let anotherWindow = AirPrintHost(home: hostHome, command: agentRunner)
let recovered = try anotherWindow.status()
precondition(recovered.running)
try anotherWindow.stop()
precondition(!agentLoaded && !FileManager.default.fileExists(atPath: agent.plist.path))
try anotherWindow.stop()  // disabling an already stopped service is safe
try? FileManager.default.removeItem(at: hostHome)
print(
  "PASS: background launch agent, login restart, display sleep allowed, stop and private plist permissions; no live agent changed."
)
