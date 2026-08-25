# Mika+Grid — Design-System

Stand: 2026-08-25 · Artefaktpfad: `docs/`

> **Rekonstruktion aus dem Bestand (Version 1.1.1).** Alle Zahlen sind aus dem Quelltext
> ausgezählt, nicht geschätzt. Wo Wildwuchs steht, ist er **dokumentiert, nicht
> bereinigt** — eine Aufräumaktion ist ein eigenes Feature mit eigener Spec, keine
> Nebenwirkung der Erfassung.

## 1 · Farben

Es gibt genau eine Farbquelle: `Sources/MikaPlusColors.swift`. Sie definiert neun Token
zweifach — einmal als `NSColor.MikaPlus`, einmal als durchgereichte `Color.MikaPlus` —
und wird laut `CLAUDE.md` mit MikaScreenSnap geteilt.

| Token | Hex | Verwendungen im UI | Anmerkung |
|---|---|---|---|
| `tealPrimary` | `#1D9E75` | 13 | Die Markenfarbe. Primärbuttons, Symbole, Hover, aktiver Seitenpunkt |
| `tealLight` | `#5DCAA5` | 7 | Kürzelbeschriftungen, Nebentext auf dunklem Grund |
| `textPrimary` | `#E1F5EE` | 6 | Haupttext auf dunklen Flächen |
| `darkBg` | `#1A1A2E` | 2 | Verlaufsende in Onboarding und Über-Fenster |
| `darkBgDeep` | `#0F0F1A` | 2 | Verlaufsanfang, dieselben zwei Stellen |
| `textSecondary` | `#9FE1CB` | 2 | Nebentext auf dunklem Grund |
| `tealLightest` | `#9FE1CB` | **0** | ungenutzt — **wertgleich mit `textSecondary`** |
| `tealSurface` | `#E1F5EE` | **0** | ungenutzt — **wertgleich mit `textPrimary`** |
| `destructive` | `#E24B4A` | **0** | ungenutzt. Die einzige destruktive Aktion der App („Reset All Settings") benutzt stattdessen das System-`.red` |

**Zwei Farbwerte tragen zwei Namen.** `#E1F5EE` heißt sowohl `tealSurface` als auch
`textPrimary`, `#9FE1CB` sowohl `tealLightest` als auch `textSecondary`. Von jedem Paar
wird genau einer benutzt. Neun Token, sieben unterscheidbare Farben, sechs tatsächlich
im Einsatz.

### Farben außerhalb des Token-Satzes

Statusfarben sind nirgends als Token definiert und stehen hart im Code:

| Wert | Wo | Bedeutung |
|---|---|---|
| `Color.green` | Popover-Statuspunkt, Häkchen im Berechtigungsschritt, Preferences-Statuszeile | Berechtigung erteilt |
| `Color.orange` | Popover-Statuspunkt, Warnbanner (`opacity 0.1` als Fläche), Preferences-Statuszeile | Berechtigung fehlt |
| `.red` | „Reset All Settings", Kürzelkonflikt-Meldung | Gefahr / Fehler |
| `Color.accentColor` | Rahmen und Text des aufnehmenden Kürzelfelds | Aufnahme läuft (folgt der Systemfarbe des Nutzers) |
| `Color.gray.opacity(0.5)` | inaktive Seitenpunkte im Onboarding | — |
| `Color.white.opacity(0.05)` | Zeilenhintergrund der Kürzelliste im Onboarding | — |
| `Color.secondary.opacity(0.4)` | Umriss der Monitorvorschau | — |

Dazu die semantischen Hierarchiestufen von SwiftUI: `.secondary` (8×), `.primary` (1×),
`.white` (3×), `.quaternary` (1×, Füllung des Kürzelfelds).

### Der Bruch zwischen hell und dunkel

Die App verhält sich in zwei Hälften unterschiedlich, und das ist im hellen Systemmodus
sichtbar:

| Oberfläche | Grund | Verhalten im hellen Modus |
|---|---|---|
| Onboarding, Über-Fenster | erzwungener `LinearGradient` von `darkBgDeep` nach `darkBg`, Text in `textPrimary` | bleibt **dunkel** |
| Popover, Einstellungen | keine eigene Fläche, System-Semantik (`.primary`, `.secondary`, `GroupBox`) | wird **hell** |

Es gibt keinen `.preferredColorScheme(.dark)`, keine Anpassung an
`@Environment(\.colorScheme)` und keine hellen Gegenstücke der Markenfarben. Wer die App
im hellen Modus benutzt, sieht ein helles Popover und ein dunkles Über-Fenster.

### Abgleich mit der Landingpage

`web/app/globals.css` führt dieselbe Palette als Tailwind-`@theme` und ist **deckungs-
gleich** — `#1d9e75`, `#5dcaa5`, `#9fe1cb`, `#e1f5ee`, `#1a1a2e`, `#0f0f1a`, `#e24b4a`.
Die Website ergänzt drei abgeleitete Flächen (`--color-line`, `--color-line-strong`,
`--color-elevated`), die es in der App nicht gibt. Anders als die App benutzt sie
`destructive` und `teal-surface` tatsächlich.

## 2 · Typografie

**Keine Schriftskala, keine benannten Stufen.** Größen stehen als Zahl an der
Verwendungsstelle:

| Größe | Häufigkeit | Wofür |
|---|---|---|
| 8 pt | 1 | Kürzelbeschriftung unter einer Rasterzone |
| 9 pt | 1 | Aktionsname unter einer Rasterzone |
| 11 pt | 8 | Fußzeile des Popovers, Warnbanner, Nebentexte |
| 12 pt | 5 | Kürzelfeld, „Skip for now", Versionszeile |
| 13 pt | 5 | Fließtext im Onboarding, Listenzeilen |
| 14 pt | 5 | Titel im Popover-Kopf, Beschriftung von Primärbuttons |
| 16 pt | 1 | Symbol im Popover-Kopf |
| 18 pt | 1 | „Mika+Grid" im Über-Tab |
| 20 pt | 3 | Überschriften von Onboarding-Schritten, Titel im Über-Fenster |
| 22 pt | 1 | „Welcome to Mika+Grid" |
| 48 pt | 3 | große Symbole (Schloss, Häkchen, App-Symbol) |

Elf Größen, alle als `.system(size:)`. Dazu zwei semantische Ausnahmen:
`.title2.bold()` (3×, die Überschrift jedes Einstellungsbereichs) und `.caption` (2×).

Schriftfamilie ist durchgängig die Systemschrift. Für Kürzel und Versionsnummern wird
`design: .monospaced` gesetzt (4×). **Die Landingpage benutzt dagegen Inter, Inter Tight
und JetBrains Mono** — die Marke sieht im Web anders aus als in der App.

**Kein Dynamic Type.** Keine einzige Größe ist über `relativeTo:` an eine Textstilstufe
gebunden. Wer die Systemschriftgröße erhöht, sieht in Mika+Grid unveränderte 8-pt-Labels.

## 3 · Abstände

Ebenfalls ohne Token, direkt an der Verwendungsstelle:

- **`spacing`:** 0 (15×, meist Layout-Hilfsstapel), 4, 6, 8 (8×), 12, 16, 20, 24
- **`padding`:** 3, 4, 6, 8, 10, 12, 14, 16, 24, 40

Ein 4er-Raster ist erkennbar, aber nicht durchgehalten: 3, 6, 10 und 14 fallen heraus.
`8` ist mit Abstand das häufigste Maß und damit der faktische Grundabstand.

## 4 · Radien und feste Maße

| Radius | Wo |
|---|---|
| 2 | Umriss der Monitorvorschau |
| 5 | Kürzelfeld im Recorder |
| 6 | Warnbanner, Hover-Fläche einer Rasterzone, Zeilen der Kürzelliste |
| 8 | Primärbuttons |

| Fläche | Maß | Ort |
|---|---|---|
| Popover | 280 pt breit, Höhe aus dem Inhalt | `PopoverGridView` |
| Einstellungsfenster | 580 × 420 | zweimal festgelegt: im `NSWindow` *und* im SwiftUI-`frame` |
| Onboarding | 480 × 560 | ebenfalls zweimal festgelegt |
| Über-Fenster | 320 × 400 | im `NSWindow`; die Ansicht selbst füllt frei |
| Monitorvorschau | 40 × 26 | `SnapZoneButton`, als `private var` statt als Konstante |
| Primärbutton | 200 × 40 | Onboarding, dreimal |
| Kürzelfeld | `minWidth: 100` | Recorder |
| Seitenpunkt | 8 × 8 | Onboarding |
| Statuspunkt | 8 × 8 | Popover-Kopf |

## 5 · Wiederkehrende Grundformen

Vier Muster treten mehrfach auf. Keines ist als wiederverwendbare Komponente
herausgezogen — sie sind jeweils kopiert:

**Primärbutton** — `Text` in 14 pt medium, weiß, Fläche `tealPrimary`, 200 × 40,
Radius 8, `.buttonStyle(.plain)`. Dreimal wörtlich wiederholt in `WelcomeScreen:35`,
`PermissionScreen:49` und `ShortcutsScreen:77`. Kein `ButtonStyle`, kein gemeinsamer
View.

**Fenster-Controller** — `NSObject`/`NSWindowDelegate` mit privatem `NSWindow`, Prüfung
auf ein bereits sichtbares Fenster, `NSHostingView` als `contentView`, `center()`,
`NSApp.activate()`, `isReleasedWhenClosed = false`, Freigabe in `windowWillClose`.
Dreimal nahezu identisch: `PreferencesWindowController`, `OnboardingWindowController`,
`AboutWindowController`. Laut `CLAUDE.md` ist dasselbe Muster auch mit MikaScreenSnap
geteilt.

**Rasterzone** (`SnapZoneButton`) — die einzige echte eigene Komponente: Monitorumriss
40 × 26 mit eingefärbter Zielfläche, darunter Aktionsname (9 pt) und aktuelles Kürzel
(8 pt monospaced), Hover legt `tealPrimary` mit 15 % Deckkraft unter die ganze Zone. Die
Zielflächen sind pro Aktion als `HStack`/`VStack` von Hand nachgebaut — elf Fälle in
einem `switch`, nicht aus `SnapAction.targetFrame` abgeleitet.

**Einstellungsblock** — `GroupBox` mit `VStack(alignment: .leading, spacing: 12)` und
`Divider()` zwischen den Zeilen, `.padding(4)` innen. Fünfmal in den drei Bereichen.

## 6 · Bewegung

Faktisch keine. Zwei Stellen:

- `withAnimation { currentPage = ... }` beim Blättern im Onboarding (Standardkurve)
- `.animation(.easeInOut, value: isGranted)` für den Wechsel Schloss → Häkchen

Der Hover-Effekt der Rasterzonen ist unanimiert. Die Einstellung „Enable snap animations"
wurde in 1.1.1 entfernt, weil sie von keiner Code-Stelle gelesen wurde — Snaps sind
sprunghaft, und das ist beabsichtigt.

## Fehlbestand

Lücken, keine Kriterien.

- **Keine Barrierefreiheit.** Kein einziges `accessibilityLabel`, kein
  `accessibilityHint`, kein Dynamic Type, keine Prüfung auf „Bewegung reduzieren". Elf
  Rasterzonen tragen als einzige Beschriftung 9-pt-Text; für VoiceOver ist die App
  praktisch stumm. Das ist besonders schief bei einem Werkzeug, das selbst auf der
  Accessibility-API aufsetzt und dessen Kernlogik `AXEnhancedUserInterface` gerade wegen
  VoiceOver-Nutzern sorgfältig wiederherstellt.
- **Kein heller Modus.** Onboarding und Über-Fenster erzwingen dunkle Flächen, Popover
  und Einstellungen folgen dem System. Im hellen Systemmodus ist die App zweigeteilt.
  Es gibt weder `.preferredColorScheme(.dark)` (das den Bruch wenigstens konsistent
  machen würde) noch helle Varianten der Markenfarben.
- **Keine Token für Typografie, Abstände und Radien.** Elf Schriftgrößen, zehn
  Abstandsmaße, vier Radien — jeder Wert steht an seiner Verwendungsstelle. Eine
  Änderung der Grundschriftgröße bedeutet 34 einzelne Fundstellen.
- **Statusfarben fehlen im Token-Satz.** Grün, Orange und Rot sind hart im Code, obwohl
  mit `destructive` bereits ein passendes, ungenutztes Token existiert.
- **Drei Token sind tot, zwei Paare wertgleich.** Siehe Tabelle unter *Farben*.
- **Der Primärbutton ist dreimal kopiert** statt einmal als `ButtonStyle` definiert.
- **Fenstermaße stehen doppelt** (NSWindow-`contentRect` und SwiftUI-`frame`). Ändert
  jemand nur eine Stelle, schneidet oder polstert das Fenster den Inhalt.
- **Die Rastervorschau kennt die echte Geometrie nicht.** `SnapZoneButton` baut die
  Zielflächen von Hand nach; `SnapAction.targetFrame` ist die Wahrheit. Die 2/3-Zone
  wird in der Vorschau als `padding(4)` auf 40 × 26 dargestellt — das entspricht rund
  80 % × 69 %, nicht 2/3 × 2/3. Vorschau und Wirkung weichen sichtbar voneinander ab.
