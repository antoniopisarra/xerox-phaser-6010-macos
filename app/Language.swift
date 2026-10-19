// SPDX-License-Identifier: GPL-2.0-or-later
import Foundation

enum AppLanguage {
  static func resolve(selection: String?, preferred: String?) -> String {
    if let selection,
      ["it", "en"].contains(selection.trimmingCharacters(in: .whitespacesAndNewlines))
    {
      return selection.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return preferred?.hasPrefix("it") == true ? "it" : "en"
  }
  static var current: String {
    if let value = UserDefaults.standard.string(forKey: "interfaceLanguage"),
      ["it", "en"].contains(value)
    {
      return value
    }
    let installed = try? String(
      contentsOfFile: "/Library/Printers/Phaser6010/interface-language", encoding: .utf8)
    return resolve(selection: installed, preferred: Locale.preferredLanguages.first)
  }
  static let english: [String: String] = [
    "stampante compatibile trovata": "compatible printer found",
    "stampanti compatibili trovate": "compatible printers found",
    "Componente di macOS non disponibile: ": "macOS component unavailable: ",
    "Operazione non completata: ": "Operation not completed: ",
    "Autorizzazione non disponibile": "Authorization unavailable",

    "Nessun aggiornamento": "Not updated yet",
    "Seleziona la stampante nella sezione Stampante.": "Select a printer on the Printer page.",
    "Ricerca delle Phaser 6010 sulla rete locale…":
      "Searching for Phaser 6010 printers on your network…",
    "Seleziona una stampante rilevata oppure inserisci il suo indirizzo IP.":
      "Select a discovered printer or enter its IP address.",
    "Stampa il foglio al 100%, misura e inserisci solo i valori rilevati.":
      "Print at 100%, measure the sheet and enter only the measurements you took.",
    "Configura Xerox Phaser 6010N": "Xerox Phaser 6010N Setup",
    "Configurazione per Mac": "Setup for Mac",
    "Stampante": "Printer",
    "Calibrazione": "Calibration",
    "Stato e toner": "Status and toner",
    "Driver indipendente\nNon ufficiale Xerox": "Independent driver\nNot an official Xerox product",
    "Disinstalla…": "Uninstall…",
    "Rilevata in rete": "Discovered on network",
    "1 stampante compatibile trovata": "1 compatible printer found",
    "Cerco le Phaser 6010 sulla rete locale…":
      "Searching for Phaser 6010 printers on your network…",
    "Nessuna Phaser 6010 rilevata. Puoi usare l’indirizzo IP qui sotto.":
      "No Phaser 6010 found. Enter its IP address below.",
    "Informazioni su Configura Xerox Phaser 6010N": "About Xerox Phaser 6010N Setup",
    "Esci": "Quit",
    "Modifica": "Edit",
    "Taglia": "Cut",
    "Copia": "Copy",
    "Incolla": "Paste",
    "Seleziona tutto": "Select All",
    "Stampa foglio di centratura…": "Print calibration sheet…",
    "La tua stampante.": "Your printer.",
    "Collega la Xerox alla stessa rete del Mac, poi selezionala dall’elenco.":
      "Connect the Xerox to the same network as your Mac, then select it below.",
    "Stampanti in rete": "Network printers",
    "Cerca di nuovo": "Search again",
    "Oppure inserisci l’indirizzo IP": "Or enter the IP address",
    "Esempio: 192.168.1.100": "Example: 192.168.1.100",
    "L’IP selezionato nell’elenco\nviene inserito automaticamente.":
      "Selecting a printer above\nfills in its IP address automatically.",
    "Configura stampante…": "Set up printer…",
    "Una stampa, centrata.": "A well-centered print.",
    "Misura il foglio e lascia all’utility il calcolo delle correzioni.":
      "Measure the sheet and let the utility calculate the corrections.",
    "Apri PDF": "Open PDF",
    "1. Inserisci le misure del foglio stampato": "1. Enter the printed sheet measurements",
    "Quadrato": "Square",
    "Larghezza": "Width",
    "Altezza": "Height",
    "Margini laterali": "Side margins",
    "Sinistra": "Left",
    "Destra": "Right",
    "Margini verticali": "Vertical margins",
    "Sopra": "Top",
    "Sotto": "Bottom",
    "Lascia vuote le misure che non hai rilevato.": "Leave measurements you did not take blank.",
    "Calcola correzioni": "Calculate corrections",
    "2. Verifica le correzioni": "2. Review the corrections",
    "Orizzontale (mm)": "Horizontal (mm)",
    "Verticale (mm)": "Vertical (mm)",
    "Scala larghezza (%)": "Width scale (%)",
    "Scala altezza (%)": "Height scale (%)",
    "Orizzontale: − sinistra / + destra   ·   Verticale: − alto / + basso":
      "Horizontal: − left / + right   ·   Vertical: − up / + down",
    "Valori standard": "Reset values",
    "Salva calibrazione…": "Save calibration…",
    "Stato e toner.": "Status and toner.",
    "Aggiorna": "Refresh",
    "Livelli toner": "Toner levels",
    "Ciano": "Cyan",
    "Giallo": "Yellow",
    "Nero": "Black",
    "Stime della stampante. Aggiornamento automatico ogni 30 secondi in questa sezione.":
      "Printer estimates. Refreshes automatically every 30 seconds while this page is open.",
    "Strumenti": "Tools",
    "Pagina web stampante": "Printer web page",
    "Stampanti e scanner": "Printers & Scanners",
    "Esporta diagnostica…": "Export diagnostics…",
    "Condivisione del Mac…": "Mac sharing…",
    "Condivisione con altri computer.\nAirPrint per iPhone e iPad non incluso in questa versione.":
      "Sharing with other computers.\nAirPrint for iPhone and iPad is not included in this version.",
    "Seleziona una stampante": "Select a printer",
    "Apri Stampante e seleziona la Xerox oppure inserisci il suo indirizzo IP.":
      "Open Printer and select the Xerox or enter its IP address.",
    "Aggiornamento in corso…": "Refreshing…",
    "Aggiornamento…": "Refreshing…",
    "Aggiornato alle ": "Updated at ",
    "\nControlla la coda nelle impostazioni per l’esito dei lavori di stampa.":
      "\nCheck the queue in Settings for print job results.",
    "Non disponibile": "Unavailable",
    "Stato non disponibile": "Status unavailable",
    "Puoi riprovare con Aggiorna.": "Use Refresh to try again.",
    "Seleziona prima una stampante.": "Select a printer first.",
    "Il report non include documenti, titoli dei lavori, nomi utente o indirizzi di rete.":
      "The report excludes documents, job titles, usernames and network addresses.",
    "Impossibile salvare la diagnostica: ": "Unable to save diagnostics: ",
    "Impossibile richiedere l’autorizzazione.": "Unable to request authorization.",
    "Seleziona una stampante o inserisci un indirizzo IPv4 valido.":
      "Select a printer or enter a valid IPv4 address.",
    "Installa prima Driver Xerox Phaser 6010N per Mac.":
      "Install the Xerox Phaser 6010N driver for Mac first.",
    "Stampante configurata. Ora puoi aprire Calibrazione e stampare il foglio di controllo.":
      "Printer configured. Open Calibration to print the test sheet.",
    "Inserisci solo misure numeriche in millimetri.":
      "Enter numeric measurements in millimeters only.",
    "Inserisci almeno una misura del foglio stampato.":
      "Enter at least one measurement from the printed sheet.",
    "Correzioni calcolate rispetto ai valori già salvati. Controllale e premi Salva calibrazione per applicarle.":
      "Corrections calculated from the saved settings. Review them and choose Save calibration to apply.",
    "Inserisci quattro valori numerici validi.": "Enter four valid numeric values.",
    "Spostamento massimo ±20 mm; scala tra 50% e 150%.":
      "Maximum offset ±20 mm; scale must be between 50% and 150%.",
    "Installa prima il driver.": "Install the driver first.",
    "Calibrazione salvata. Stampa di nuovo il foglio al 100% per verificare il risultato.":
      "Calibration saved. Print the sheet again at 100% to check the result.",
    "Valori standard proposti. Premi Salva calibrazione solo se vuoi applicarli.":
      "Default values shown. Choose Save calibration to apply them.",
    "Foglio di calibrazione non disponibile nel programma.":
      "The calibration sheet is missing from the application.",
    "Foglio di calibrazione non disponibile.": "Calibration sheet unavailable.",
    "Impossibile aprire il dialogo di stampa.": "Unable to open the print dialog.",
    "Disinstallare il driver Xerox Phaser 6010N?": "Uninstall the Xerox Phaser 6010N driver?",
    "Verranno rimossi driver, utility, calibrazione e coda Phaser6010, compresi i lavori in attesa. Le altre stampanti rimarranno disponibili.":
      "This removes the driver, utility, calibration and Phaser6010 queue, including pending jobs. Other printers will remain available.",
    "Annulla": "Cancel",
    "Disinstalla": "Uninstall",
    "Il driver non risulta installato.": "The driver is not installed.",
    "Il lato del quadrato deve essere compreso tra 50 e 150 mm.":
      "The square side must measure between 50 and 150 mm.",
    "I margini devono essere compresi tra 0 e 50 mm.": "Margins must be between 0 and 50 mm.",
    "Inserisci entrambi i margini della stessa coppia.": "Enter both margins in the same pair.",
    "Correzione fuori intervallo: massimo 20 mm e scala tra 50% e 150%. Controlla le misure.":
      "Correction out of range: maximum 20 mm and scale 50–150%. Check your measurements.",
    "Risposta troppo grande.": "Response too large.",
    "La risposta non identifica una Xerox Phaser 6010N compatibile.":
      "The response does not identify a compatible Xerox Phaser 6010N.",
    "Inserisci un indirizzo IPv4 valido.": "Enter a valid IPv4 address.",
    "Stato non disponibile. La stampante potrebbe non rispondere alle richieste di monitoraggio.":
      "Status unavailable. The printer may not be responding to monitoring requests.",
    "Pronta": "Ready",
    "Stampa in corso": "Printing",
    "Riscaldamento": "Warming up",
    "Raggiungibile": "Reachable",
  ]
}
func L(_ italian: String) -> String {
  AppLanguage.current == "en" ? AppLanguage.english[italian] ?? italian : italian
}
