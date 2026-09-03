# Mika+Grid — Claude Code Brief

## What is this?
A native macOS Menu Bar app built with Swift + SwiftUI.
It snaps windows to predefined layouts using the macOS Accessibility API — similar to Rectangle.
The app lives exclusively in the menu bar (no Dock icon). Part of the Mika+ ecosystem.

## SDD-Artefakte

**Artefaktpfad: `docs/`** — alle `sdd-`-Skills lesen ihn hier und in Zeile 3 des PRD.

| Datei | Inhalt |
|---|---|
| `docs/prd.md` | Vision, Zielgruppe, Scope, Rahmenbedingungen, Datenschutzstufe A |
| `docs/datenmodell.md` | `UserDefaults`-Schlüssel, flüchtige Speicher, Löschregeln |
| `docs/design-system.md` | Farben, Typografie, Abstände, Komponenten-Grundformen |
| `docs/app-shell.md` | Einstiegspunkte, die drei Fenster, Lebenszyklus |
| `features/index.md` | Feature-Inventar B01–B10, Status, QA-Reihenfolge, projektweite Lücken |
| `features/B<NN>-<slug>/spec.md` | Akzeptanzkriterien und *Fehlbestand* je Feature |
| `features/B<NN>-<slug>/design.md` | Aufbau, Datenhaltung, Zugriff, AK-Abdeckung je Feature |

Erfasst am 2026-08-25 über `sdd-erfassen`, Phase 1 und 2 vollständig. Alle Dokumente sind
**rückwirkend aus dem Bestand** (v1.1.1) geschrieben und beschreiben, was der Code tut,
nicht was er tun sollte. Jedes trägt einen Abschnitt *Fehlbestand* mit den Lücken, die
dabei aufgefallen sind.

Alle zehn Features stehen auf `rekonstruiert`. Der bei der Erfassung gefundene Fehlbestand
wurde in **v1.2.0** abgearbeitet: von 73 Lücken sind 72 geschlossen, von 30 offenen Fragen
29 entschieden. Offen bleibt **ein** Punkt, der Zugangsdaten außerhalb des Repositories
verlangt: die Notarisierung des Direktvertriebs. Er steht in `features/index.md` unter
„Was offen bleibt"; die Landingpage ist seit dem 2026-09-03 unter `grid.daumedia.lu`
erreichbar.

**Beim Arbeiten am Code:** Die Spec des betroffenen Features ist eine *Rekonstruktion*
und kann selbst falsch sein — anders als bei einer Spec, die vor dem Code entstand. Wer
ein Bestandsfeature erweitert, legt ein neues Feature mit eigener Nummer an, das unter
*Abhängigkeiten* darauf verweist.

## App Identity

**Zwei Fassungen aus einem Quelltext** (seit Feature 01). Sie unterscheiden sich an genau
einer Stelle: wie ein Fenster bewegt wird.

**Die Store-Fassung ist seit dem 2026-09-03 freigegeben** — `id6805495907`,
<https://apps.apple.com/app/id6805495907>. Der **Direktvertrieb hinkt hinterher:** Das
neueste GitHub-Release ist 1.1.1, `appcast.xml` kennt keine 1.2.0, und die DMG-Adresse in
`web/lib/app.ts` zeigt auf ein Release, das es nicht gibt. Wer 1.2.0 direkt ausliefern
will, braucht zuerst die Notarisierung.

| | Direktvertrieb | App Store |
|---|---|---|
| **Bundle ID** | `lu.daumedia.mikagrid` | `lu.daumedia.mikagrid` (dieselbe) |
| **Min macOS** | 14.0 (Sonoma) | 15.0 (Sequoia) |
| **Sandbox** | aus | **an** |
| **Fenster bewegt** | selbst, über die Accessibility-API | über Apples Kurzbefehle |
| **Updates** | Sparkle | App Store |
| **Schema** | `MikaGrid (Direct)` | `MikaGrid (App Store)` |

**Beide Fassungen tragen dieselbe Bundle-Kennung** (Betreiberentscheidung 2026-08-26, OF-04
in `features/01-app-store-vertrieb/spec.md`). Sie sind deshalb **nicht nebeneinander
installierbar**: gemeinsame Einstellungen, gemeinsames Anmeldeobjekt, LaunchServices kann
sie nicht unterscheiden. Solange nur ein Vertriebsweg ausgespielt wird, ist das folgenlos —
wer beide gleichzeitig will, muss OF-04 zurücknehmen.

- **Language**: Swift 6.0, SwiftUI
- **Build System**: XcodeGen (`project.yml`) + SwiftPM für Tests
- **Architecture**: arm64 (Apple Silicon)

## Project Structure
```
MikaGrid/
├── CLAUDE.md                        ← you are here
├── README.md
├── CHANGELOG.md
├── project.yml                      ← XcodeGen: DIE WAHRHEIT über beide Ziele
├── Package.swift                    ← SwiftPM: Bibliothek + Direktziel + Tests
├── appcast.xml                      ← Sparkle update feed (GitHub-hosted)
├── .gitignore
├── docs/                            ← SDD-Artefakte (PRD, Datenmodell, Design-System, App-Shell)
├── features/                        ← SDD-Feature-Inventar (B01–B10), Specs je Feature
├── AppStore/                        ← Store-Texte, Screenshots, Fragebogen-Antworten
├── build.sh                         → exec scripts/build.sh
├── Resources/
│   ├── Info.plist                   ← Direktziel: LSUIElement=true, Bundle ID
│   ├── Info-MAS.plist               ← Store-Ziel: macOS 15, URL-Schema, kein Sparkle
│   ├── MikaGrid.entitlements        ← No sandbox
│   ├── MikaGridMAS.entitlements     ← Sandbox + scripting-targets
│   ├── Mika+Grid Snap.shortcut      ← Companion-Kurzbefehl (Dateiname = Anzeigename!)
│   ├── AppIcon.png                  ← 1024x1024 source icon
│   └── AppIcon.icns                 ← macOS icon set
├── Sources/
│   ├── MikaGridCore/                ← BIBLIOTHEK — was beide Fassungen teilen
│   │   ├── WindowSnapping.swift     ← DIE NAHT: snap() + readiness
│   │   ├── UpdateChecking.swift     ← Sparkle hinter einer Schnittstelle (Store: nil)
│   │   ├── AppState.swift           ← @Observable, kennt nur die Schnittstellen
│   │   ├── SnapAction/-Result/-History/-Payload/-Reply.swift
│   │   ├── HotkeyManager · AppPreferences · MikaPlusColors · LaunchAtLoginManager
│   │   ├── PopoverGridView · SnapZoneButton · AboutWindow
│   │   ├── Preferences/             ← Einstellungsfenster
│   │   └── Onboarding/              ← Rahmen, Begrüßung, Kürzelübersicht
│   │
│   ├── MikaGrid/                    ← DIREKTZIEL (nicht sandboxed)
│   │   ├── MikaGridApp.swift        ← @main
│   │   ├── AccessibilityWindowSnapper.swift  ← erfüllt WindowSnapping über AXUIElement
│   │   ├── WindowManager · AccessibilityManager · SparkleUpdater
│   │   └── Onboarding/PermissionScreen.swift
│   │
│   └── MikaGridMAS/                 ← APP-STORE-ZIEL (sandboxed)
│       ├── MikaGridMASApp.swift     ← @main, nimmt mikagrid-mas:// entgegen
│       ├── ShortcutsWindowSnapper.swift      ← erfüllt WindowSnapping über Kurzbefehle
│       ├── ShortcutsRunner.swift    ← Apple Events an „Shortcuts Events"
│       ├── CompanionShortcutManager.swift
│       └── CompanionShortcutScreen.swift     ← Onboarding-Schritt
│
├── scripts/
│   ├── build.sh                     ← Build + app bundle + codesign
│   ├── create-dmg.sh                ← DMG with create-dmg (brew)
│   ├── create-dmg-simple.sh         ← DMG with hdiutil only
│   └── GenerateDMGBackground.swift  ← Branded DMG background
│
└── web/                             ← Marketing site (Next.js, deployed on Vercel)
    ├── lib/app.ts                   ← Version, download URL — sync on every release
    ├── lib/snapActions.ts           ← Mirror of SnapAction.swift
    ├── app/                         ← App Router: layout, page, OG image, robots, sitemap
    └── components/                  ← Nav, Hero, SnapGridDemo, Features, …
```

## Marketing Site (`web/`)

Next.js 15 (App Router) + Tailwind CSS v4, English, dark-only. One static page.

```bash
cd web && npm install && npm run dev   # http://localhost:3000
npm run build                          # must pass before deploying
```

**Deploy**: Vercel with **Root Directory = `web`** (zero-config otherwise).

**Keep in sync on every release** — these mirror Swift/plist sources and will
silently go stale otherwise:
- `web/lib/app.ts` — `version` + `minMacOS` from `Resources/Info.plist`,
  `dmgUrl` from the GitHub release, `dmgSizeMB` from `appcast.xml` (`length`)
- `web/lib/snapActions.ts` — labels and default bindings from `Sources/SnapAction.swift`

Brand tokens live in `web/app/globals.css` (`@theme`) and mirror
`Sources/MikaPlusColors.swift`.

## Snap Actions & Default Shortcuts

| Shortcut | Action | Key Code |
|----------|--------|----------|
| ⌃⌥← | Left Half | 0x7B |
| ⌃⌥→ | Right Half | 0x7C |
| ⌃⌥↑ | Top Half | 0x7E |
| ⌃⌥↓ | Bottom Half | 0x7D |
| ⌃⌥U | Top Left | 0x20 |
| ⌃⌥I | Top Right | 0x22 |
| ⌃⌥J | Bottom Left | 0x26 |
| ⌃⌥K | Bottom Right | 0x28 |
| ⌃⌥↩ | Maximize | 0x24 |
| ⌃⌥C | Center (2/3) | 0x08 |
| ⌃⌥⌫ | Restore | 0x33 |

## Architecture

- **`WindowSnapping` ist die einzige Naht** zwischen beiden Fassungen. Oberhalb davon ist
  nicht erkennbar, welche läuft. Wer einen Unterschied zwischen den Fassungen braucht, baut
  ihn **hier** ein — nicht mit `#if` verstreut über die Oberfläche
- **Apple Events gehen an `Shortcuts Events`, nie an `Shortcuts`.** Nur der UI-lose
  Ereignisdienst führt Kurzbefehle aus, ohne ein Fenster zu öffnen (AK-11). Apple schreibt
  es selbst in sein Skripting-Wörterbuch. Das URL-Schema `shortcuts://` öffnet nachweislich
  ein Fenster und ist deshalb **kein** Rückfallweg
- **Eine leere Antwort von Kurzbefehle ist KEIN Erfolg.** Der jeweils erste Zugriff auf eine
  neue Fähigkeit liefert eine leere Antwort ohne Fehlermeldung — dahinter steckt eine
  einmalige Zustimmung, die macOS bei einem unsichtbaren Aufruf nicht erfragen kann
- **AppState** — `@Observable @MainActor` central state holding all managers
- **WindowManager** — uses `AXUIElementCreateApplication()` + `kAXFocusedWindowAttribute` to get/set window position and size
- **Snap-Ergebnis** — `snapFrontmostWindow` liefert ein `SnapResult`; `AppState.performSnap` erzeugt daraus Systemton und Meldung. Kein Fehlerpfad darf wieder still enden
- **Historien-Schlüssel** — `WindowKey` trägt das `AXUIElement` des Fensters (`CFEqual`/`CFHash`). **Nicht** auf Titel oder PID zurückbauen: Der Titel brach bei jeder Änderung, kollidierte bei titellosen Fenstern und legte Personenbeziehbares in den Speicher
- **Vorschau im Popover** — kommt aus `SnapAction.previewRect`, nicht aus handgebauten Stapeln. `previewRect` rechnet im Einheitsquadrat und **darf nicht runden**; `targetFrame` rundet immer
- **Signatur** — `scripts/build.sh` signiert von innen nach außen und **ohne `--deep`**. `--deep` überschreibt die inneren Signaturen und prägt Sparkles XPC-Diensten die App-Entitlements auf
- **`disable-library-validation`** — steht nicht mehr in den Entitlements. Nur Ad-hoc-Bauten bekommen sie automatisch; mit Developer ID ist sie entbehrlich
- **Snap write sequence — do not "simplify"** — `applyFrame` writes **size → position → size**, not position → size. macOS constrains a position write against the window's *current* size (`NSWindow.constrainFrameRect:toScreen:`), so an oversized window cannot be moved to a target edge until it has been shrunk first. Before writing, `AXEnhancedUserInterface` is temporarily disabled on the **app** element (Chromium/Electron/Java apps and anything under VoiceOver set it; AppKit then *animates* AX frame changes and the size write cancels the position animation) and always restored via `defer`. Afterwards the frame is read back and corrected in up to 3 passes (2 pt tolerance), aborting on stagnation or a 0.6 s deadline
- **AX timeouts** — `AXUIElementSetMessagingTimeout(_, 0.25)` on both app and window element; it applies per object, so it must be set on each. Without it a blocked target app freezes the menu bar
- **Snap target** — `NSWorkspace.shared.frontmostApplication`, unless that is Mika+Grid itself (the `.menuBarExtraStyle(.window)` popover makes the app frontmost); then the cached last-active foreign PID from `didActivateApplicationNotification` is used
- **Coordinate Conversion** — `axY = NSScreen.primaryHeight - cocoaY - windowHeight` (AX=top-left, NSScreen=bottom-left). `primaryHeight` is the display at global origin `(0,0)` — *not* `NSScreen.screens.first`. `SnapAction.targetFrame` rounds the four **edges** (never width/height) so halves tile seamlessly on fractional `visibleFrame`s
- **HotkeyManager** — Carbon `InstallEventHandler` + `RegisterEventHotKey` with `nonisolated(unsafe) static var instance` for callback bridge. The event handler is installed **exactly once** (guarded by `eventHandlerRef`); `reRegisterAll` only swaps hotkeys, since a second `InstallEventHandler` would make one keypress fire twice
- **Communication** — `NotificationCenter` posts `.showPreferences` / `.showAbout` from popover to AppDelegate

## Permissions Required
- **Accessibility**: `AXIsProcessTrusted()` — prompted during onboarding
- **NO App Sandbox** — required for AXUIElement + global hotkeys
- `LSUIElement = true` in Info.plist — hides from Dock

## Shared Patterns with MikaScreenSnap
- `MikaPlusColors.swift` — identical brand color palette
- `HotkeyManager.swift` — same Carbon pattern, different signature ("MKGD" vs "MSNS")
- `LaunchAtLoginManager.swift` — identical SMAppService wrapper
- `PreferencesWindowController.swift` — same NSWindow + NSHostingView pattern
- `OnboardingWindowController.swift` — same window controller pattern
- `AboutWindowController.swift` — same pattern with Mika+Grid branding
- `build.sh` / DMG scripts — adapted from MikaScreenSnap (without Sparkle)

## Build & Run
```bash
swift build                      # Debug build (Direktziel)
swift test                       # 86 tests — run these before touching geometry or hotkeys
bash build.sh                    # Build + app bundle + codesign (Developer ID if available)
bash build.sh --universal        # arm64 + x86_64
open build/Mika+Grid.app         # Launch

xcodegen generate                # nach jeder Änderung an project.yml
xcodebuild -scheme "MikaGrid (App Store)" -derivedDataPath build/xcode-mas build
```

**Getrennte Ableitungsordner sind Pflicht.** Beide App-Ziele erzeugen `Mika+Grid.app`. Im
gemeinsamen Produktordner überschreiben sie einander, und das Store-Bundle erbt dann
`Sparkle.framework` aus dem Direktbau — was AK-02 ausschließt. Einmal beobachtet.

**`info:`/`entitlements:` in `project.yml` ERZEUGEN die Dateien** und überschreiben dabei
vorhandene. Deshalb werden `Info.plist` und die Entitlements nur über `INFOPLIST_FILE`
bzw. `CODE_SIGN_ENTITLEMENTS` referenziert. Einmal hat es die Direkt-Entitlements samt
ihrer Begründung gelöscht.

## App-Store-Paket

- `AppStore/` — Texte, Screenshots und die Werkzeuge, um beides neu zu erzeugen. Aufbau
  nach Fastlane-Konvention (`metadata/<locale>/*.txt`), damit ein späterer Wechsel auf
  `fastlane deliver` ohne Umbau geht. Übernommen aus Mika+FileScope
- **`en-US` ist die einzige Lokalisierung** — die Oberfläche der App ist englisch, eine
  deutsche Headline darüber läse sich wie ein Fehler
- **Die Store-Texte sagen „zehn Aktionen", nicht elf.** `ShortcutsWindowSnapper`
  beantwortet `.restore` mit `.nothingToRestore`; README und Website zählen elf, das gilt
  für den Direktvertrieb. `swift test --filter StoreAssetTests` schlägt fehl, sobald
  „eleven" in einem Store-Text steht
- **Der Companion-Kurzbefehl gehört in die Beschreibung, nicht in den Werbetext** (AK-20:
  Hinweis *vor* dem Download). Der Werbetext ist ohne Review änderbar und trägt deshalb
  keine Pflichtangabe. Geprüft wird, dass „Shortcuts" in den ersten 700 Zeichen vorkommt
- **„Rectangle" darf nicht in die Store-Texte.** README und `web/app/layout.tsx` führen
  den Namen als SEO-Begriff — auf der eigenen Website unbedenklich, im Store ein
  Ablehnungsgrund. Der Test verbietet ihn samt vier weiteren Fremdprodukten
- `AppStore/tools/capture.sh` nimmt die fünf Rohaufnahmen auf, `swift
  AppStore/tools/compose.swift` setzt daraus die fertigen 2880×1800-Bilder.
  **Aufgenommen wird die Store-Fassung** — die Fußzeile des Popovers zeigt „Updates" nur
  bei vorhandenem Update-Kanal, ein Bild der Direktfassung zeigte im Store also eine
  Schaltfläche, die es dort nicht gibt
- **Jede Rohaufnahme ist ein Bildschirmausschnitt, kein Fenster.** Anders als bei
  Mika+FileScope: Diese App hat kein Hauptfenster, und Fensterverwaltung ist an einem
  einzelnen Fenster nicht zu zeigen. Das Popover (280 pt) wird über das
  `highlight`-Layout herausvergrößert
- **Das Popover schließt bei jedem Aktivwerden einer anderen App.** Die Reihenfolge
  „erst snappen, dann Popover, dann aufnehmen" in `capture.sh` ist deshalb nicht
  verhandelbar
- `swift test --filter StoreAssetTests` prüft Zeichenlimits, Bildmaße, Alphakanal,
  Netzfreiheit von `MikaGridCore`/`MikaGridMAS` und den Abgleich mit `Info-MAS.plist`
- `AppStore/CHECKLISTE.md` listet, was nur im Apple-Konto zu erledigen ist — und zwei
  Produktentscheidungen, die vor der Einreichung fallen sollten (BF-08, BF-09)

## Release
```bash
bash scripts/release.sh --check  # Info.plist, CHANGELOG, appcast und web/lib abgleichen
bash scripts/release.sh          # Direktvertrieb: bauen, signieren, notarisieren, DMG
bash scripts/release.sh --store  # App Store: archivieren, exportieren, hochladen
node scripts/check-web-sync.mjs  # web/lib gegen die Swift-Quellen prüfen
bash scripts/make-companion-shortcut.sh   # Companion-Kurzbefehl neu bauen und signieren
```

Der Store-Zweig braucht **`3rd Party Mac Developer Application`** oder
`Apple Distribution` — eine `Developer ID`-Identität genügt dafür **nicht**.

**Store-Pflichtschlüssel in `Resources/Info-MAS.plist`:** `LSApplicationCategoryType`
(sonst weist der Upload mit Fehler **90242** ab — einmal passiert) und
`ITSAppUsesNonExemptEncryption` (erspart die Rückfrage zur Exportkonformität bei jedem
Upload). `release.sh --store` prüft beide, bevor es archiviert. Die Kategorie muss zu der
in App Store Connect gewählten passen.
Notarisierung läuft, sobald `NOTARY_PROFILE` ein hinterlegtes `notarytool`-Profil nennt.

## Create DMG Installer
```bash
bash scripts/create-dmg-simple.sh   # No dependencies
bash scripts/create-dmg.sh          # Requires: brew install create-dmg
```
