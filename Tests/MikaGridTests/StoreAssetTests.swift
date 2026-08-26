// StoreAssetTests.swift
// MikaGridTests
//
// Prüft das Paket unter AppStore/ gegen die Vorgaben von App Store Connect.
//
// Ein Prüfschritt statt eines Skripts: Die Zeichenlimits sind der häufigste Grund für
// eine abgewiesene Einreichung, und `swift test` läuft ohnehin. Wer einen Text
// verlängert, merkt es hier — nicht erst im Formular.
//
// Übernommen aus Mika+FileScope. Drei Prüfungen mussten dabei anders ausfallen, weil es
// hier **zwei** Fassungen gibt; die Begründung steht jeweils an Ort und Stelle.
//
// Alle Prüfungen laufen ohne Netzwerk und ohne laufende App.

import Testing
import Foundation
import AppKit

struct StoreAssetTests {

    // MARK: - Pfade

    /// Projektwurzel aus dem Pfad dieser Datei — unabhängig vom Arbeitsverzeichnis.
    private static let projectRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // MikaGridTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // Projektwurzel

    private var appStore: URL { Self.projectRoot.appendingPathComponent("AppStore") }

    private func text(_ feld: String, locale: String = "en-US") throws -> String {
        try String(contentsOf: appStore.appendingPathComponent("metadata/\(locale)/\(feld)"),
                   encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func quelle(_ pfad: String) throws -> String {
        try String(contentsOf: Self.projectRoot.appendingPathComponent(pfad), encoding: .utf8)
    }

    /// Lokalisierungen, die in App Store Connect angelegt sind.
    private let locales = ["en-US"]

    private let screenshotFormat = "mac-2880x1800"
    private let screenshotSize = NSSize(width: 2880, height: 1800)

    // MARK: - Metadaten

    @Test("Jedes Feld bleibt im Zeichenlimit von App Store Connect")
    func metadataWithinLimits() throws {
        // Apple zählt Zeichen, nicht Bytes.
        let limits: [String: Int] = [
            "name.txt": 30,
            "subtitle.txt": 30,
            "promotional_text.txt": 170,
            "description.txt": 4000,
            "keywords.txt": 100,
            "release_notes.txt": 4000,
        ]
        for locale in locales {
            for (feld, limit) in limits.sorted(by: { $0.key < $1.key }) {
                let inhalt = try text(feld, locale: locale)
                #expect(!inhalt.isEmpty, "\(locale)/\(feld) ist leer")
                #expect(inhalt.count <= limit,
                        "\(locale)/\(feld): \(inhalt.count) Zeichen, erlaubt sind \(limit)")
            }
        }
    }

    @Test("Die Schlüsselwörter verschenken kein Zeichen des Budgets")
    func keywordsWasteNoBudget() throws {
        for locale in locales {
            let keywords = try text("keywords.txt", locale: locale)
            // Ein Leerzeichen nach dem Komma zählt gegen die 100 Zeichen, ohne die Suche
            // zu verbessern.
            #expect(!keywords.contains(", "),
                    "\(locale)/keywords.txt: Leerzeichen nach Komma verschenkt Budget")
            #expect(!keywords.contains(",,"), "\(locale)/keywords.txt: leeres Schlüsselwort")
        }
    }

    /// Fremde Produktnamen im Store-Eintrag sind ein gängiger Ablehnungsgrund. `README.md`
    /// und `web/app/layout.tsx` nennen „Rectangle" als Vergleich — auf der eigenen Website
    /// ist das unbedenklich, im Store nicht. Der Weg von dort hierher ist kurz.
    @Test("Die Store-Texte nennen kein fremdes Produkt")
    func metadataNamesNoForeignProduct() throws {
        let fremd = ["Rectangle", "Magnet", "Moom", "BetterSnapTool", "Divvy", "Yabai"]
        for locale in locales {
            for feld in ["keywords.txt", "description.txt", "subtitle.txt",
                         "promotional_text.txt", "release_notes.txt"] {
                let inhalt = try text(feld, locale: locale)
                for name in fremd {
                    #expect(!inhalt.contains(name),
                            "\(locale)/\(feld) nennt das fremde Produkt »\(name)«")
                }
            }
        }
    }

    @Test("Die drei Adressen sind gesetzt und absolut")
    func urlsAreAbsolute() throws {
        for locale in locales {
            for feld in ["support_url.txt", "marketing_url.txt", "privacy_url.txt"] {
                let url = try text(feld, locale: locale)
                #expect(url.hasPrefix("https://"), "\(locale)/\(feld): \(url) ist keine https-Adresse")
            }
            // Die Datenschutzangabe muss auf die Datenschutzseite zeigen, nicht auf die
            // Startseite — Apple ruft sie auf.
            let privacy = try text("privacy_url.txt", locale: locale)
            #expect(privacy.hasSuffix("/privacy"), "\(locale)/privacy_url.txt zeigt nicht auf /privacy")
        }
    }

    @Test("Kein Platzhalter ist stehengeblieben")
    func noPlaceholdersLeft() throws {
        let verdaechtig = ["TODO", "TBD", "XXX", "Lorem ipsum", "PLACEHOLDER"]
        for locale in locales {
            let ordner = appStore.appendingPathComponent("metadata/\(locale)")
            for datei in try FileManager.default.contentsOfDirectory(
                at: ordner, includingPropertiesForKeys: nil) where datei.pathExtension == "txt" {
                let inhalt = try String(contentsOf: datei, encoding: .utf8)
                for marker in verdaechtig {
                    #expect(!inhalt.localizedCaseInsensitiveContains(marker),
                            "\(locale)/\(datei.lastPathComponent) enthält »\(marker)«")
                }
            }
        }
    }

    // MARK: - Abgleich mit dem Bestand

    @Test("Der Store-Name ist derselbe wie im Bundle")
    func storeNameMatchesBundle() throws {
        let plist = try quelle("Resources/Info-MAS.plist")
        #expect(try plistWert("CFBundleName", in: plist) == text("name.txt"),
                "name.txt weicht von CFBundleName in Info-MAS.plist ab (AK-19)")
    }

    /// ABWEICHUNG vom Vorbild: geprüft wird gegen `Info-MAS.plist`, nicht gegen
    /// `Package.swift`. Dort steht `.macOS(.v14)` — das ist die Direktfassung. Die
    /// Store-Fassung verlangt macOS 15, weil die Fensteraktionen der Kurzbefehle es tun.
    /// Verbatim übernommen prüfte dieser Test die falsche Fassung.
    @Test("Die Beschreibung nennt das Mindestsystem der Store-Fassung")
    func descriptionNamesStoreMinimumVersion() throws {
        let plist = try quelle("Resources/Info-MAS.plist")
        let version = try plistWert("LSMinimumSystemVersion", in: plist)
        let major = version.split(separator: ".").first.map(String.init) ?? version
        #expect(try text("description.txt").contains("macOS \(major)"),
                "Info-MAS.plist verlangt macOS \(version), die Beschreibung sagt etwas anderes")
    }

    /// Die Store-Fassung führt zehn der elf Aktionen aus: `ShortcutsWindowSnapper` gibt für
    /// `.restore` `.nothingToRestore` zurück, weil Kurzbefehle keine Fensterrahmen
    /// zurückmeldet. Website und README zählen elf — das gilt für den Direktvertrieb.
    /// Wandert die Zahl in die Store-Texte, verspricht der Eintrag eine Funktion, die diese
    /// Fassung nicht hat, und das trifft Guideline 2.3 (Accurate Metadata).
    @Test("Die Store-Texte versprechen keine elfte Aktion")
    func storeTextsPromiseNoEleventhAction() throws {
        // Die Zusage steht und fällt mit dieser Zeile im Store-Ziel.
        let snapper = try quelle("Sources/MikaGridMAS/ShortcutsWindowSnapper.swift")
        #expect(snapper.contains("action != .restore"),
                "ShortcutsWindowSnapper kennt kein Restore mehr — dann darf die Beschreibung anders lauten")

        for locale in locales {
            for feld in ["description.txt", "promotional_text.txt", "release_notes.txt",
                         "subtitle.txt"] {
                let inhalt = try text(feld, locale: locale).lowercased()
                #expect(!inhalt.contains("eleven"),
                        "\(locale)/\(feld) verspricht elf Aktionen — diese Fassung führt zehn aus")
            }
        }
    }

    /// AK-20: Der Companion-Kurzbefehl muss **vor** dem Download genannt sein, nicht erst
    /// nach der Installation. Prüfbar ist, dass er überhaupt in der Beschreibung steht —
    /// und zwar in der oberen Hälfte, wo der Store abschneidet.
    @Test("Die Beschreibung nennt den Kurzbefehl früh genug (AK-20)")
    func descriptionNamesCompanionShortcutEarly() throws {
        let beschreibung = try text("description.txt")
        guard let treffer = beschreibung.range(of: "Shortcuts") else {
            Issue.record("description.txt nennt Apples Kurzbefehle überhaupt nicht — AK-20 verletzt")
            return
        }
        let davor = beschreibung.distance(from: beschreibung.startIndex, to: treffer.lowerBound)
        #expect(davor < 700,
                "Der Hinweis auf Kurzbefehle steht erst nach \(davor) Zeichen — im Store ist er dann eingeklappt")
    }

    @Test("Die Store-Fassung verspricht keinen Netzzugriff, den sie hätte")
    func entitlementsCarryNoNetworkClient() throws {
        let entitlements = try quelle("Resources/MikaGridMAS.entitlements")
        #expect(!entitlements.contains("network.client"),
                "Die Beschreibung sagt »not a single network request« — die Entitlements sagen etwas anderes")
    }

    // MARK: - Screenshots

    @Test("Jeder Screenshot hat die zugesagte Größe und keinen Alphakanal")
    func screenshotsHavePromisedSize() throws {
        for locale in locales {
            let ordner = appStore.appendingPathComponent("screenshots/\(locale)/\(screenshotFormat)")
            let dateien = try FileManager.default
                .contentsOfDirectory(at: ordner, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "jpg" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            #expect(!dateien.isEmpty, "\(locale): keine Screenshots")

            for datei in dateien {
                guard let rep = NSImageRep(contentsOf: datei) else {
                    Issue.record("\(datei.lastPathComponent) ließ sich nicht lesen")
                    continue
                }
                #expect(NSSize(width: rep.pixelsWide, height: rep.pixelsHigh) == screenshotSize,
                        "\(datei.lastPathComponent): \(rep.pixelsWide)×\(rep.pixelsHigh)")
                // App Store Connect weist Bilder mit Alphakanal zurück.
                #expect(!rep.hasAlpha, "\(datei.lastPathComponent) hat einen Alphakanal")
            }
        }
    }

    @Test("Jedes Motiv hat eine eigene Rohaufnahme und einen Text")
    func everyShotHasRawCaptureAndText() throws {
        struct Karte: Decodable { let rect: [CGFloat] }
        struct Motiv: Decodable { let file: String; let theme: String; let layout: String; let card: Karte? }
        struct Text: Decodable { let headline: String; let subline: String }
        struct Konfiguration: Decodable { let shots: [Motiv]; let texts: [String: [String: Text]] }

        let daten = try Data(contentsOf: appStore.appendingPathComponent("tools/shots.json"))
        let k = try JSONDecoder().decode(Konfiguration.self, from: daten)

        #expect(!k.shots.isEmpty, "shots.json nennt kein Motiv")
        let bekannteLayouts: Set = ["hero", "text-top", "frame-top", "highlight"]
        let bekannteThemes: Set = ["light", "dark"]

        for motiv in k.shots {
            #expect(bekannteLayouts.contains(motiv.layout),
                    "\(motiv.file): compose.swift kennt kein Layout »\(motiv.layout)«")
            #expect(bekannteThemes.contains(motiv.theme),
                    "\(motiv.file): unbekanntes Thema »\(motiv.theme)«")
            if motiv.layout == "highlight" {
                #expect(motiv.card != nil, "\(motiv.file): Layout highlight ohne »card«")
                #expect(motiv.card?.rect.count == 4, "\(motiv.file): »rect« braucht vier Werte")
            }
            // Eine fehlende Rohaufnahme darf nicht still auf eine andere Sprache
            // zurückfallen — das brächte englische Bilder in einen übersetzten Store.
            for (sprache, texte) in k.texts {
                let quelle = appStore
                    .appendingPathComponent("screenshots/raw/\(sprache)/\(motiv.file).png")
                #expect(FileManager.default.fileExists(atPath: quelle.path),
                        "Rohaufnahme fehlt: \(sprache)/\(motiv.file).png")
                #expect(texte[motiv.file] != nil,
                        "shots.json: kein Text für \(motiv.file) in \(sprache)")
            }
        }
    }

    /// Zwei gleiche Rohaufnahmen sind kein theoretischer Fall: Beim Aufbau dieses Pakets
    /// waren 03 und 04 eine Weile byteweise identisch, weil der Onboarding-Schritt von
    /// selbst weiterschaltete und der Klick dazwischen ins Leere ging. Bei Mika+FileScope
    /// ist derselbe Fehler schon einmal vorgekommen.
    @Test("Keine zwei Motive teilen sich dieselbe Aufnahme")
    func everyShotIsItsOwnCapture() throws {
        let ordner = appStore.appendingPathComponent("screenshots/raw/en")
        let dateien = try FileManager.default
            .contentsOfDirectory(at: ordner, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "png" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        var gesehen: [Int: String] = [:]
        for datei in dateien {
            let summe = try Data(contentsOf: datei).hashValue
            if let anderer = gesehen[summe] {
                Issue.record("\(datei.lastPathComponent) ist identisch mit \(anderer)")
            }
            gesehen[summe] = datei.lastPathComponent
        }
    }

    // MARK: - Die Zusagen der Fragebögen

    /// Die Altersfreigabe und der Datenschutz-Eintrag stehen beide auf „kein
    /// Netzwerkzugriff". Wer eine `URLSession` einbaut, macht damit stillschweigend beide
    /// falsch.
    ///
    /// ABWEICHUNG vom Vorbild, doppelt: Geprüft werden nur `MikaGridCore` und
    /// `MikaGridMAS`, denn `Sources/MikaGrid/` ist die Direktfassung und bindet Sparkle
    /// ein — ein anderes Binary, das nie im Store landet. Und **rekursiv**, weil
    /// `MikaGridCore` die Unterordner `Preferences/` und `Onboarding/` hat; ein flacher
    /// Lauf wie beim Vorbild übersähe die Hälfte der Dateien.
    @Test("Die Quellen der Store-Fassung kennen keinen Netzzugriff")
    func storeSourcesHaveNoNetworkAccess() throws {
        var geprueft = 0
        for ziel in ["Sources/MikaGridCore", "Sources/MikaGridMAS"] {
            let wurzel = Self.projectRoot.appendingPathComponent(ziel)
            guard let lauf = FileManager.default.enumerator(at: wurzel,
                                                           includingPropertiesForKeys: nil) else {
                Issue.record("\(ziel) ließ sich nicht durchlaufen")
                return
            }
            for fall in lauf {
                guard let datei = fall as? URL, datei.pathExtension == "swift" else { continue }
                geprueft += 1
                let inhalt = try String(contentsOf: datei, encoding: .utf8)
                for verboten in ["URLSession", "WKWebView", "NSURLConnection"] {
                    #expect(!inhalt.contains(verboten), """
                        \(datei.lastPathComponent) nennt \(verboten). \
                        AppStore/ALTERSFREIGABEN.md und der Datenschutz-Eintrag sagen beide, \
                        dass die Store-Fassung keine Verbindungen herstellt — beides prüfen.
                        """)
                }
                // Sparkle gehört an die Direktfassung. Im Store-Ziel wäre es ein
                // Update-Kanal, den AK-02 ausschließt — und ein Netzzugriff dazu.
                #expect(!inhalt.contains("\nimport Sparkle"),
                        "\(datei.lastPathComponent) bindet Sparkle ein — das gehört nur ins Direktziel")
            }
        }
        // Ein leerer Durchlauf wäre ein grüner Test ohne Aussage.
        #expect(geprueft > 20, "nur \(geprueft) Dateien geprüft — stimmen die Pfade noch?")
    }

    @Test("Die Altersfreigabe steht in beiden Dokumenten gleich")
    func ageRatingAgreesEverywhere() throws {
        let freigaben = try String(
            contentsOf: appStore.appendingPathComponent("ALTERSFREIGABEN.md"), encoding: .utf8)
        let grunddaten = try String(
            contentsOf: appStore.appendingPathComponent("APP_STORE_CONNECT.md"), encoding: .utf8)

        #expect(freigaben.contains("**Ergebnis: 4+**"), "ALTERSFREIGABEN.md nennt kein Ergebnis")
        #expect(grunddaten.contains("4+"), "APP_STORE_CONNECT.md nennt keine Altersfreigabe")
        // Beide Dateien werden von Hand gepflegt; ein Widerspruch fiele sonst erst im
        // Formular auf.
        for stufe in ["9+", "13+", "16+", "18+"] {
            #expect(!grunddaten.contains("Altersfreigabe | \(stufe)"),
                    "APP_STORE_CONNECT.md sagt \(stufe), ALTERSFREIGABEN.md sagt 4+")
        }
    }

    /// Weicht die Kategorie in App Store Connect von `LSApplicationCategoryType` ab, weist
    /// der Upload mit Fehler 90242 ab. Was in ASC steht, kann von hier niemand prüfen —
    /// wohl aber, dass die Dokumentation denselben Wert nennt wie das Bundle.
    @Test("Die Kategorie im Bundle steht auch in der Dokumentation")
    func categoryIsDocumented() throws {
        let plist = try quelle("Resources/Info-MAS.plist")
        let kategorie = try plistWert("LSApplicationCategoryType", in: plist)
        let grunddaten = try String(
            contentsOf: appStore.appendingPathComponent("APP_STORE_CONNECT.md"), encoding: .utf8)
        #expect(grunddaten.contains(kategorie),
                "APP_STORE_CONNECT.md nennt »\(kategorie)« nicht — Fehler 90242 beim Upload")
    }

    /// Beide Fassungen tragen dieselbe Kennung (OF-04). Ältere Artefakte nennen
    /// `lu.daumedia.mikagrid.mas`; wer die anlegt, bekommt einen Datensatz, in den nie ein
    /// Archiv passt.
    @Test("Beide Fassungen tragen dieselbe Bundle-Kennung")
    func bothEditionsShareTheBundleIdentifier() throws {
        let direkt = try plistWert("CFBundleIdentifier", in: quelle("Resources/Info.plist"))
        let store = try plistWert("CFBundleIdentifier", in: quelle("Resources/Info-MAS.plist"))
        #expect(direkt == store, "Die Kennungen weichen ab — dann ist OF-04 zurückgenommen worden")

        // Geprüft wird die Zeile der Grunddaten-Tabelle, nicht das ganze Dokument: Die
        // hinfällige Kennung `…​.mas` steht dort absichtlich als Warnung, und ein Verbot
        // über den gesamten Text würde genau diese Warnung wieder austreiben.
        let grunddaten = try String(
            contentsOf: appStore.appendingPathComponent("APP_STORE_CONNECT.md"), encoding: .utf8)
        guard let zeile = grunddaten.split(separator: "\n")
            .first(where: { $0.hasPrefix("| Bundle-ID ") }) else {
            Issue.record("APP_STORE_CONNECT.md hat keine Bundle-ID-Zeile in den Grunddaten")
            return
        }
        #expect(zeile.contains(store), "Die Grunddaten nennen eine andere Kennung als das Bundle")
        #expect(!zeile.contains("\(store).mas"),
                "Die Grunddaten nennen die hinfällige Kennung \(store).mas als anzulegende")
    }

    // MARK: - Werkzeug

    private func plistWert(_ schluessel: String, in plist: String) throws -> String {
        guard let key = plist.range(of: "<key>\(schluessel)</key>"),
              let start = plist.range(of: "<string>", range: key.upperBound..<plist.endIndex),
              let ende = plist.range(of: "</string>", range: start.upperBound..<plist.endIndex)
        else {
            Issue.record("\(schluessel) fehlt in der Plist")
            return ""
        }
        return String(plist[start.upperBound..<ende.lowerBound])
    }
}
