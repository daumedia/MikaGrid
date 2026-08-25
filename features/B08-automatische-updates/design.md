# B08 · Automatische Updates — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.** Es beschreibt den Bestand, wie er ist.

## Überblick

Die App hält genau ein Objekt vor, das Sparkle steuert: einen
`SPUStandardUpdaterController`, der beim Erzeugen sofort startet. Er liest die Adresse
des Update-Verzeichnisses und den öffentlichen Signaturschlüssel aus der `Info.plist`
des Bundles — die App reicht ihm nichts davon programmatisch nach. Von da an erledigt
Sparkle alles selbst: Zeitplan, Abruf, Versionsvergleich, Download, Signaturprüfung,
Installation und die zugehörigen Fenster.

Die eigene Hülle ist bewusst dünn. Sie besteht aus vier durchgereichten Eigenschaften
und einer Methode; eigene Logik gibt es nicht. Zwei Schaltflächen und ein Schalter in
der Oberfläche greifen darauf zu.

## Einstiegspunkte

Die Vorlage sieht hier Routen vor; eine Menüleisten-App hat keine.

| Einstieg | Ort | Wirkung | Zugang |
|---|---|---|---|
| „Updates" | Fußzeile des Popovers | Prüfung mit sichtbarer Rückmeldung | jeder Nutzer |
| „Check Now" | Einstellungen → Allgemein → Updates | dieselbe Prüfung | jeder Nutzer |
| „Automatic updates" | Einstellungen → Allgemein → Updates | schaltet die zeitgesteuerte Prüfung | jeder Nutzer |
| Zeitplan | keiner — Sparkle-intern | Prüfung im Standardintervall (24 h) | — |
| „Last checked …" | Einstellungen → Allgemein → Updates | reine Anzeige | — |

## Komponentenstruktur

```
AppState
└── SparkleUpdater                      dünne Hülle, hält den Controller am Leben
    └── SPUStandardUpdaterController     startingUpdater: true, beide Delegates nil
        ├── SPUUpdater                   Zeitplan, Feed-Abruf, Versionsvergleich
        │   ├── canCheckForUpdates       durchgereicht — von der Oberfläche NIE gelesen
        │   ├── automaticallyChecksForUpdates   ←→ Schalter „Automatic updates"
        │   └── lastUpdateCheckDate      → Anzeige „Last checked … ago"
        └── SPUStandardUserDriver        alle sichtbaren Update-Fenster

Oberfläche
├── PopoverGridView / Fußzeile
│   └── „Updates"        → sparkleUpdater.checkForUpdates()
└── GeneralTabView / GroupBox „Updates"
    ├── Toggle           ←→ sparkleUpdater.automaticallyChecksForUpdates
    ├── „Last checked"   ←  sparkleUpdater.lastUpdateCheckDate
    └── „Check Now"      → sparkleUpdater.checkForUpdates()
```

## Konfiguration statt Datenmodell

Es gibt keine Tabellen. Was das Verhalten bestimmt, steht an zwei Orten.

### Im Bundle — `Resources/Info.plist`

| Schlüssel | Wert | Bedeutung |
|---|---|---|
| `SUFeedURL` | `https://raw.githubusercontent.com/daumedia/MikaGrid/master/appcast.xml` | Wo das Verzeichnis liegt. **Zweig `master`** — siehe FB-01 |
| `SUPublicEDKey` | `eauiHgP4PM9ynLekAmo3URrX3ye3HW7D53xOZa5AeYI=` | Öffentlicher Ed25519-Schlüssel. Nachweislich identisch mit dem Schlüssel im Keychain des Betreibers |
| `CFBundleVersion` | `2` | Die Zahl, gegen die `sparkle:version` verglichen wird |
| `CFBundleShortVersionString` | `1.1.1` | Anzeigeversion |
| `SUEnableSystemProfiling` | *fehlt* | Damit gilt der Sparkle-Standard: kein Profiling |
| `SUScheduledCheckInterval` | *fehlt* | Damit gilt der Sparkle-Standard: 24 Stunden |

### Zur Laufzeit — `UserDefaults`, Suite `lu.daumedia.mikagrid`

Alle von Sparkle geschrieben, keiner davon von der App selbst. Stand des geprüften
Systems am 2026-08-25:

| Schlüssel | Wert | In der Oberfläche |
|---|---|---|
| `SUEnableAutomaticChecks` | `1` | ja — „Automatic updates" |
| `SUAutomaticallyUpdate` | `1` | **nein** — kein Schalter vorhanden (FB-05) |
| `SUSendProfileInfo` | `0` | nein |
| `SULastCheckTime` | Zeitstempel | ja — als „Last checked … ago" |
| `SUHasLaunchedBefore` | `1` | nein |

### Das Verzeichnis — `appcast.xml`

Ein RSS-Kanal mit einem `<item>` je Fassung. Maßgeblich je Eintrag:

| Feld | Wofür | Stand 1.1.1 |
|---|---|---|
| `sparkle:version` | Vergleich gegen `CFBundleVersion` | `2` |
| `sparkle:shortVersionString` | Anzeige | `1.1.1` |
| `sparkle:minimumSystemVersion` | Ausschluss zu alter Systeme | `14.0` |
| `enclosure/url` | Download | GitHub-Release-Adresse |
| `enclosure/length` | Prüfsumme auf Größe | `2543170` — verifiziert |
| `enclosure/sparkle:edSignature` | Echtheit | verifiziert, inkl. Negativkontrollen |

## Vertrauensmodell

Die Vorlage sieht Zugriffsregeln je Rolle vor. Hier gibt es keine Rollen — die Frage
lautet stattdessen: **Wem vertraut die App, wenn sie Code installiert?**

| Was | Wird geprüft durch | Greift |
|---|---|---|
| Echtheit des DMG | Ed25519-Signatur gegen `SUPublicEDKey` | ✅ verifiziert am ausgelieferten Artefakt |
| Unversehrtheit des DMG | dieselbe Signatur + `length` | ✅ verifiziert |
| Transportweg | HTTPS zu `raw.githubusercontent.com` und GitHub Releases | ✅ durch die Plattform |
| **Aktualität der Aussage** („ist das wirklich die neueste Fassung") | **nichts** — der Feed selbst ist unsigniert | ❌ FB-06 |
| Ob überhaupt geprüft wurde | **nichts** — kein Delegate, kein Protokoll | ❌ FB-04 |

Der private Signierschlüssel liegt ausschließlich im Keychain des Betreibers. Er ist
nicht im Repository, nicht in den Skripten und nicht im Bundle. Das ist der Kern der
Kette: Wer ihn nicht hat, kann kein Update ausliefern, das Sparkle annimmt.

## Missbrauchsschutz

| Fläche | Limit | Verhalten | Wo |
|---|---|---|---|
| Feed-Abruf | keins in der App | Häufigkeit bestimmt Sparkle (24 h) | Sparkle |
| Download | keins | GitHub CDN | Plattform |
| Installation | Signaturprüfung | Abbruch bei Abweichung | Sparkle |

Ein eigener Endpunkt existiert nicht, ein Rate Limit ist deshalb gegenstandslos. Kosten
entstehen pro Aufruf keine, weil GitHub öffentliche Repositories und Release-Anhänge
kostenlos ausliefert.

## Externe Dienste

| Dienst | Wofür | Was geht hin | Was wird vorher entfernt |
|---|---|---|---|
| GitHub (`raw.githubusercontent.com`) | Update-Verzeichnis | HTTPS-Abruf: IP-Adresse, Zeitpunkt, User-Agent von Sparkle | nichts zu entfernen — die App sendet keine eigenen Daten |
| GitHub Releases | DMG-Download | dasselbe, plus die Größe des Transfers | — |

Kein Auftragsverarbeitungsvertrag vorhanden und bei Stufe A auch nicht erforderlich: Es
werden keine personenbezogenen Daten *verarbeitet*, sondern nur die technisch
unvermeidbare Verbindungsinformation übertragen, die jeder Abruf einer öffentlichen
Datei erzeugt.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so (soweit rekonstruierbar) |
|---|---|---|---|
| 1 | Sparkle statt Eigenbau | eigener Update-Dienst; nur Hinweis auf neue Version | Signaturprüfung, Installationslogik und Oberfläche fertig vorhanden; Eigenbau wäre genau der Teil, bei dem ein Fehler die schwersten Folgen hat |
| 2 | `SPUStandardUpdaterController` statt `SPUUpdater` direkt | volle Kontrolle über die Oberfläche | Der Standardweg bringt alle Fenster mit; die App wollte offenkundig keine eigene Update-Oberfläche bauen |
| 3 | Beide Delegates `nil` | Delegate für Protokollierung und Fehlermeldungen | **Grund nicht erkennbar.** Vermutlich Sparsamkeit beim Aufsetzen — die Folge steht in FB-04 |
| 4 | Feed im selben Repository | eigener Server, GitHub Pages, S3 | Kostenlos, versioniert, kein weiterer Dienst. Der Preis ist die Zweig-Abhängigkeit aus FB-01 |
| 5 | `@preconcurrency import Sparkle` | Sparkle-Aufrufe abschirmen | Sparkles Schnittstelle ist nicht auf Swift-6-Nebenläufigkeit ausgelegt; der Import unterdrückt die Warnungen. Die Hülle ist `@MainActor`, alle Zugriffe laufen also ohnehin auf dem Hauptstrang |
| 6 | Kein `SUScheduledCheckInterval` | eigenes Intervall | Sparkle-Standard von 24 h übernommen — für ein Werkzeug ohne Sicherheitsfunktion angemessen |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `SUFeedURL` in `Info.plist` + `SPUUpdater`-Zeitplan | live verifiziert |
| AK-02 | `PopoverGridView` Fußzeile → `checkForUpdates()` | |
| AK-03 | `GeneralTabView` „Check Now" → dieselbe Methode | |
| AK-04 | `lastUpdateCheckDate` → `Text(…, style: .relative)` | |
| AK-05 | `automaticallyChecksForUpdates` ↔ `SUEnableAutomaticChecks` | Sparkle persistiert selbst |
| AK-06 | `SUPublicEDKey` + Sparkles Signaturprüfung | verifiziert mit Negativkontrolle |
| AK-07 | dieselbe Prüfung | verifiziert |
| AK-08 | `enclosure/length` | verifiziert |
| AK-09 | `sparkle:minimumSystemVersion` je Eintrag | |
| AK-10 ⚠ | `SUAutomaticallyUpdate`, gesetzt durch Sparkles Erstdialog | **Kein Gegenstück in der Oberfläche** — offen als OF-01 |
| AK-11 | fehlendes `SUEnableSystemProfiling` | am laufenden System bestätigt |
| AK-12 | Ausbleiben eigener Netzaufrufe | |
| AK-13 | Ausbleiben eigener Netzaufrufe | |

Keine Zeile ohne Zuordnung. Umgekehrt gilt: `canCheckForUpdates` wird von der Hülle
bereitgestellt, aber von keiner Oberfläche gelesen — ein Kandidat für toten Code, der
kein Kriterium verletzt und deshalb hier nur vermerkt ist.
