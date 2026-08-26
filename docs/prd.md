# Mika+Grid — Product Requirements Document

Stand: 2026-08-25 · Stufe Datenschutz: A · Stack-Profil: `swiftui-macos` · Artefaktpfad: `docs/` · Version: 1.2.0

> **Rekonstruktion.** Dieses PRD wurde am 2026-08-25 rückwirkend aus dem Bestand
> geschrieben (`sdd-erfassen` Phase 1), nicht vor dem Bau. Beschrieben ist, was der Code
> tut — Stand v1.2.0, nach der Reparatur der bei der Erfassung gefundenen Lücken. Zielgruppe, Monetarisierung,
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
| Architektur | Universal Binary (arm64 + x86_64) über `build.sh --universal` |
| Bundle-ID | `lu.daumedia.mikagrid` |
| Backend | **keins** — kein Server, keine Datenbank, kein Konto |
| Datenhaltung | ausschließlich lokal: `UserDefaults` (`hasCompletedOnboarding`, `permissionSkipped`, `hotkeyBindings`) und flüchtiger Speicher |
| Umgebungen | keine Trennung nötig — es gibt nur den lokalen Rechner und die Auslieferung. Prüfläufe über GitHub Actions bei jedem Push |
| Datenregion | entfällt für die App. Website auf Vercel, Downloads und Update-Feed bei GitHub (USA) |
| Sprachen | Oberfläche, README und Website ausschließlich Englisch |
| Monetarisierung | **keine.** Kostenlos und quelloffen; das Produkt ist Referenz und Werbeträger für daumedia.lu — Einnahmen entstehen über Auftragsarbeit |
| Sandbox | **je Fassung verschieden** (seit Feature 01). **Direktvertrieb:** aus (`app-sandbox = false`) — die Accessibility-API funktioniert in der Sandbox nicht. **App Store:** an; diese Fassung bewegt Fenster nicht selbst, sondern über Apples Kurzbefehle. Die frühere Aussage „der Mac App Store ist ausgeschlossen" galt dem **Bauweg**, nicht dem Produkt |
| Mindestsystem | macOS 14 (Direktvertrieb) · macOS 15 (App Store — die Fensteraktionen von Kurzbefehle setzen es voraus) |
| Library Validation | **an.** Die Entitlement wurde in 1.2.0 entfernt: Sie war ein Symptom der Ad-hoc-Signatur und ist mit Developer-ID-Signatur entbehrlich (nachgewiesen). Ad-hoc-Bauten bekommen sie automatisch |
| Externe Dienste | GitHub (Update-Feed `raw.githubusercontent.com/daumedia/MikaGrid/master/appcast.xml` und DMG-Download aus Releases) · Vercel (Hosting der Landingpage) |
| Vertrieb | GitHub Releases als signiertes DMG, Sparkle-Selbstaktualisierung, Landingpage `mikagrid.vercel.app` (noch nicht veröffentlicht) |
| Lizenz | MIT — `LICENSE` liegt im Repository, README, Website und strukturierte Daten verweisen darauf |

## Datenschutz — Kurzfassung

**Stufe A**, weil Mika+Grid ein Werkzeug ohne Konten ist: Es gibt keine Registrierung,
keine Nutzerkennung, keinen Server und keine Datenbank. Gespeichert werden ausschließlich
drei technische Einstellungen in den lokalen `UserDefaults`. Nichts davon ist
personenbezogen, nichts verlässt das Gerät.

Zwei Punkte, die die Stufe **nicht** anheben, aber benannt gehören, weil sie beim
flüchtigen Lesen des Codes untergehen:

- **Fenstertitel werden in keiner Fassung weitergegeben.** Für die App-Store-Fassung war
  ursprünglich vorgesehen, den Titel an Apples Kurzbefehle zu übergeben, falls die
  Zielanwendung mehrere Fenster hat (AK-23). Das ist entfallen: Der Kurzbefehl arbeitet
  ohne Filter auf das vorderste Fenster, weshalb die Nutzlast nur fünf Zahlen und einen
  Zufallswert trägt. Es gibt damit **keine** Fassung, die etwas Personenbeziehbares
  weitergibt.
- **Fenstertitel werden seit 1.2.0 gar nicht mehr gelesen.** Bis dahin bildete der Titel
  zusammen mit der Prozesskennung den Schlüssel der Wiederherstellungs-Historie und lag
  damit im Arbeitsspeicher — ein Dokumentname oder eine besuchte Website hat sehr wohl
  Personenbezug. Der Schlüssel ist jetzt die Fensterreferenz des Systems, eine Angabe ohne
  jeden Aussagewert. Damit ist die einzige Stelle der App mit möglichem Personenbezug
  entfallen.
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

Ausführlich in `docs/datenschutz.md`; die öffentliche Fassung steht unter `/privacy` auf
der Landingpage.

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

Die sechs Punkte, die bei der Erfassung notiert wurden, sind bis auf zwei geschlossen.

| Punkt | Stand |
|---|---|
| `LICENSE` fehlte | ✅ ergänzt (MIT, 2026) |
| `docs/datenschutz.md` fehlte | ✅ ergänzt, dazu `/privacy` und `/legal` auf der Website |
| Kein einziger Test | ✅ 45 Tests in `Tests/MikaGridTests/`, dazu CI bei jedem Push |
| Zwei Release-Zweige parallel | ✅ entschieden: Der Feed bleibt auf `master`, weil eine Umstellung bestehende Installationen genau einmal gefährden würde. `scripts/release.sh` zieht `master` bei jedem Release mit und weist darauf hin |
| Ad-hoc signiert, nicht notarisiert | ⚠ **teilweise:** Signiert wird jetzt mit Developer ID. Die Notarisierung ist in `release.sh` vorbereitet und läuft, sobald `NOTARY_PROFILE` gesetzt ist — die App-Store-Connect-Zugangsdaten gehören nicht ins Repository |
| „Nächster Bildschirm" und „eigene Raster" ausdrücklich offen | unverändert offen — beides ist kein Mangel, sondern ein mögliches künftiges Feature mit eigener Nummer |

### Was offen bleibt

- **Notarisierung** (2026-08-25). Ein Developer-ID-Zertifikat ist vorhanden, die
  Mitgliedschaft besteht also. Es fehlt einmalig:
  `xcrun notarytool store-credentials MikaGrid --apple-id <id> --team-id CWJM4J4HFN
  --password <app-spezifisch>`. Danach erledigt `scripts/release.sh` alles Weitere.
- **Landingpage veröffentlichen** (2026-08-25). Der Bau ist geprüft, Impressum und
  Datenschutzerklärung liegen vor, der Lizenzlink stimmt. Es fehlt die Verbindung des
  Vercel-Projekts mit Root Directory `web`.

Beide verlangen Zugangsdaten außerhalb des Repositories und sind deshalb nicht aus dem
Quelltext heraus lösbar.

### Gestalterisch offen, bewusst nicht in dieser Reparatur

Heller Modus, Dynamic Type und Gestaltungs-Token (siehe `docs/design-system.md`). Das ist
eine Aufgabe mit eigenem Umfang und eigenen Entscheidungen und gehört in ein neues Feature
mit eigener Spec — nicht in eine Reparatur, die sonst das Erscheinungsbild ohne Anforderung
veränderte.
