# Features

Stand: 2026-08-25 · Stack-Profil: `swiftui-macos` · Artefaktpfad: `docs/` · App-Version: 1.2.0

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
| B02 | Sichern des Rahmens vor dem **ersten** Snap, Wiederherstellen mit ⌃⌥⌫, Schlüssel ist die Fensterreferenz (`CFEqual`), Historie auf 100 Einträge begrenzt | `SnapHistory.swift`, `WindowManager.snapFrontmostWindow` (restore-Zweig) |
| B03 | Carbon-Registrierung der elf Kürzel, einmalige Handler-Installation, freie Belegung über Recorder, Konflikt- und Sperrlistenprüfung, sichtbare Fehlschläge, Speicherung mit Schemaversion und Auffüllen fehlender Belegungen | `HotkeyManager.swift`, `Preferences/ShortcutsTabView.swift` |
| B04 | `MenuBarExtra` ohne Dock-Symbol, Raster mit aus der Zielgeometrie abgeleiteter Vorschau, Berechtigungsanzeige mit Symbol und Farbe, Rückmeldung fehlgeschlagener Snaps, Fußzeile mit vier Aktionen | `MikaGridApp.swift`, `PopoverGridView.swift`, `SnapZoneButton.swift` |
| B05 | Prüfen und Anfordern der Zustimmung, Abfrage im Sekundentakt, Deep Link in die Systemeinstellungen, Statusanzeige an drei Stellen, Verhalten bei fehlender Berechtigung | `AccessibilityManager.swift`, `Onboarding/PermissionScreen.swift` |
| B06 | Zwei- oder dreistufiger Ablauf je nach Berechtigungslage, selbsttätiges Weiterschalten, Kürzelübersicht, Autostart-Schalter, Abschlusslogik | `Onboarding/` (5 Dateien) |
| B07 | Drei Bereiche in `NavigationSplitView`, Start bei der Anmeldung über `SMAppService`, Update-Schalter, Zurücksetzen aller Einstellungen, Über-Bereich und das (unerreichbare) Über-Fenster | `Preferences/` (6 Dateien), `AboutWindow.swift`, `LaunchAtLoginManager.swift` |
| B08 | Sparkle-Einbindung, EdDSA-signierter Feed auf GitHub, manuelle und automatische Prüfung, `SUFeedURL`/`SUPublicEDKey`, Pflege von `appcast.xml` je Release | `SparkleUpdater.swift`, `appcast.xml`, `Resources/Info.plist` |
| B09 | `swift build -c release` (optional universal) → Bundle → Sparkle einbetten und von innen nach außen signieren → Developer-ID-Signatur mit Hardened Runtime → DMG signiert → Release mit Konsistenzprüfung und appcast-Signatur | `scripts/build.sh`, `scripts/release.sh`, `scripts/create-dmg*.sh`, `Resources/MikaGrid.entitlements` |
| B10 | Next.js 15, drei Routen (Start, `/privacy`, `/legal`), spiegelt Version, Download-Link, DMG-Größe und Aktionsliste aus dem Bestand — maschinell abgeglichen über `check-web-sync.mjs` | `web/`, `scripts/check-web-sync.mjs` |

## Stand

Phase 1 (Kartierung) und Phase 2 (Rückerfassung) sind abgeschlossen. Anschließend wurde der
Bestand **repariert**: Alle Lücken, die die Erfassung zutage gefördert hat, sind in
**v1.2.0** geschlossen — bis auf zwei, die Zugangsdaten außerhalb des Repositories
verlangen.

| | erfasst | nach der Reparatur |
|---|---|---|
| Akzeptanzkriterien | 148 | 148 |
| davon ⚠ markiert | 26 | **2** |
| Fehlbestand-Einträge | 73 | **2 offen**, 71 behoben |
| Offene Fragen | 30 | **2 offen**, 28 entschieden |
| Tests | 0 | **45** |

Die verbliebenen ⚠ markieren jetzt etwas anderes als vorher: nicht mehr „fragwürdiges
Verhalten, das zu klären ist", sondern **Punkte, die aus dem Repository heraus nicht
lösbar sind**.

### Was offen bleibt

| Punkt | Warum offen | Was fehlt |
|---|---|---|
| **Notarisierung** (B09/FB-01, B08/FB-08) | Zugangsdaten für App Store Connect gehören nicht ins Repository | Einmalig `xcrun notarytool store-credentials MikaGrid --apple-id <id> --team-id CWJM4J4HFN --password <app-spezifisch>`, danach erledigt `scripts/release.sh` den Rest |
| **Landingpage veröffentlichen** (B10/FB-02) | Zugriff auf das Vercel-Konto nötig | Das Projekt `daumedia/mikaplus-grid` ist bereits verbunden und baut Vorschauen je Pull Request — es fehlt ein Produktivstand unter einer erreichbaren Adresse. Weicht sie von `APP.siteUrl` ab, ist `web/lib/app.ts` nachzuziehen |

Ein Developer-ID-Zertifikat ist vorhanden (`Michael Rodrigues, CWJM4J4HFN`), die
Mitgliedschaft besteht also — bei der Notarisierung fehlt wirklich nur der einmalige
Anmeldeschritt.

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

## Was in v1.2.0 geschlossen wurde

Die vollständige Liste steht je Feature unter *Behobener Fehlbestand*. Die Funde mit der
größten Tragweite:

| Betraf | Was falsch war | Jetzt |
|---|---|---|
| B09 | `codesign --deep` überschrieb die sorgfältige Signierung von innen nach außen und prägte Sparkles XPC-Diensten die App-Entitlements auf | `--deep` entfernt; die Dienste tragen wieder leere Entitlements |
| B09 | `disable-library-validation` schwächte den Hardened Runtime dauerhaft | entfernt und nachgewiesen, dass es mit Developer-ID-Signatur entbehrlich ist; Ad-hoc-Bauten bekommen es automatisch |
| B01/B05 | Sechs Abbruchpfade endeten still — jede Störung sah gleich aus | `SnapResult` mit sechs Fällen, Systemton und Begründung im Popover |
| B02 | Der Historien-Schlüssel enthielt den Fenstertitel: brach bei Titeländerung, kollidierte bei titellosen Fenstern, lag im Speicher | Schlüssel ist die Fensterreferenz (`CFEqual`), Historie auf 100 Einträge begrenzt |
| B03 | Eine künftig ergänzte Aktion hätte bei Bestandsnutzern kein Kürzel bekommen | fehlende Belegungen werden aufgefüllt, dazu eine Schemaversion |
| B04 | Die Vorschau der 2/3-Zone zeigte ~80 % × 69 % | aus `SnapAction.previewRect` abgeleitet — ein Test hält beide Seiten zusammen |
| B07 | „Reset All Settings" führte nicht in den Auslieferungszustand | beide Kennzeichen und acht Sparkle-Schlüssel werden gelöscht |
| B07 | Das Über-Fenster war seit 1.1.0 unerreichbar | zwei Wege dorthin |
| B10 | `LICENSE` fehlte, obwohl an vier Stellen MIT zugesagt wurde | ergänzt, Link folgt dem Standardzweig |
| B10 | Weder Impressum noch Datenschutzerklärung | `/legal` und `/privacy`, dazu `docs/datenschutz.md` |
| projektweit | Kein einziger Test | 45 Tests; einer davon deckte während der Reparatur einen Fehler in der neuen Vorschau-Ableitung auf |
| projektweit | Kein Prüflauf | `.github/workflows/ci.yml`, `scripts/release.sh --check`, `scripts/check-web-sync.mjs` |

## Projektweite Lücken — geschlossen

| Lücke | Stand |
|---|---|
| `LICENSE` fehlte | ✅ ergänzt |
| Kein `Tests/`-Verzeichnis | ✅ 45 Tests |
| `docs/datenschutz.md` fehlte | ✅ ergänzt |
| Keine Barrierefreiheit | ✅ Beschriftungen und Hinweise im Popover, Status nicht mehr nur farbcodiert, „Back" im Onboarding |
| Kein Tastaturweg in die App | ✅ ⌘, und ⌘Q, solange das Popover offen ist |
| Fehlschläge wurden still verschluckt | ✅ an allen sechs Features behoben — Snap, Kürzelregistrierung, Anmeldeobjekt, Update-Prüfung, Sparkle-Einbettung |

Der letzte Eintrag war das deutlichste Muster der Erfassung: An sechs von zehn Features
endete mindestens ein Fehlerpfad ohne Rückmeldung. Genau das ist jetzt durchgehend
aufgelöst — jede Störung sagt, was los ist.

Noch **nicht** geschlossen ist der helle Modus: Onboarding und Über-Fenster erzwingen
weiterhin dunkle Flächen, während Popover und Einstellungen dem System folgen. Das ist
eine gestalterische Entscheidung mit eigenem Umfang und gehört in ein eigenes Feature mit
eigener Spec, nicht in eine Reparatur (siehe `docs/design-system.md`).

