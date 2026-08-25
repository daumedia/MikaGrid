# B09 · Build-, Signatur- und DMG-Kette — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Drei Shell-Skripte und ein Swift-Skript, die nacheinander von Hand aufgerufen werden.
`build.sh` übersetzt das Paket, baut aus der ausführbaren Datei ein `.app`-Bundle,
bettet Sparkle ein und signiert. Eines der beiden DMG-Skripte macht daraus einen
Datenträger mit Hintergrundbild und fester Symbolanordnung. `GenerateDMGBackground.swift`
erzeugt dieses Hintergrundbild, wenn es fehlt.

Es gibt keinen Freigabelauf und keine Fließbandsteuerung: kein GitHub Actions, kein
Makefile, keine Prüfung, ob die Versionsangaben an den fünf Stellen zueinander passen.
Wer ein Release macht, ruft die Skripte in der richtigen Reihenfolge auf und trägt die
Signatur danach von Hand in `appcast.xml` nach.

## Einstiegspunkte

| Aufruf | Erzeugt | Voraussetzung |
|---|---|---|
| `bash build.sh` | `build/Mika+Grid.app` | Swift-Toolchain |
| `bash build.sh --clean` | dasselbe, nach Löschen von `.build/` | — |
| `bash scripts/create-dmg-simple.sh` | `installer/Mika+Grid-v<V>.dmg` | fertiges Bundle |
| `bash scripts/create-dmg.sh` | dasselbe, gestalterisch besser | zusätzlich `brew install create-dmg` |
| `swift scripts/GenerateDMGBackground.swift` | `installer/dmg-background*.png` | wird sonst automatisch gerufen |

`build.sh` in der Wurzel ist eine Weiterleitung auf `scripts/build.sh`.

## Ablauf der Kette

```
bash build.sh
├── [--clean]  .build/ löschen
├── swift build -c release                        Übersetzen
├── Bundle aufbauen
│   ├── Contents/MacOS/MikaGrid                   ausführbare Datei
│   ├── Contents/Info.plist                       aus Resources/
│   └── Contents/Resources/AppIcon.icns           falls vorhanden
├── Sparkle einbetten                             ← überspringt still, wenn nicht gefunden (FB-04)
│   ├── Framework nach Contents/Frameworks/ kopieren
│   ├── install_name_tool: rpath @executable_path/../Frameworks
│   └── von innen nach außen signieren
│       ├── XPCServices/*.xpc
│       ├── Versions/B/*.app  (Updater.app)
│       ├── Versions/B/Autoupdate
│       ├── Versions/B/Sparkle
│       └── Sparkle.framework
└── Gesamtbundle signieren                        ← MACHT DIE ZEILE DARÜBER ZUNICHTE (FB-02)
    codesign --force --deep --sign - --entitlements … --options runtime

bash scripts/create-dmg-simple.sh
├── Bundle vorhanden?                             sonst Abbruch mit Hinweis
├── Hintergrundbild fehlt? → GenerateDMGBackground.swift
├── Sparse-Image anlegen (App-Größe + 20 MB)
├── einhängen
├── App kopieren, /Applications verknüpfen, .background/ ablegen, Datenträgersymbol setzen
├── Finder-Anordnung per AppleScript                 ← bei Fehlschlag bleibt das Image eingehängt (EC-05)
├── aushängen
└── nach UDZO umwandeln (zlib-9)                     → installer/Mika+Grid-v<V>.dmg
```

## Erzeugnisse

| Pfad | Inhalt | Versioniert |
|---|---|---|
| `.build/` | Zwischenstände von SPM, Sparkle-Artefakte | nein |
| `build/Mika+Grid.app` | fertiges Bundle | nein |
| `installer/*.dmg` | Auslieferungsdatenträger | nein |
| `installer/dmg-background*.png` | erzeugter Hintergrund | nein |

## Signaturlage — der Kern dieses Features

Stand des gebauten Bundles am 2026-08-25:

| Merkmal | Wert | Bewertung |
|---|---|---|
| Signaturart | `adhoc` | keine Herkunft nachweisbar |
| `TeamIdentifier` | `not set` | Folge der Ad-hoc-Signatur |
| Kennzeichen | `0x10002 (adhoc, runtime)` | Hardened Runtime ist an ✅ |
| `codesign --verify --deep --strict` | bestanden | in sich schlüssig ✅ |
| `spctl -a -vv` | **rejected** | Gatekeeper lehnt ab ❌ |
| Notarisierungsticket am DMG | **keins** | ❌ |
| Entitlements im Bundle | `app-sandbox=false`, `disable-library-validation=true` | wie beabsichtigt |

### Was `--deep` anrichtet — nachgewiesen

Die Skriptzeilen 64–72 signieren Sparkles Bestandteile einzeln und in der richtigen
Reihenfolge, ohne Entitlements. Zeile 76 signiert danach das ganze Bundle mit `--deep`
**und** den Entitlements der App. Ergebnis am fertigen Bundle:

| Bestandteil | Entitlements laut Sparkle-Auslieferung | Entitlements nach dem Build |
|---|---|---|
| `Downloader.xpc` | *leer* (`<dict/>`) | `app-sandbox=false`, `disable-library-validation=true` |
| `Installer.xpc` | *leer* | dieselben |
| `Updater.app` | *leer* | dieselben |

Die einzelnen Signierschritte sind damit wirkungslos — sie werden Sekunden später
überschrieben. Und Bestandteile, die Apple bewusst ohne Sonderrechte ausliefert,
bekommen die Sonderrechte der Wirtsanwendung aufgeprägt.

### Warum `disable-library-validation` überhaupt gesetzt ist

```
ad-hoc signiert  →  App und Sparkle.framework haben keine gemeinsame Team-Kennung
                 →  Library Validation verweigert das Laden des Frameworks
                 →  Entitlement abgeschaltet  (Commit cb04fbe)
```

Die Entitlement behebt also ein Symptom der Ad-hoc-Signatur. Mit einer
Developer-ID-Signatur wäre sie entbehrlich. Sie bleibt trotzdem stehen und schwächt den
Hardened Runtime dauerhaft ab.

## Zugriffsregeln

Die Vorlage sieht Rollen vor; hier gibt es keine. Die entsprechende Frage lautet:
**wer darf ein gültiges Artefakt erzeugen?**

| Fähigkeit | Erfordert | Liegt bei |
|---|---|---|
| Bundle bauen und ad-hoc signieren | nur die Toolchain | jeder, der das Repository hat |
| Ein Update ausliefern, das Sparkle annimmt | den privaten Ed25519-Schlüssel | ausschließlich der Betreiber (Keychain) |
| Ein Artefakt bauen, das Gatekeeper annimmt | Developer-ID-Zertifikat | **niemand** — es existiert keines |

Die mittlere Zeile ist die eigentliche Absicherung des Produkts. Sie greift, und sie
greift nachweislich (siehe B08/AK-06).

## Missbrauchsschutz

| Fläche | Limit | Wo |
|---|---|---|
| Bauen | keins nötig, lokaler Vorgang | — |
| Signieren | Besitz des Schlüsselmaterials | Keychain des Betreibers |
| Verteilen | GitHub-Kontozugriff | GitHub |

## Externe Dienste

| Dienst | Wofür | Was geht hin |
|---|---|---|
| Homebrew (`create-dmg`) | optionales DMG-Werkzeug | nichts — lokal installiert |
| GitHub Releases | Ablage des DMG | das Artefakt selbst, beim Hochladen von Hand |

Keine Fließbandsteuerung, kein Dienst bekommt Quelltext oder Schlüssel.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so (soweit rekonstruierbar) |
|---|---|---|---|
| 1 | Shell-Skript statt Xcode-Projekt | XcodeGen, Tuist | SPM allein baut kein Bundle; ein Skript hält das Projekt bei einem Werkzeug |
| 2 | Ad-hoc-Signatur | Developer ID | Kein Zertifikat vorhanden. Ob bewusst (Kosten) oder aufgeschoben, ist nicht rekonstruierbar — die Landingpage nennt es offen, was für „bewusst" spricht |
| 3 | Hardened Runtime trotz Ad-hoc | weglassen | Kostet nichts und ist Voraussetzung für spätere Notarisierung |
| 4 | Inside-out-Signierung von Sparkle | nur das Gesamtbundle | Das korrekte Muster für verschachtelte Bestandteile — durch `--deep` in Zeile 76 allerdings entwertet |
| 5 | `--deep` beim Signieren | ohne `--deep` | **Grund nicht erkennbar.** Vermutlich in der Annahme übernommen, es sei gründlicher. Apple rät ab |
| 6 | Zwei DMG-Skripte | eines | Das eine braucht Homebrew, das andere nicht — nützlich auf einem frisch aufgesetzten Rechner |
| 7 | Hintergrundbild aus Swift | PNG einchecken | Bleibt im Quelltext nachvollziehbar und mit der Marke änderbar |
| 8 | Signatur für den appcast von Hand | im Skript automatisieren | **Grund nicht erkennbar** — vermutlich, weil `sign_update` erst mit Sparkle dazukam. Folge in FB-06 |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `scripts/build.sh`, Bundle-Aufbau | |
| AK-02 | `--clean`-Auswertung, Zeilen 10–22 | |
| AK-03 | Suche nach dem Framework + `install_name_tool` | still bei Fehlschlag (FB-04) |
| AK-04 | Signierschritt | verifiziert |
| AK-05 | `--options runtime` + `--entitlements` | verifiziert |
| AK-06 | `create-dmg-simple.sh` gesamt | |
| AK-07 | Prüfung auf `$APP_BUNDLE` in beiden DMG-Skripten | |
| AK-08 | `command -v create-dmg` in `create-dmg.sh` | |
| AK-09 | Prüfung auf das Hintergrundbild in beiden Skripten | |
| AK-10 | `PlistBuddy` liest `CFBundleShortVersionString` | |
| AK-11 ⚠ | **nichts** — es gibt keinen Notarisierungsschritt | belegt durch `spctl` und `stapler`; offen als OF-01 |
| AK-12 ⚠ | `codesign --force --deep` in Zeile 76 | belegt am Bundle; offen als OF-02 |
| AK-13 | Abwesenheit von Geheimnissen in den Skripten | |
| AK-14 | Kopierschritte im DMG-Skript | |

Zwei Kriterien (AK-11, AK-12) beschreiben Verhalten, das aus einer **fehlenden** bzw.
einer **schädlichen** Zeile folgt. Sie sind trotzdem Kriterien, weil die QA sie
reproduzieren können muss — nicht, weil das Verhalten richtig wäre.
