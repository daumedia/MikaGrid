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

Alle zehn Features stehen auf `rekonstruiert` — 148 Akzeptanzkriterien, davon 26 mit ⚠
markiert („das tut der Code heute, soll er das?"), 73 Fehlbestand-Einträge, 30 offene
Fragen. Nächster Schritt ist `/sdd-qa B08`; die Reihenfolge steht in `features/index.md`.

**Beim Arbeiten am Code:** Die Spec des betroffenen Features ist eine *Rekonstruktion*
und kann selbst falsch sein — anders als bei einer Spec, die vor dem Code entstand. Wer
ein Bestandsfeature erweitert, legt ein neues Feature mit eigener Nummer an, das unter
*Abhängigkeiten* darauf verweist.

## App Identity
- **Name**: Mika+Grid
- **Bundle ID**: lu.daumedia.mikagrid
- **Min macOS**: 14.0 (Sonoma)
- **Language**: Swift 6.0, SwiftUI
- **Build System**: Swift Package Manager
- **Architecture**: arm64 (Apple Silicon)

## Project Structure
```
MikaGrid/
├── CLAUDE.md                        ← you are here
├── README.md
├── CHANGELOG.md
├── Package.swift                    ← SPM config (macOS 14+, Carbon, ApplicationServices, Sparkle)
├── appcast.xml                      ← Sparkle update feed (GitHub-hosted)
├── .gitignore
├── docs/                            ← SDD-Artefakte (PRD, Datenmodell, Design-System, App-Shell)
├── features/                        ← SDD-Feature-Inventar (B01–B10), Specs je Feature
├── build.sh                         → exec scripts/build.sh
├── Resources/
│   ├── Info.plist                   ← LSUIElement=true, Bundle ID
│   ├── MikaGrid.entitlements        ← No sandbox
│   ├── AppIcon.png                  ← 1024x1024 source icon
│   └── AppIcon.icns                 ← macOS icon set
├── Sources/
│   ├── MikaGridApp.swift            ← @main, MenuBarExtra + AppDelegate
│   ├── AppState.swift               ← @Observable central state
│   ├── AppPreferences.swift         ← UserDefaults-backed preferences
│   ├── MikaPlusColors.swift         ← Brand colors (shared with MikaScreenSnap)
│   ├── LaunchAtLoginManager.swift   ← SMAppService wrapper
│   ├── AboutWindow.swift            ← About window with Mika+ branding
│   │
│   ├── # Window Management Core
│   ├── WindowManager.swift          ← AXUIElement window manipulation
│   ├── SnapAction.swift             ← 11 snap actions + geometry + default bindings
│   ├── SnapHistory.swift            ← Previous positions for restore
│   ├── AccessibilityManager.swift   ← Permission check/request/polling
│   │
│   ├── # Auto-Update
│   ├── SparkleUpdater.swift         ← Sparkle wrapper (SPUStandardUpdaterController)
│   │
│   ├── # Global Hotkeys
│   ├── HotkeyManager.swift          ← Carbon RegisterEventHotKey (sig: "MKGD")
│   │
│   ├── # Menu Bar UI
│   ├── PopoverGridView.swift        ← Visual snap grid popover
│   ├── SnapZoneButton.swift         ← Clickable zone with monitor preview
│   │
│   ├── # Settings
│   ├── Preferences/
│   │   ├── PreferencesStyles.swift          ← Tab enum
│   │   ├── PreferencesWindowController.swift
│   │   ├── PreferencesContainerView.swift   ← NavigationSplitView
│   │   ├── GeneralTabView.swift             ← Launch at Login, animations
│   │   ├── ShortcutsTabView.swift           ← Inline recorder + conflict detection
│   │   └── AboutTabView.swift               ← Version, reset, onboarding
│   │
│   └── # Onboarding
│       └── Onboarding/
│           ├── OnboardingWindowController.swift
│           ├── OnboardingView.swift         ← Paged container
│           ├── WelcomeScreen.swift          ← "Snap. Organize. Focus."
│           ├── PermissionScreen.swift       ← Accessibility + auto-polling
│           └── ShortcutsScreen.swift        ← Shortcuts overview
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

- **AppState** — `@Observable @MainActor` central state holding all managers
- **WindowManager** — uses `AXUIElementCreateApplication()` + `kAXFocusedWindowAttribute` to get/set window position and size
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
swift build              # Debug build
swift build -c release   # Release build
bash build.sh            # Build + app bundle + codesign
open build/Mika+Grid.app # Launch
```

## Create DMG Installer
```bash
bash scripts/create-dmg-simple.sh   # No dependencies
bash scripts/create-dmg.sh          # Requires: brew install create-dmg
```
