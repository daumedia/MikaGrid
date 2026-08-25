# Features

Stand: 2026-08-25 · Stack-Profil: `swiftui-macos` · Artefaktpfad: `docs/`

Alle Einträge tragen das Präfix **`B`**: gebaut, bevor die Kette da war, rückwirkend
erfasst. An der ID ist damit ohne Nachschlagen erkennbar, dass die zugehörige `spec.md`
eine **Rekonstruktion** ist und selbst falsch sein kann — anders als bei einer Spec, die
vor dem Code entstand und die Vorgabe war.

| ID | Feature | Prio | Status | Abhängig von | Zuletzt |
|---|---|---|---|---|---|
| B01 | Fenster snappen | P0 | rekonstruiert | B05 | 2026-08-25 |
| B02 | Position wiederherstellen | P0 | rekonstruiert | B01 | 2026-08-25 |
| B03 | Globale Tastenkürzel | P0 | rekonstruiert | B01 | 2026-08-25 |
| B04 | Menüleisten-Popover | P0 | rekonstruiert | B01 | 2026-08-25 |
| B05 | Accessibility-Berechtigung | P0 | rekonstruiert | — | 2026-08-25 |
| B06 | Erststart-Onboarding | P1 | rekonstruiert | B05 | 2026-08-25 |
| B07 | Einstellungsfenster | P1 | rekonstruiert | B03, B05 | 2026-08-25 |
| B08 | Automatische Updates | P0 | rekonstruiert | — | 2026-08-25 |
| B09 | Build-, Signatur- und DMG-Kette | P0 | rekonstruiert | B08 | 2026-08-25 |
| B10 | Landingpage | P2 | rekonstruiert | B09 | 2026-08-25 |

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

## Stand der Erfassung

Phase 1 (Kartierung) und Phase 2 (Rückerfassung) sind **abgeschlossen**. Alle zehn
Features tragen `spec.md` und `design.md`, geschrieben aus dem Bestand von v1.1.1.

| | Anzahl |
|---|---|
| Akzeptanzkriterien | 148 |
| davon ⚠ markiert — „das tut der Code, soll er das?" | 26 |
| Fehlbestand-Einträge (Lücken, keine Kriterien) | 73 |
| Offene Fragen an den Betreiber | 30 |
| Dokumente | 20 · 3.076 Zeilen |

Die ⚠-Kriterien sind **absichtlich** als Kriterien formuliert und nicht weggelassen: Die
QA muss das tatsächliche Verhalten reproduzieren können. Wird eines davon als Fehler
eingestuft, wandert es in den *Fehlbestand* des betreffenden Features.

## Reihenfolge der QA

Unverändert nach Risiko, jetzt als Eingangsreihenfolge für `sdd-qa`:

> **B08 → B09 → B05 → B01 → B02 → B03 → B10 → B04 → B06 → B07**

| Rang | Feature | Warum hier |
|---|---|---|
| 1 | **B08** Automatische Updates | Lädt ausführbaren Code aus dem Netz und installiert ihn — laut `SUAutomaticallyUpdate = 1` unbeaufsichtigt. Die EdDSA-Prüfung ist die einzige Schranke |
| 2 | **B09** Build- und Signaturkette | Die Kette, der B08 vertraut. Ad-hoc signiert, nicht notarisiert |
| 3 | **B05** Accessibility-Berechtigung | Torwächter für jeden Zugriff auf fremde Prozesse |
| 4 | **B01** Fenster snappen | Schreibt in fremde Prozesse, liest Fenstertitel |
| 5 | **B02** Wiederherstellen | Hält Fenstertitel im Speicher — der einzige Ort mit möglichem Personenbezug |
| 6 | **B03** Globale Tastenkürzel | Systemweite Kürzel, Tastatur-Beobachter während der Aufnahme |
| 7 | **B10** Landingpage | Öffentliche Zusagen zu Lizenz und Datenschutz; heute nicht ausgeliefert |
| 8 | **B04** Popover | Darstellung |
| 9 | **B06** Onboarding | Ablauf und Darstellung |
| 10 | **B07** Einstellungsfenster | Lokale Einstellungen |

```
/sdd-qa B08     →  Testbericht; der höchste Schweregrad entscheidet, wie es weitergeht
```

| QA-Ergebnis | Nächster Schritt | Status |
|---|---|---|
| kein Befund | kein Deployment — der Code ist live | `deployed`, mit Auditvermerk |
| kritisch oder hoch | Erfassung pausiert: `sdd-build` → `sdd-qa` → `sdd-deploy` | `review` → … → `deployed` |
| nur mittel oder niedrig | Eintrag in `features/befunde.md`, weiter mit dem nächsten | bleibt `review` |

`features/befunde.md` wird von `sdd-qa` angelegt und ausschließlich von dort
fortgeschrieben — nie von Hand.

## Entscheidungen, die vor der QA anstehen

Die 30 offenen Fragen stehen je Feature unter *Offene Fragen*. Sieben davon ändern, was
die QA überhaupt prüfen soll, und gehören deshalb vorgezogen:

| # | Frage | Wirkung |
|---|---|---|
| B10/OF-01 | Soll die Landingpage überhaupt live gehen? | Solange sie es nicht ist, sind das fehlende Impressum und der tote Lizenzlink folgenlos. Sobald sie es ist, sind sie es nicht mehr — **diese Antwort bestimmt die Dringlichkeit von drei weiteren Befunden** |
| — | `LICENSE` ergänzen? | Keine offene Frage, sondern eine Lücke: README, Landingpage und die strukturierten Daten sagen MIT zu, die Datei fehlt. Zwei Minuten Arbeit |
| B09/OF-01 | Auslieferung notarisieren? | Setzt eine Developer-Mitgliedschaft voraus (99 USD/Jahr). Hängt am Zweck „Visitenkarte für Auftragsarbeit" |
| B08/OF-01 | Darf sich die App unbeaufsichtigt aktualisieren? | Sie tut es heute, ohne dass die Oberfläche das anbietet oder zurücknehmen kann |
| B08/OF-02 | Welcher Zweig trägt den Update-Feed? | `main` ist `master` seit dem 2026-08-25 voraus. Beim nächsten Release entscheidet das, ob Updates ankommen |
| B02/OF-01 | Historien-Schlüssel auf die Fensternummer umstellen? | Behebt drei Befunde auf einmal und nimmt den Fenstertitel aus dem Arbeitsspeicher |
| B07/OF-03 | Über-Fenster wieder erreichbar machen — oder streichen? | Beides ist vertretbar; der heutige Zwischenzustand aus 85 Zeilen totem Code ist es nicht |

## Projektweite Lücken

Diese betreffen **kein einzelnes Feature** und stehen deshalb auch in den Dokumenten
unter `docs/`:

| Lücke | Betrifft |
|---|---|
| `LICENSE` fehlt, obwohl an vier Stellen MIT zugesagt wird | Repository, README, B10 |
| Kein `Tests/`-Verzeichnis — `swift test` hat nichts auszuführen | alle zehn Features nennen es im Fehlbestand |
| `docs/datenschutz.md` fehlt | PRD, B10 |
| Keine Barrierefreiheit: kein `accessibilityLabel`, kein Dynamic Type | B04, B06, B07 |
| Kein heller Modus in Onboarding und Über-Fenster | B06, B07 |
| Kein Programmmenü und damit kein Tastaturweg in die App | B04, B07 |
| Fehlschläge werden durchgehend still verschluckt (`print` oder gar nichts) | B01, B03, B05, B07, B08, B09 |

Der letzte Eintrag ist das deutlichste Muster der ganzen Erfassung: An sechs von zehn
Features endet mindestens ein Fehlerpfad ohne jede Rückmeldung an den Nutzer. Einzeln ist
das jeweils vertretbar; zusammen ergibt es eine App, die bei jeder Störung gleich
aussieht — sie tut einfach nichts.
