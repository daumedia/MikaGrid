# B05 · Accessibility-Berechtigung — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Ein beobachtbares Objekt hält einen einzigen Wahrheitswert: Ist der Prozess für die
Accessibility-API zugelassen? Es kann diesen Wert neu erfragen, den Systemdialog
auslösen, die Systemeinstellungen öffnen und einen Abfragetakt starten, der den Wert
jede Sekunde erneuert. Vier Oberflächenstellen lesen ihn, eine davon startet den Takt.

Das Objekt kann die Berechtigung **nicht erteilen** — das darf nur das System, und nur
auf Handlung des Nutzers. Alles, was hier gebaut ist, ist Anzeige und Wegweisung.

## Einstiegspunkte

| Ort | Zeigt / tut | Wann |
|---|---|---|
| Popover, Kopfzeile | 8-pt-Punkt grün oder orange | bei jedem Öffnen neu geprüft |
| Popover, Warnbanner | Hinweis + Sprung in die Systemeinstellungen | nur wenn nicht erteilt |
| Einstellungen → Allgemein | Statuszeile mit Symbol und Text, „Open Settings" | bei jedem Anzeigen neu geprüft |
| Onboarding, Schritt 2 | Schloss oder Häkchen, „Open System Settings", „Skip for now" | nur wenn nicht erteilt |
| App-Start | löst ggf. den Systemdialog aus | wenn Onboarding fertig **und** nicht übersprungen |

## Komponentenstruktur

```
AccessibilityManager                    @Observable @MainActor
├── isGranted: Bool                     private(set) — einziger Zustand
├── pollTimer: Timer?
├── checkPermission()                   AXIsProcessTrusted() → isGranted
├── requestPermission()                 löst den Systemdialog aus (Ergebnis verworfen — FB-03)
├── openSystemSettings()                x-apple.systempreferences:… (alter Pfad — FB-02)
├── startPolling()                      1 s Takt → checkPermission()
└── stopPolling()

Leser
├── PopoverGridView
│   ├── Kopfzeile · Circle(grün/orange)
│   ├── Warnbanner (bedingt) → openSystemSettings()
│   └── onAppear → checkPermission()
├── GeneralTabView
│   ├── Statuszeile · Label + Farbe
│   ├── „Open Settings" (bedingt) → openSystemSettings()
│   └── onAppear → checkPermission()
├── PermissionScreen                     der einzige Ort mit laufendem Takt
│   ├── onAppear → startPolling()
│   ├── onDisappear → stopPolling()
│   ├── onReceive(1-s-Publisher) → bei isGranted: nach 1 s weiterblättern
│   └── „Skip for now" → preferences.permissionSkipped = true
├── OnboardingView                       entscheidet 2 oder 3 Schritte
└── WindowManager                        guard AXIsProcessTrusted() — still (FB-01)
```

Bemerkenswert: `PermissionScreen` hat **zwei** Zeitgeber — den Takt im Manager
(aktualisiert `isGranted`) und einen eigenen `Timer.publish` (wertet aus und blättert
weiter). Beide laufen im Sekundentakt nebeneinander.

## Zustand statt Datenmodell

Es gibt keine Tabellen. Drei Wahrheitswerte bestimmen das Verhalten beim Start:

| Wert | Wohnt in | Gesetzt von |
|---|---|---|
| `isGranted` | flüchtig, aus `AXIsProcessTrusted()` | dem System |
| `permissionSkipped` | `UserDefaults` | nur `PermissionScreen` |
| `hasCompletedOnboarding` | `UserDefaults` | B06 |

### Startverhalten — die Wahrheitstabelle

| `hasCompletedOnboarding` | `permissionSkipped` | `isGranted` | Was beim Start passiert |
|---|---|---|---|
| false | beliebig | beliebig | Onboarding erscheint (B06) |
| true | true | beliebig | **nichts** — kein Dialog, dauerhaft |
| true | false | true | nur Prüfung, kein Dialog |
| true | false | false | Prüfung, dann Systemdialog |

Acht Kombinationen, kein Test (FB-06).

## Der Zustand außerhalb der App

Die Zustimmung selbst liegt in der TCC-Datenbank von macOS und ist an die **Signatur**
des Bundles gebunden. Daraus folgt der Zusammenhang mit B09: Weil ad-hoc signiert wird,
ändert sich die Kennung bei jedem Bau, und die Berechtigung muss erneut erteilt werden.
Für Nutzer der ausgelieferten Fassung ist das unerheblich; für die Entwicklung ist es
die Ursache des Karteileichen-Effekts in den Systemeinstellungen.

## Zugriffsregeln

| Wer | Darf | Erzwungen durch |
|---|---|---|
| Mika+Grid mit Zustimmung | Position, Größe und Titel des fokussierten Fensters lesen und Position/Größe setzen | macOS TCC — nicht von der App |
| Mika+Grid ohne Zustimmung | nichts an fremden Fenstern | `guard AXIsProcessTrusted()` **und** die API selbst |
| der Nutzer | Zustimmung jederzeit erteilen und entziehen | Systemeinstellungen |

Die Erzwingung liegt vollständig beim Betriebssystem. Der `guard` im `WindowManager` ist
kein Schutz, sondern eine Abkürzung: Er verhindert vergebliche AX-Aufrufe. Selbst wenn
er fehlte, würde macOS jeden Zugriff verweigern.

## Missbrauchsschutz

| Fläche | Limit | Verhalten |
|---|---|---|
| Anforderung der Berechtigung | vom System begrenzt: der Dialog erscheint je Signatur nur einmal | danach nur noch über die Systemeinstellungen |
| Abfragetakt | 1 s, nur im Onboarding-Schritt | endet mit `onDisappear` |

Eine App kann sich die Berechtigung nicht erschleichen und den Dialog nicht wiederholt
erzwingen — das ist Absicht der Plattform und braucht hier keine eigene Vorkehrung.

## Externe Dienste

Keine. Die Berechtigungsprüfung ist ein lokaler Systemaufruf.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so (soweit rekonstruierbar) |
|---|---|---|---|
| 1 | `AXIsProcessTrusted()` ohne Prompt zum Prüfen | immer mit Prompt prüfen | Prüfen darf keinen Dialog auslösen, sonst erschiene er bei jedem Öffnen des Popovers |
| 2 | Abfragetakt statt Benachrichtigung | auf eine Systemmeldung warten | Für TCC-Änderungen gibt es keine öffentliche Benachrichtigung — Abfragen ist der einzige Weg |
| 3 | Takt nur im Onboarding | dauerhaft | Sparsamkeit. Preis: AK-11 |
| 4 | Überspringen möglich | Zwang zur Erteilung | Die App bleibt ohne Berechtigung teilweise nutzbar; ein Zwang wäre unhöflich |
| 5 | Zustand als `private(set)` | frei schreibbar | Nur das System bestimmt den Wert; Schreibzugriff von außen wäre sinnlos |
| 6 | Zwei Zeitgeber im Berechtigungsschritt | einer | **Grund nicht erkennbar.** Der Takt des Managers pflegt den Wert, der Publisher der Ansicht wertet ihn aus — funktional getrennt, aber einer hätte genügt |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `init()` → `checkPermission()` | |
| AK-02 | `AppDelegate.applicationDidFinishLaunching` | nur bei `!permissionSkipped` |
| AK-03 | dieselbe Bedingung | dauerhaft — FB-05 |
| AK-04 | `PopoverGridView` Kopfzeile + Warnbanner | |
| AK-05 | dieselbe Stelle | |
| AK-06 | Warnbanner → `openSystemSettings()` | Pfad fraglich — FB-02 |
| AK-07 | `GeneralTabView` Statuszeile | |
| AK-08 | `startPolling()` + `onReceive`-Publisher | |
| AK-09 | `onDisappear` → `stopPolling()` | |
| AK-10 ⚠ | `guard` in `WindowManager` — **ohne Rückmeldung** | offen als OF-01 |
| AK-11 ⚠ | `onAppear`-Prüfung, **kein** laufender Takt | offen als OF-02 |
| AK-12 | Beschränkung der genutzten AX-Attribute | belegbar über B01 |
| AK-13 | Text in `PermissionScreen` | |

Keine Zeile ohne Zuordnung. Umgekehrt ohne Kriterium: keine — jede öffentliche Methode
des Managers wird von mindestens einer Oberflächenstelle benutzt.
