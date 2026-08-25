# Mika+Grid — Product Requirements Document

Stand: 2026-08-25 · Stufe Datenschutz: A · Stack-Profil: `swiftui-macos` · Artefaktpfad: `docs/`

> **Rekonstruktion.** Dieses PRD wurde am 2026-08-25 rückwirkend aus dem Bestand
> geschrieben (`sdd-erfassen` Phase 1), nicht vor dem Bau. Beschrieben ist, was der Code
> in Version 1.1.1 tut — nicht, was er tun sollte. Zielgruppe, Monetarisierung,
> Nicht-Ziele und Erfolgskriterien stammen aus vier gezielten Fragen an den Betreiber;
> alles Übrige ist gelesen.

## Vision

Mika+Grid ordnet Fenster auf dem Mac mit einem Tastendruck. Wer ⌃⌥← drückt, hat das
aktive Fenster auf der linken Bildschirmhälfte — ohne Maus, ohne Ziehen, ohne dass eine
weitere App im Dock steht. Wer die Kürzel nicht auswendig kann, klickt dieselbe Zone im
Menüleisten-Popover an. Die App ist die native, quelloffene Alternative zu Rectangle im
Mika+-Baukasten: klein genug, um vergessen zu werden, und zuverlässig genug, dass man
sie den ganzen Tag benutzt.

## Zielgruppe

| Gruppe | Situation | Was sie hier will |
|---|---|---|
| Der Betreiber selbst | Arbeitet täglich mit Editor, Terminal und Browser nebeneinander auf einem Apple-Silicon-Mac | Fenster ohne Handgriff an ihren Platz — und ein Werkzeug, das nie im Weg steht |
| Mika+-Ökosystem | Weitere kleine native macOS-Werkzeuge derselben Reihe (MikaScreenSnap u. a.) | Geteilte Bausteine: Farbpalette, Hotkey-Muster, Onboarding, Build-Kette |
| Öffentliche Nutzer | Finden die App über GitHub oder die Landingpage | Kostenloser Rectangle-Ersatz; willkommen, aber nicht die treibende Zielgruppe |

## Im Scope

- Elf Snap-Aktionen: vier Hälften, vier Viertel, Maximieren, Zentrieren auf 2/3, Zurücksetzen
- Globale Tastenkürzel für jede Aktion, frei belegbar, mit Konflikterkennung innerhalb der App
- Visuelles Raster im Menüleisten-Popover mit Monitorvorschau je Zone und angezeigtem Kürzel
- Mehrere Bildschirme: gesnappt wird auf dem Bildschirm, auf dem der Fenstermittelpunkt liegt
- Wiederherstellen der Position vor dem letzten Snap, je Fenster
- Geführte Einrichtung der Accessibility-Berechtigung beim ersten Start
- Einstellungsfenster mit drei Bereichen: Allgemein, Kurzbefehle, Über
- Start bei der Anmeldung über `SMAppService`
- Automatische Updates über Sparkle mit EdDSA-signiertem Feed
- Vertrieb als signiertes DMG über GitHub Releases, dazu eine Landingpage

## Nicht im Scope

- **Einrasten per Maus am Bildschirmrand** (Drag-to-Edge, wie Windows Aero Snap oder
  Rectangle es kann). Bewusst nicht gebaut: es verlangt einen globalen Mausereignis-Monitor
  und damit dauerhaft laufende Ereignisverarbeitung — der Gegenentwurf zu einer App, die
  nur bei Tastendruck etwas tut.
- **Konten, Anmeldung, Synchronisierung.** Es gibt keinen Server und keine Nutzerkennung.
- **Telemetrie und Analytics.** Weder in der App noch auf der Website.

Dieser Abschnitt ist wichtiger als er aussieht: Er ist die Stelle, an der ein Agent
aufhört, Nachbarfunktionen mitzubauen.

## Erfolgskriterien

- **Tägliche Eigennutzung.** Mika+Grid ist auf dem Arbeitsgerät des Betreibers
  installiert, Rectangle ist es nicht, und über drei Monate gibt es keinen Anlass,
  zurückzuwechseln.
- Ein Snap sitzt beim **ersten** Auslösen — kein zweites Drücken, kein Nachjustieren
  (der Regressionsanlass für 1.1.1).
- Die Menüleiste bleibt bedienbar, auch wenn eine Ziel-App nicht antwortet.

## Rahmenbedingungen

| Thema | Entscheidung |
|---|---|
| Stack-Profil | `swiftui-macos` — Details in `~/.claude/sdd/stacks/swiftui-macos.md` |
| Sprache / Toolchain | Swift 6.0 strict concurrency, SwiftUI, Swift Package Manager |
| Mindestsystem | macOS 14.0 (Sonoma), `LSMinimumSystemVersion` |
| Architektur | arm64 (Apple Silicon). Intel-Macs müssen aus dem Quelltext bauen |
| Bundle-ID | `lu.daumedia.mikagrid` |
| Backend | **keins** — kein Server, keine Datenbank, kein Konto |
| Datenhaltung | ausschließlich lokal: `UserDefaults` (`hasCompletedOnboarding`, `permissionSkipped`, `hotkeyBindings`) und flüchtiger Speicher |
| Umgebungen | keine Trennung nötig — es gibt nur den lokalen Rechner und die Auslieferung |
| Datenregion | entfällt für die App. Website auf Vercel, Downloads und Update-Feed bei GitHub (USA) |
| Sprachen | Oberfläche, README und Website ausschließlich Englisch |
| Monetarisierung | **keine.** Kostenlos und quelloffen; das Produkt ist Referenz und Werbeträger für daumedia.lu — Einnahmen entstehen über Auftragsarbeit |
| Sandbox | **aus** (`com.apple.security.app-sandbox = false`). Die Accessibility-API und globale Carbon-Hotkeys funktionieren in der Sandbox nicht. Folge: Der Mac App Store ist ausgeschlossen, der Vertrieb läuft über DMG und Sparkle |
| Library Validation | **aus** (`com.apple.security.cs.disable-library-validation = true`) — nötig, damit die ad-hoc signierte Sparkle.framework geladen wird |
| Externe Dienste | GitHub (Update-Feed `raw.githubusercontent.com/daumedia/MikaGrid/master/appcast.xml` und DMG-Download aus Releases) · Vercel (Hosting der Landingpage) |
| Vertrieb | GitHub Releases als DMG, Sparkle-Selbstaktualisierung, Landingpage `mikagrid.vercel.app` |
| Lizenz | MIT laut README und Website — **die Datei `LICENSE` fehlt im Repository** (siehe Offene Punkte) |

## Datenschutz — Kurzfassung

**Stufe A**, weil Mika+Grid ein Werkzeug ohne Konten ist: Es gibt keine Registrierung,
keine Nutzerkennung, keinen Server und keine Datenbank. Gespeichert werden ausschließlich
drei technische Einstellungen in den lokalen `UserDefaults`. Nichts davon ist
personenbezogen, nichts verlässt das Gerät.

Zwei Punkte, die die Stufe **nicht** anheben, aber benannt gehören, weil sie beim
flüchtigen Lesen des Codes untergehen:

- **Fenstertitel werden gelesen und im Arbeitsspeicher gehalten.** Der Schlüssel der
  Wiederherstellungs-Historie ist `"<PID>_<Fenstertitel>"`. Ein Fenstertitel kann einen
  Dokumentnamen, einen E-Mail-Betreff oder eine besuchte Website enthalten — also sehr
  wohl Personenbezug. Er wird **nie** auf die Festplatte geschrieben, nie protokolliert
  und nie übertragen; die Historie lebt in einem Dictionary und ist beim Beenden weg.
- **Der Update-Check erzeugt eine Verbindung zu GitHub.** Dabei sieht GitHub die
  IP-Adresse des Nutzers und den Zeitpunkt. Sparkles System-Profiling ist **nicht**
  aktiviert (`SUEnableSystemProfiling` fehlt in der `Info.plist`, Sparkle-Standard ist
  aus), es werden also keine Hardware- oder Systemdaten mitgeschickt.

Regeln, die für die ganze App gelten:

- **Kein Netzwerkverkehr außer dem Update-Check.** Jede weitere ausgehende Verbindung
  wäre eine neue Entscheidung und gehört ins PRD, bevor sie gebaut wird.
- **Keine Telemetrie, kein Analytics, kein Crash-Reporting** — weder in der App noch auf
  der Landingpage. Die Website behauptet das öffentlich („0 Trackers or analytics"); die
  Aussage ist am Bestand geprüft und trifft zu.
- **Fenstertitel gehören nicht in Logs.** Weder `print` noch `os_log`, auch nicht beim
  Debuggen.
- **Die Accessibility-Berechtigung wird ausschließlich für Fensterrahmen benutzt** —
  Lesen und Setzen von Position, Größe und Titel des fokussierten Fensters. Kein
  Auslesen von Inhalten, kein Tastaturmitschnitt fremder Apps.

Ein Dokument `docs/datenschutz.md` existiert noch nicht. Bei Stufe A ist es eine halbe
Seite; es fehlt trotzdem (siehe Offene Punkte).

## Feature-Inventar

Alle Einträge stehen auf Status `bestand`: gebaut, ausgeliefert, nie durch die Kette
gelaufen. Das ist ein Inventar, keine Planung — die Spalte *Prio* sagt, wie zentral ein
Teil für das Produkt ist, nicht was als Nächstes gebaut wird.

| ID | Feature | Prio | Kurzbeschreibung | Abhängig von |
|---|---|---|---|---|
| B01 | Fenster snappen | P0 | Elf Aktionen, Zielgeometrie je Bildschirm, Schreiben über die Accessibility-API mit Rückmessung | B05 |
| B02 | Position wiederherstellen | P0 | Merkt sich den Rahmen vor jedem Snap je Fenster und stellt ihn mit ⌃⌥⌫ zurück | B01 |
| B03 | Globale Tastenkürzel | P0 | Carbon-Registrierung aller elf Kürzel, freie Belegung mit Recorder, Konflikterkennung, Speicherung | B01 |
| B04 | Menüleisten-Popover | P0 | `MenuBarExtra` ohne Dock-Symbol, visuelles Raster mit Monitorvorschau, Fußzeile | B01 |
| B05 | Accessibility-Berechtigung | P0 | Prüfen, Anfordern, Statusanzeige, Abfrage im Sekundentakt, Deep Link in die Systemeinstellungen | — |
| B06 | Erststart-Onboarding | P1 | Drei Schritte: Willkommen, Berechtigung, Kürzelübersicht mit Anmelde-Autostart | B05 |
| B07 | Einstellungsfenster | P1 | Drei Bereiche, Start bei Anmeldung, Zurücksetzen aller Einstellungen, Über-Fenster | B03, B05 |
| B08 | Automatische Updates | P0 | Sparkle mit EdDSA-signiertem Feed auf GitHub, manuelle und automatische Prüfung | — |
| B09 | Build-, Signatur- und DMG-Kette | P0 | `swift build` → App-Bundle → eingebettete Sparkle.framework → Signatur → DMG | B08 |
| B10 | Landingpage | P2 | Next.js 15 auf Vercel, spiegelt Version, Download-Link und Aktionsliste aus dem Bestand | B09 |

**Der Zuschnitt ist ein Vorschlag** und wird vor dem Eintrag in `features/index.md`
einzeln bestätigt — kein Agent kennt die Absicht hinter dem Code.

## Offene Punkte

- **`LICENSE` fehlt** (2026-08-25). README verlinkt `[MIT](LICENSE)`, die Landingpage
  sagt „MIT-licensed — the full source is on GitHub". Die Datei existiert im Repository
  nicht. Ohne sie ist der Quelltext rechtlich *nicht* MIT-lizenziert, sondern ohne
  Nutzungsrechte — eine Zusage, die der Bestand nicht hält.
- **`docs/datenschutz.md` fehlt** (2026-08-25). Bei Stufe A eine halbe Seite, aber die
  Landingpage macht öffentliche Datenschutzaussagen, die nirgends verbindlich hinterlegt
  sind.
- **Kein einziger Test im Projekt** (2026-08-25). Es gibt kein `Tests/`-Verzeichnis;
  `swift test` hat nichts auszuführen. Die Geometrieberechnung in `SnapAction.targetFrame`
  ist reine, testbare Rechnung ohne Systemabhängigkeit — dass sie ungetestet ist, hat
  1.1.1 mit verursacht.
- **Zwei Release-Zweige parallel** (2026-08-25). `SUFeedURL` zeigt auf `master`,
  entwickelt wird auf `main`. Beide sind aktuell deckungsgleich (0 Commits Abstand). Läuft
  einer davon vor, erreicht kein Update mehr einen bestehenden Nutzer — die App sucht an
  genau einer Stelle und nirgends sonst.
- **Auslieferung ist ad-hoc signiert und nicht notarisiert** (2026-08-25). Die FAQ der
  Landingpage sagt das offen und erklärt den Rechtsklick-Umweg. Für ein öffentlich
  verteiltes Produkt ist es trotzdem der Punkt mit der größten Hebelwirkung — Details
  gehören in die Rückerfassung von B09.
- **Ausdrücklich offen gelassen** (2026-08-25): „Fenster auf den nächsten Bildschirm
  verschieben" und „eigene Raster / Drittel" wurden **nicht** als Nicht-Ziele erklärt.
  Sie sind heute nicht gebaut, aber auch nicht ausgeschlossen. Wer sie baut, legt ein
  neues Feature mit eigener Nummer an, das unter *Abhängigkeiten* auf B01 verweist.
