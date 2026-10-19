// SPDX-License-Identifier: GPL-2.0-or-later
import Cocoa
import PDFKit
import UniformTypeIdentifiers

final class Surface: NSView {
  init(_ frame: NSRect, color: NSColor, radius: CGFloat = 16) {
    super.init(frame: frame)
    wantsLayer = true
    layer?.backgroundColor = color.cgColor
    layer?.cornerRadius = radius
  }
  required init?(coder: NSCoder) { fatalError() }
}
final class TonerGauge: NSView {
  var percentage: Int? { didSet { needsDisplay = true } }
  var tint: NSColor = .systemCyan
  override func draw(_ dirtyRect: NSRect) {
    NSColor(calibratedWhite: 0.92, alpha: 1).setFill()
    NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6).fill()
    if let p = percentage, p > 0 {
      tint.setFill()
      NSBezierPath(
        roundedRect: NSRect(
          x: 0, y: 0, width: bounds.width * CGFloat(p) / 100, height: bounds.height), xRadius: 6,
        yRadius: 6
      ).fill()
    }
  }
}
final class PrinterRow: NSTableRowView {
  override func drawSelection(in dirtyRect: NSRect) {
    NSColor(calibratedRed: 0.02, green: 0.43, blue: 0.49, alpha: 0.12).setFill()
    NSBezierPath(roundedRect: bounds.insetBy(dx: 3, dy: 3), xRadius: 10, yRadius: 10).fill()
  }
  override var interiorBackgroundStyle: NSView.BackgroundStyle { .normal }
}
final class Delegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate {
  var window: NSWindow!
  let accent = NSColor(calibratedRed: 0.02, green: 0.43, blue: 0.49, alpha: 1)
  let ink = NSColor(calibratedRed: 0.08, green: 0.19, blue: 0.25, alpha: 1)
  var connection: NSView!, calibration: NSView!, statusPage: NSView!
  let printerState = NSTextField(labelWithString: "Nessun aggiornamento")
  let statusDetail = NSTextField(
    wrappingLabelWithString: "Seleziona la stampante nella sezione Stampante.")
  let lastUpdate = NSTextField(labelWithString: "")
  var tonerLabels: [NSTextField] = [], tonerBars: [TonerGauge] = []
  var snapshot: PrinterSnapshot?
  var refreshTimer: Timer?
  var refreshing = false
  var statusGeneration = 0
  let pdfLanguage = NSPopUpButton()
  let table = NSTableView(), discovery = PrinterDiscovery()
  var printers: [DiscoveredPrinter] = []
  let ip = NSTextField(string: UserDefaults.standard.string(forKey: "printerIP") ?? "")
  let searchStatus = NSTextField(
    wrappingLabelWithString: "Ricerca delle Phaser 6010 sulla rete locale…")
  let connectionStatus = NSTextField(
    wrappingLabelWithString:
      "Seleziona una stampante rilevata oppure inserisci il suo indirizzo IP.")
  let calibrationStatus = NSTextField(
    wrappingLabelWithString: "Stampa il foglio al 100%, misura e inserisci solo i valori rilevati.")
  let progress = NSProgressIndicator()
  var measured: [NSTextField] = [], corrections: [NSTextField] = []
  var saved = Calibration.load()
  var nav: [NSButton] = []
  var isPreview: Bool { CommandLine.arguments.contains("--render-preview") }
  @discardableResult func label(
    _ parent: NSView, _ text: String, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat,
    _ size: CGFloat = 13, _ bold: Bool = false, _ color: NSColor? = nil
  ) -> NSTextField {
    let v = NSTextField(wrappingLabelWithString: text)
    v.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
    v.textColor = color ?? ink
    v.frame = NSRect(x: x, y: y, width: w, height: size > 20 ? 42 : 38)
    parent.addSubview(v)
    return v
  }
  @discardableResult func button(
    _ parent: NSView, _ title: String, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ action: Selector,
    _ primary: Bool = false
  ) -> NSButton {
    let b = NSButton(title: title, target: self, action: action)
    b.bezelStyle = .rounded
    b.frame = NSRect(x: x, y: y, width: w, height: 36)
    if primary {
      b.bezelColor = accent
      b.contentTintColor = .white
    }
    parent.addSubview(b)
    return b
  }
  func field(_ parent: NSView, _ placeholder: String, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat)
    -> NSTextField
  {
    let f = NSTextField(string: "")
    f.placeholderString = placeholder
    f.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
    f.frame = NSRect(x: x, y: y, width: width, height: 28)
    parent.addSubview(f)
    return f
  }
  func applicationDidFinishLaunching(_ notification: Notification) {
    configureMenu()
    window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 1000, height: 760),
      styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
    window.title = "Configura Xerox Phaser 6010N"
    window.appearance = NSAppearance(named: .aqua)
    let root = Surface(
      NSRect(x: 0, y: 0, width: 1000, height: 760), color: NSColor(calibratedWhite: 0.97, alpha: 1),
      radius: 0)
    window.contentView = root
    let side = Surface(
      NSRect(x: 0, y: 0, width: 220, height: 760),
      color: NSColor(calibratedRed: 0.91, green: 0.95, blue: 0.96, alpha: 1), radius: 0)
    root.addSubview(side)
    if let icon = NSImage(named: "AppIcon")
      ?? Bundle.main.url(forResource: "AppIcon", withExtension: "png").flatMap({
        NSImage(contentsOf: $0)
      })
    {
      NSApp.applicationIconImage = icon
      let image = NSImageView(frame: NSRect(x: 24, y: 630, width: 80, height: 80))
      image.image = icon
      side.addSubview(image)
    }
    label(side, "Phaser 6010N", 24, 588, 180, 21, true)
    label(side, "Configurazione per Mac", 24, 558, 180, 12, false, .secondaryLabelColor)
    let first = button(side, "Stampante", 18, 475, 184, #selector(showConnection))
    first.image = NSImage(systemSymbolName: "printer", accessibilityDescription: nil)
    first.imagePosition = .imageLeading
    let second = button(side, "Calibrazione", 18, 425, 184, #selector(showCalibration))
    second.image = NSImage(systemSymbolName: "scope", accessibilityDescription: nil)
    second.imagePosition = .imageLeading
    let third = button(side, "Stato e toner", 18, 375, 184, #selector(showStatus))
    third.image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: nil)
    third.imagePosition = .imageLeading
    nav = [first, second, third]
    label(
      side, "Driver indipendente\nNon ufficiale Xerox", 24, 77, 174, 11, false, .secondaryLabelColor
    )
    button(side, "Disinstalla…", 18, 28, 184, #selector(remove))
    connection = NSView(frame: NSRect(x: 220, y: 0, width: 780, height: 760))
    calibration = NSView(frame: connection.frame)
    statusPage = NSView(frame: connection.frame)
    root.addSubview(connection)
    root.addSubview(calibration)
    root.addSubview(statusPage)
    buildConnection()
    buildCalibration()
    buildStatus()
    showConnection()
    window.center()
    if isPreview {
      printers = [
        DiscoveredPrinter(
          name: "Xerox Phaser 6010N", ip: "192.168.1.100", source: "Rilevata in rete")
      ]
      table.reloadData()
      table.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
      searchStatus.stringValue = "1 stampante compatibile trovata"
      progress.stopAnimation(nil)
      let base = CommandLine.arguments.last!
      root.layoutSubtreeIfNeeded()
      render(root, to: base + "-stampante.png")
      showCalibration()
      root.layoutSubtreeIfNeeded()
      render(root, to: base + "-calibrazione.png")
      NSApp.terminate(nil)
      return
    }
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    discovery.onUpdate = { [weak self] items, searching in
      guard let self = self else { return }
      let selected =
        self.table.selectedRow >= 0 && self.table.selectedRow < self.printers.count
        ? self.printers[self.table.selectedRow].ip : nil
      self.printers = items
      self.table.reloadData()
      if let selected = selected, let row = items.firstIndex(where: { $0.ip == selected }) {
        self.table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
      } else if items.count == 1 {
        self.table.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
      }
      self.searchStatus.stringValue =
        items.isEmpty
        ? (searching
          ? "Cerco le Phaser 6010 sulla rete locale…"
          : "Nessuna Phaser 6010 rilevata. Puoi usare l’indirizzo IP qui sotto.")
        : "\(items.count) stampant\(items.count==1 ? "e compatibile trovata":"i compatibili trovate")"
      if searching { self.progress.startAnimation(nil) } else { self.progress.stopAnimation(nil) }
    }
    search()
    refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
      if let self = self, !self.statusPage.isHidden { self.refreshStatus() }
    }
  }
  func configureMenu() {
    let menu = NSMenu()
    let appItem = NSMenuItem()
    menu.addItem(appItem)
    let appMenu = NSMenu()
    appItem.submenu = appMenu
    appMenu.addItem(
      withTitle: "Informazioni su Configura Xerox Phaser 6010N",
      action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
    appMenu.addItem(.separator())
    appMenu.addItem(
      withTitle: "Esci", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    let editItem = NSMenuItem()
    menu.addItem(editItem)
    let edit = NSMenu(title: "Modifica")
    editItem.submenu = edit
    edit.addItem(withTitle: "Taglia", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    edit.addItem(withTitle: "Copia", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    edit.addItem(withTitle: "Incolla", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    edit.addItem(
      withTitle: "Seleziona tutto", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
    let fileItem = NSMenuItem()
    menu.addItem(fileItem)
    let file = NSMenu(title: "File")
    fileItem.submenu = file
    let print = NSMenuItem(
      title: "Stampa foglio di centratura…", action: #selector(printCalibration), keyEquivalent: "p"
    )
    print.target = self
    file.addItem(print)
    NSApp.mainMenu = menu
  }
  func buildConnection() {
    label(connection, "La tua stampante.", 28, 684, 710, 29, true)
    label(
      connection, "Collega la Xerox alla stessa rete del Mac, poi selezionala dall’elenco.", 28,
      650, 710, 13, false, .secondaryLabelColor)
    let card = Surface(NSRect(x: 28, y: 324, width: 724, height: 298), color: .white)
    connection.addSubview(card)
    label(card, "Stampanti in rete", 20, 244, 400, 17, true)
    button(card, "Cerca di nuovo", 533, 238, 173, #selector(search))
    progress.style = .spinning
    progress.controlSize = .small
    progress.isDisplayedWhenStopped = false
    progress.frame = NSRect(x: 21, y: 215, width: 16, height: 16)
    card.addSubview(progress)
    searchStatus.frame = NSRect(x: 47, y: 193, width: 650, height: 36)
    searchStatus.font = .systemFont(ofSize: 12)
    searchStatus.textColor = .secondaryLabelColor
    card.addSubview(searchStatus)
    table.frame = NSRect(x: 0, y: 0, width: 692, height: 172)
    table.autoresizingMask = [.width]
    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("printer"))
    column.width = 675
    table.addTableColumn(column)
    table.headerView = nil
    table.rowHeight = 66
    table.delegate = self
    table.dataSource = self
    table.backgroundColor = .white
    table.style = .fullWidth
    table.allowsEmptySelection = true
    let scroll = NSScrollView(frame: NSRect(x: 16, y: 15, width: 692, height: 172))
    scroll.documentView = table
    scroll.hasVerticalScroller = true
    scroll.drawsBackground = false
    card.addSubview(scroll)
    let manual = Surface(NSRect(x: 28, y: 177, width: 724, height: 128), color: .white)
    connection.addSubview(manual)
    label(manual, "Oppure inserisci l’indirizzo IP", 20, 76, 650, 16, true)
    ip.placeholderString = "Esempio: 192.168.1.100"
    ip.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
    ip.frame = NSRect(x: 20, y: 27, width: 340, height: 30)
    manual.addSubview(ip)
    label(
      manual, "L’IP selezionato nell’elenco\nviene inserito automaticamente.", 381, 20, 320, 12,
      false, .secondaryLabelColor)
    connectionStatus.frame = NSRect(x: 29, y: 86, width: 715, height: 60)
    connectionStatus.font = .systemFont(ofSize: 13)
    connectionStatus.textColor = .secondaryLabelColor
    connection.addSubview(connectionStatus)
    button(connection, "Configura stampante…", 516, 30, 236, #selector(add), true)
  }
  func buildCalibration() {
    label(calibration, "Una stampa, centrata.", 28, 684, 710, 29, true)
    label(
      calibration, "Misura il foglio e lascia all’utility il calcolo delle correzioni.", 28, 650,
      710, 13, false, .secondaryLabelColor)
    button(
      calibration, "Stampa foglio di centratura…", 28, 598, 290, #selector(printCalibration), true)
    pdfLanguage.addItems(withTitles: ["Italiano", "English"])
    pdfLanguage.frame = NSRect(x: 333, y: 601, width: 150, height: 28)
    let preferred =
      UserDefaults.standard.string(forKey: "pdfLanguage")
      ?? (Locale.preferredLanguages.first?.hasPrefix("it") == true ? "it" : "en")
    pdfLanguage.selectItem(at: preferred == "it" ? 0 : 1)
    pdfLanguage.target = self
    pdfLanguage.action = #selector(pdfLanguageChanged)
    calibration.addSubview(pdfLanguage)
    button(calibration, "Apri PDF", 612, 598, 140, #selector(openCalibration))
    let card = Surface(NSRect(x: 28, y: 326, width: 724, height: 252), color: .white)
    calibration.addSubview(card)
    label(card, "1. Inserisci le misure del foglio stampato", 20, 201, 680, 17, true)
    let names = [
      ("Quadrato", "Larghezza", "Altezza", "100"), ("Margini laterali", "Sinistra", "Destra", "10"),
      ("Margini verticali", "Sopra", "Sotto", "10"),
    ]
    for (i, row) in names.enumerated() {
      let y = CGFloat(151 - i * 47)
      label(card, row.0, 20, y - 2, 150, 13, true)
      label(card, row.1, 183, y - 2, 80, 12, false, .secondaryLabelColor)
      measured.append(field(card, row.3, 264, y, 90))
      label(card, "mm", 361, y - 2, 28, 12, false, .secondaryLabelColor)
      label(card, row.2, 423, y - 2, 75, 12, false, .secondaryLabelColor)
      measured.append(field(card, row.3, 503, y, 90))
      label(card, "mm", 601, y - 2, 28, 12, false, .secondaryLabelColor)
    }
    label(
      card, "Lascia vuote le misure che non hai rilevato.", 20, 8, 430, 11, false,
      .secondaryLabelColor)
    button(card, "Calcola correzioni", 516, 7, 190, #selector(calculate))
    let result = Surface(NSRect(x: 28, y: 145, width: 724, height: 163), color: .white)
    calibration.addSubview(result)
    label(result, "2. Verifica le correzioni", 20, 111, 680, 17, true)
    for (i, name) in [
      "Orizzontale (mm)", "Verticale (mm)", "Scala larghezza (%)", "Scala altezza (%)",
    ].enumerated() {
      let x = CGFloat(20 + i * 174)
      label(result, name, x, 68, 168, 11, false, .secondaryLabelColor)
      let f = field(result, "0", x, 46, 145)
      corrections.append(f)
    }
    label(
      result, "Orizzontale: − sinistra / + destra   ·   Verticale: − basso / + alto", 20, 1, 680,
      11, false, .secondaryLabelColor)
    fillCorrections(saved)
    calibrationStatus.frame = NSRect(x: 29, y: 65, width: 710, height: 60)
    calibrationStatus.font = .systemFont(ofSize: 12)
    calibrationStatus.textColor = .secondaryLabelColor
    calibration.addSubview(calibrationStatus)
    button(calibration, "Valori standard", 28, 18, 180, #selector(reset))
    button(calibration, "Salva calibrazione…", 516, 18, 236, #selector(saveCalibration), true)
  }
  func buildStatus() {
    label(statusPage, "Stato e toner.", 28, 684, 710, 29, true)
    lastUpdate.frame = NSRect(x: 29, y: 647, width: 530, height: 26)
    lastUpdate.font = .systemFont(ofSize: 12)
    lastUpdate.textColor = .secondaryLabelColor
    statusPage.addSubview(lastUpdate)
    button(statusPage, "Aggiorna", 598, 643, 154, #selector(refreshStatus))
    let state = Surface(NSRect(x: 28, y: 500, width: 724, height: 122), color: .white)
    statusPage.addSubview(state)
    printerState.frame = NSRect(x: 20, y: 62, width: 684, height: 43)
    printerState.font = .boldSystemFont(ofSize: 27)
    printerState.textColor = accent
    state.addSubview(printerState)
    statusDetail.frame = NSRect(x: 20, y: 11, width: 684, height: 43)
    statusDetail.font = .systemFont(ofSize: 12)
    statusDetail.textColor = .secondaryLabelColor
    state.addSubview(statusDetail)
    let toner = Surface(NSRect(x: 28, y: 210, width: 724, height: 270), color: .white)
    statusPage.addSubview(toner)
    label(toner, "Livelli toner", 20, 219, 680, 17, true)
    let colors: [NSColor] = [
      .systemCyan, .systemPink, .systemYellow, NSColor(calibratedWhite: 0.2, alpha: 1),
    ]
    for (i, name) in ["Ciano", "Magenta", "Giallo", "Nero"].enumerated() {
      let y = CGFloat(184 - i * 45)
      label(toner, name, 20, y, 110, 13, true)
      let bar = TonerGauge(frame: NSRect(x: 126, y: y + 12, width: 420, height: 12))
      bar.tint = colors[i]
      toner.addSubview(bar)
      tonerBars.append(bar)
      let value = label(toner, "—", 573, y - 1, 130, 15, true)
      tonerLabels.append(value)
    }
    label(
      toner, "Stime della stampante. Aggiornamento automatico ogni 30 secondi in questa sezione.",
      20, 1, 684, 10.5, false, .secondaryLabelColor)
    let tools = Surface(NSRect(x: 28, y: 28, width: 724, height: 158), color: .white)
    statusPage.addSubview(tools)
    label(tools, "Strumenti", 20, 108, 680, 17, true)
    button(tools, "Pagina web stampante", 15, 65, 219, #selector(openPrinterWeb))
    button(tools, "Stampanti e scanner", 249, 65, 226, #selector(openPrinterSettings))
    button(tools, "Esporta diagnostica…", 490, 65, 219, #selector(exportDiagnostics))
    button(tools, "Condivisione del Mac…", 15, 18, 219, #selector(openSharing))
    label(
      tools,
      "Condivisione con altri computer.\nAirPrint per iPhone e iPad non incluso in questa versione.",
      252, 12, 450, 11, false, .secondaryLabelColor)
  }
  @objc func refreshStatus() {
    guard !refreshing else { return }
    guard let address = normalizedIPv4(ip.stringValue) else {
      printerState.stringValue = "Seleziona una stampante"
      statusDetail.stringValue =
        "Apri Stampante e seleziona la Xerox oppure inserisci il suo indirizzo IP."
      return
    }
    refreshing = true
    statusGeneration += 1
    let generation = statusGeneration
    lastUpdate.stringValue = "Aggiornamento in corso…"
    snapshot = nil
    printerState.stringValue = "Aggiornamento…"
    statusDetail.stringValue = "Xerox Phaser 6010N · " + address
    for i in 0..<4 {
      tonerBars[i].percentage = nil
      tonerLabels[i].stringValue = "—"
    }
    DispatchQueue.global(qos: .utility).async { [weak self] in
      let result = Result { try PrinterSnapshot.fetch(ip: address) }
      DispatchQueue.main.async {
        guard let self = self, generation == self.statusGeneration else { return }
        self.refreshing = false
        guard normalizedIPv4(self.ip.stringValue) == address else {
          self.refreshStatus()
          return
        }
        switch result {
        case .success(let value):
          self.snapshot = value
          self.printerState.stringValue = value.title
          let formatter = DateFormatter()
          formatter.dateStyle = .none
          formatter.timeStyle = .medium
          self.lastUpdate.stringValue = "Aggiornato alle " + formatter.string(from: value.checkedAt)
          self.statusDetail.stringValue =
            "Xerox Phaser 6010N · " + address
            + "\nControlla la coda nelle impostazioni per l’esito dei lavori di stampa."
          for (i, item) in value.toners.enumerated() {
            self.tonerBars[i].percentage = item.percent
            self.tonerLabels[i].stringValue =
              item.percent.map { String($0) + "%" } ?? "Non disponibile"
          }
        case .failure(let error):
          self.snapshot = nil
          self.printerState.stringValue = "Stato non disponibile"
          self.statusDetail.stringValue = error.localizedDescription
          self.lastUpdate.stringValue = "Puoi riprovare con Aggiorna."
          for i in 0..<4 {
            self.tonerBars[i].percentage = nil
            self.tonerLabels[i].stringValue = "—"
          }
        }
      }
    }
  }
  @objc func openPrinterWeb() {
    guard let address = normalizedIPv4(ip.stringValue), let url = URL(string: "http://" + address)
    else {
      alert("Seleziona prima una stampante.")
      return
    }
    NSWorkspace.shared.open(url)
  }
  @objc func openPrinterSettings() {
    NSWorkspace.shared.open(
      URL(string: "x-apple.systempreferences:com.apple.Print-Scan-Settings.extension")!)
  }
  @objc func openSharing() {
    NSWorkspace.shared.open(
      URL(string: "x-apple.systempreferences:com.apple.Sharing-Settings.extension")!)
  }
  @objc func exportDiagnostics() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.plainText]
    panel.nameFieldStringValue = "Phaser6010-diagnostica.txt"
    panel.message =
      "Il report non include documenti, titoli dei lavori, nomi utente o indirizzi di rete."
    guard panel.runModal() == .OK, let url = panel.url else { return }
    do {
      try DiagnosticReport.text(calibration: saved, snapshot: snapshot).write(
        to: url, atomically: true, encoding: .utf8)
    } catch { alert("Impossibile salvare la diagnostica: " + error.localizedDescription) }
  }
  func fillCorrections(_ c: Calibration) {
    for (f, v) in zip(corrections, [c.x, c.y, c.scaleX, c.scaleY]) {
      f.stringValue = String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), v)
    }
  }
  func numberOfRows(in tableView: NSTableView) -> Int { printers.count }
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
  {
    let p = printers[row]
    let v = NSView(frame: NSRect(x: 0, y: 0, width: 680, height: 66))
    let icon = NSImageView(frame: NSRect(x: 14, y: 15, width: 34, height: 34))
    icon.image = NSImage(systemSymbolName: "printer.fill", accessibilityDescription: "Stampante")
    icon.contentTintColor = accent
    v.addSubview(icon)
    label(v, "Xerox Phaser 6010N", 63, 29, 490, 15, true)
    label(v, p.ip + "  ·  " + p.source, 63, 4, 490, 12, false, .secondaryLabelColor)
    return v
  }
  func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
    PrinterRow()
  }
  func tableViewSelectionDidChange(_ notification: Notification) {
    let row = table.selectedRow
    if row >= 0 && row < printers.count { ip.stringValue = printers[row].ip }
  }
  func selectPage(_ index: Int) {
    connection.isHidden = index != 0
    calibration.isHidden = index != 1
    statusPage.isHidden = index != 2
    for (i, b) in nav.enumerated() {
      b.bezelColor = i == index ? accent : nil
      b.contentTintColor = i == index ? .white : .controlTextColor
    }
  }
  @objc func showConnection() { selectPage(0) }
  @objc func showCalibration() { selectPage(1) }
  @objc func showStatus() {
    selectPage(2)
    refreshStatus()
  }
  @objc func search() { discovery.start(knownIP: normalizedIPv4(ip.stringValue)) }
  func authorize(_ command: String) -> String? {
    let escaped = command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(
      of: "\"", with: "\\\"")
    guard
      let script = NSAppleScript(
        source: "do shell script \"\(escaped)\" with administrator privileges")
    else { return "Impossibile richiedere l’autorizzazione." }
    var error: NSDictionary?
    script.executeAndReturnError(&error)
    if let error = error {
      return
        "Operazione non completata: \(error[NSAppleScript.errorMessage] ?? "Autorizzazione non disponibile")"
    }
    return nil
  }
  @objc func add() {
    guard let address = normalizedIPv4(ip.stringValue) else {
      alert("Seleziona una stampante o inserisci un indirizzo IPv4 valido.")
      return
    }
    let ppd = Calibration.directory + "/Phaser6010.ppd"
    guard FileManager.default.fileExists(atPath: ppd) else {
      alert("Installa prima Driver Xerox Phaser 6010N per Mac.")
      return
    }
    let command =
      "if /usr/bin/lpstat -p Phaser6010 >/dev/null 2>&1; then /usr/bin/grep -q 'Xerox Phaser 6010N Community' /etc/cups/ppd/Phaser6010.ppd || { echo 'Il nome Phaser6010 è usato da un’altra stampante.' >&2; exit 1; }; fi; /usr/sbin/lpadmin -p Phaser6010 -E -v socket://\(address):9100 -P \(ppd) -D 'Xerox Phaser 6010N'"
    if let error = authorize(command) {
      alert(error)
      return
    }
    UserDefaults.standard.set(address, forKey: "printerIP")
    connectionStatus.stringValue =
      "Stampante configurata. Ora puoi aprire Calibrazione e stampare il foglio di controllo."
  }
  @objc func calculate() {
    do {
      let values = try measured.map { f -> Double? in
        let s = f.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return nil }
        guard let v = Calibration.number(s) else {
          throw CalibrationError("Inserisci solo misure numeriche in millimetri.")
        }
        return v
      }
      guard values.contains(where: { $0 != nil }) else {
        throw CalibrationError("Inserisci almeno una misura del foglio stampato.")
      }
      let result = try saved.corrected(
        width: values[0], height: values[1], left: values[2], right: values[3], top: values[4],
        bottom: values[5])
      fillCorrections(result)
      calibrationStatus.stringValue =
        "Correzioni calcolate rispetto ai valori già salvati. Controllale e premi Salva calibrazione per applicarle."
    } catch { alert(error.localizedDescription) }
  }
  @objc func saveCalibration() {
    let v = corrections.compactMap { Calibration.number($0.stringValue) }
    guard v.count == 4 else {
      alert("Inserisci quattro valori numerici validi.")
      return
    }
    let c = Calibration(x: v[0], y: v[1], scaleX: v[2], scaleY: v[3])
    guard c.valid else {
      alert("Spostamento massimo ±20 mm; scala tra 50% e 150%.")
      return
    }
    guard FileManager.default.fileExists(atPath: Calibration.directory + "/filter/phaser6010")
    else {
      alert("Installa prima il driver.")
      return
    }
    if let error = authorize(c.saveCommand) {
      alert(error)
      return
    }
    saved = c
    fillCorrections(c)
    measured.forEach { $0.stringValue = "" }
    calibrationStatus.stringValue =
      "Calibrazione salvata. Stampa di nuovo il foglio al 100% per verificare il risultato."
  }
  @objc func reset() {
    fillCorrections(Calibration())
    calibrationStatus.stringValue =
      "Valori standard proposti. Premi Salva calibrazione solo se vuoi applicarli."
  }
  @objc func pdfLanguageChanged() {
    UserDefaults.standard.set(
      pdfLanguage.indexOfSelectedItem == 0 ? "it" : "en", forKey: "pdfLanguage")
  }
  func pdfURL() -> URL? {
    Bundle.main.url(
      forResource: pdfLanguage.indexOfSelectedItem == 0 ? "Centratura-it" : "Calibration-en",
      withExtension: "pdf")
  }
  @objc func openCalibration() {
    guard let url = pdfURL() else {
      alert("Foglio di calibrazione non disponibile nel programma.")
      return
    }
    NSWorkspace.shared.open(url)
  }
  @objc func printCalibration() {
    guard let url = pdfURL(), let document = PDFDocument(url: url) else {
      alert("Foglio di calibrazione non disponibile.")
      return
    }
    let info = (NSPrintInfo.shared.copy() as! NSPrintInfo)
    info.paperSize = NSSize(width: 595.2756, height: 841.8898)
    info.orientation = .portrait
    info.topMargin = 0
    info.bottomMargin = 0
    info.leftMargin = 0
    info.rightMargin = 0
    info.isHorizontallyCentered = false
    info.isVerticallyCentered = false
    info.scalingFactor = 1
    if let printer = NSPrinter(name: "Phaser6010") { info.printer = printer }
    guard
      let operation = document.printOperation(
        for: info, scalingMode: .pageScaleNone, autoRotate: false)
    else {
      alert("Impossibile aprire il dialogo di stampa.")
      return
    }
    operation.showsPrintPanel = true
    operation.showsProgressPanel = true
    operation.run()
  }
  @objc func remove() {
    let a = NSAlert()
    a.messageText = "Disinstallare il driver Xerox Phaser 6010N?"
    a.informativeText =
      "Verranno rimossi driver, utility, calibrazione e coda Phaser6010, compresi i lavori in attesa. Le altre stampanti rimarranno disponibili."
    a.addButton(withTitle: "Annulla")
    a.addButton(withTitle: "Disinstalla")
    guard a.runModal() == .alertSecondButtonReturn else { return }
    guard FileManager.default.fileExists(atPath: Calibration.directory + "/uninstall.sh") else {
      alert("Il driver non risulta installato.")
      return
    }
    if let error = authorize("/bin/bash /Library/Printers/Phaser6010/uninstall.sh") {
      alert(error)
      return
    }
    NSApp.terminate(nil)
  }
  func alert(_ text: String) {
    let a = NSAlert()
    a.messageText = text
    a.runModal()
  }
  func render(_ view: NSView, to path: String) {
    guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
    view.cacheDisplay(in: view.bounds, to: bitmap)
    try? bitmap.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
  }
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
  func applicationWillTerminate(_ notification: Notification) {
    discovery.stop()
    refreshTimer?.invalidate()
  }
}
if CommandLine.arguments.contains("--status-test") {
  do {
    let snap = try PrinterSnapshot.fetch(ip: CommandLine.arguments.last!)
    let e = JSONEncoder()
    e.outputFormatting = [.prettyPrinted, .sortedKeys]
    print(String(data: try e.encode(snap), encoding: .utf8)!)
  } catch {
    fputs(error.localizedDescription + "\n", stderr)
    exit(1)
  }
} else if CommandLine.arguments.contains("--discovery-test") {
  let d = PrinterDiscovery()
  var latest: [DiscoveredPrinter] = []
  d.onUpdate = { items, _ in latest = items }
  d.start(knownIP: UserDefaults.standard.string(forKey: "printerIP"))
  RunLoop.main.run(until: Date().addingTimeInterval(7))
  d.stop()
  let data = try! JSONEncoder().encode(latest)
  print(String(data: data, encoding: .utf8)!)
} else {
  let app = NSApplication.shared
  let delegate = Delegate()
  app.delegate = delegate
  app.setActivationPolicy(.regular)
  withExtendedLifetime(delegate) { app.run() }
}
