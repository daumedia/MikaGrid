# Features

Stand: 2026-08-25 · Stack-Profil: `swiftui-macos` · Artefaktpfad: `docs/`

Alle Einträge tragen das Präfix **`B`**: gebaut, bevor die Kette da war, rückwirkend
erfasst. An der ID ist damit ohne Nachschlagen erkennbar, dass die zugehörige `spec.md`
eine **Rekonstruktion** ist und selbst falsch sein kann — anders als bei einer Spec, die
vor dem Code entstand und die Vorgabe war.

| ID | Feature | Prio | Status | Abhängig von | Zuletzt |
|---|---|---|---|---|---|
| B01 | Fenster snappen | P0 | bestand | B05 | — |
| B02 | Position wiederherstellen | P0 | bestand | B01 | — |
| B03 | Globale Tastenkürzel | P0 | bestand | B01 | — |
| B04 | Menüleisten-Popover | P0 | bestand | B01 | — |
| B05 | Accessibility-Berechtigung | P0 | bestand | — | — |
| B06 | Erststart-Onboarding | P1 | bestand | B05 | — |
| B07 | Einstellungsfenster | P1 | bestand | B03, B05 | — |
| B08 | Automatische Updates | P0 | bestand | — | — |
| B09 | Build-, Signatur- und DMG-Kette | P0 | bestand | B08 | — |
| B10 | Landingpage | P2 | bestand | B09 | — |

## Was jedes Feature umfasst

| ID | Umfang | Quellen |
|---|---|---|
| B01 | Elf Snap-Aktionen, Zielgeometrie je Bildschirm, Bildschirmwahl über den Fenstermittelpunkt, Schreibfolge Größe→Position→Größe mit Rückmessung, Umgang mit `AXEnhancedUserInterface` und AX-Zeitgrenzen | `WindowManager.swift`, `SnapAction.swift` |
| B02 | Sichern des Rahmens vor jedem Snap, Wiederherstellen mit ⌃⌥⌫, Schlüssel aus PID und Fenstertitel | `SnapHistory.swift`, `WindowManager.snapFrontmostWindow` (restore-Zweig) |
| B03 | Carbon-Registrierung der elf Kürzel, einmalige Handler-Installation, freie Belegung über Recorder, Konfliktprüfung innerhalb der App, Speicherung als JSON, Zurücksetzen auf Standard | `HotkeyManager.swift`, `Preferences/ShortcutsTabView.swift` |
| B04 | `MenuBarExtra` ohne Dock-Symbol, Raster mit Monitorvorschau je Zone, Berechtigungsampel und Warnbanner, Fußzeile mit drei Aktionen | `MikaGridApp.swift`, `PopoverGridView.swift`, `SnapZoneButton.swift` |
| B05 | Prüfen und Anfordern der Zustimmung, Abfrage im Sekundentakt, Deep Link in die Systemeinstellungen, Statusanzeige an drei Stellen, Verhalten bei fehlender Berechtigung | `AccessibilityManager.swift`, `Onboarding/PermissionScreen.swift` |
| B06 | Zwei- oder dreistufiger Ablauf je nach Berechtigungslage, selbsttätiges Weiterschalten, Kürzelübersicht, Autostart-Schalter, Abschlusslogik | `Onboarding/` (5 Dateien) |
| B07 | Drei Bereiche in `NavigationSplitView`, Start bei der Anmeldung über `SMAppService`, Update-Schalter, Zurücksetzen aller Einstellungen, Über-Bereich und das (unerreichbare) Über-Fenster | `Preferences/` (6 Dateien), `AboutWindow.swift`, `LaunchAtLoginManager.swift` |
| B08 | Sparkle-Einbindung, EdDSA-signierter Feed auf GitHub, manuelle und automatische Prüfung, `SUFeedURL`/`SUPublicEDKey`, Pflege von `appcast.xml` je Release | `SparkleUpdater.swift`, `appcast.xml`, `Resources/Info.plist` |
| B09 | `swift build -c release` → Bundle-Aufbau → Einbetten und Signieren der Sparkle.framework von innen nach außen → Signatur mit Hardened Runtime → DMG in zwei Varianten → gebrandeter DMG-Hintergrund | `scripts/build.sh`, `scripts/create-dmg*.sh`, `scripts/GenerateDMGBackground.swift`, `Resources/MikaGrid.entitlements` |
| B10 | Next.js 15 auf Vercel, spiegelt Version, Download-Link, DMG-Größe und Aktionsliste aus dem Bestand; öffentliche Aussagen zu Lizenz, Datenschutz und Signaturlage | `web/` |

## Reihenfolge der Rückerfassung

**Nach Risiko, nicht nach Nummer:**

> **B08 → B09 → B05 → B01 → B02 → B03 → B10 → B04 → B06 → B07**

Die Rückerfassung ist die Eintrittskarte für `sdd-qa`, und die QA ist an einem
Bestandsprojekt ein Sicherheitsaudit. Wer mit der Darstellung anfängt, auditiert zuletzt,
was zuerst brennen kann.

| Rang | Feature | Warum hier |
|---|---|---|
| 1 | **B08** Automatische Updates | Lädt ausführbaren Code aus dem Netz und installiert ihn — auf dem geprüften System laut `SUAutomaticallyUpdate = 1` sogar unbeaufsichtigt. Die EdDSA-Signaturprüfung ist die einzige Schranke davor. Fällt sie, ist jede weitere Absicherung der App gegenstandslos |
| 2 | **B09** Build- und Signaturkette | Die Kette, der B08 vertraut. Ad-hoc signiert, nicht notarisiert, `disable-library-validation` aktiv. Hier entsteht das Artefakt, dessen Echtheit B08 prüft |
| 3 | **B05** Accessibility-Berechtigung | Der Torwächter für jeden Zugriff auf fremde Prozesse. Ohne ihn tut die App nichts; mit ihm darf sie sehr viel |
| 4 | **B01** Fenster snappen | Schreibt in fremde Prozesse und liest deren Fenstertitel. Die risikoreichste Stelle der eigentlichen Anwendungslogik |
| 5 | **B02** Wiederherstellen | Hält Fenstertitel im Arbeitsspeicher — der einzige Ort mit möglichem Personenbezug (siehe `docs/datenmodell.md`) |
| 6 | **B03** Globale Tastenkürzel | Installiert während der Aufnahme einen Monitor für Tastaturereignisse und registriert systemweite Kürzel |
| 7 | **B10** Landingpage | Macht öffentliche Zusagen zu Lizenz, Datenschutz und Signaturlage. Eine Abweichung vom Bestand ist bereits belegt: `LICENSE` fehlt |
| 8 | **B04** Popover | Darstellung. Ein bekannter Fund: Die Vorschau bildet die tatsächliche Zielgeometrie nicht korrekt ab |
| 9 | **B06** Onboarding | Darstellung und Ablauf, kein Fremdzugriff |
| 10 | **B07** Einstellungsfenster | Darstellung und lokale Einstellungen. Enthält den Fund „Über-Fenster unerreichbar" |

## Ablauf je Feature

```
/sdd-erfassen B08     →  spec.md + design.md rückwärts, Status: rekonstruiert
/sdd-qa B08           →  Testbericht; entscheidet, wie es weitergeht
```

Was nach der QA passiert, entscheidet der höchste Schweregrad im Bericht — nicht dieser
Skill:

| Ergebnis | Nächster Schritt | Status |
|---|---|---|
| kein Befund | kein Deployment, der Code ist live | `deployed`, mit Auditvermerk |
| kritisch oder hoch | Erfassung pausiert: `sdd-build` → `sdd-qa` → `sdd-deploy` | `review` → … → `deployed` |
| nur mittel oder niedrig | Eintrag in `features/befunde.md`, weiter mit dem nächsten Feature | bleibt `review` |

## Bereits bekannte Lücken

Diese Punkte sind in Phase 1 beim Lesen aufgefallen und stehen ausführlich in den
`Fehlbestand`-Abschnitten von `docs/datenmodell.md`, `docs/design-system.md` und
`docs/app-shell.md` sowie unter *Offene Punkte* im PRD. Sie sind **keine QA-Befunde** —
`features/befunde.md` wird erst von `sdd-qa` angelegt und ausschließlich von dort
fortgeschrieben.

| Betrifft | Lücke |
|---|---|
| projektweit | `LICENSE` fehlt, obwohl README und Website MIT zusichern |
| projektweit | Kein `Tests/`-Verzeichnis — `swift test` hat nichts auszuführen |
| projektweit | `docs/datenschutz.md` fehlt |
| B03 / Daten | Keine Schemaversion; eine neu hinzugefügte Aktion bekommt bei Bestandsnutzern kein Kürzel |
| B02 | Historien-Schlüssel bricht bei Titelwechsel; `clearAll()` wird nie aufgerufen; kein Limit |
| B07 | Über-Fenster ist nicht erreichbar (`.showAbout` wird nirgends gepostet) |
| B07 | `SUAutomaticallyUpdate` ist aktiv, aber in der Oberfläche nicht abschaltbar |
| B04 | Vorschau der 2/3-Zone zeigt ~80 % × 69 % statt 67 % × 67 % |
| B08 | `SUFeedURL` zeigt auf `master`, entwickelt wird auf `main` (derzeit deckungsgleich) |
| B09 | Ad-hoc signiert, nicht notarisiert, `disable-library-validation` aktiv |
| projektweit | Keine Barrierefreiheit; kein heller Modus in Onboarding und Über-Fenster |
