# B06 · Erststart-Onboarding — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Ein Fensterhalter erzeugt beim ersten Start ein randloses Fenster mit dunklem Verlauf und
setzt eine Blätteransicht hinein. Die Zahl der Schritte wird **beim Aufbau** festgelegt:
drei, wenn die Berechtigung fehlt, sonst zwei. Der Berechtigungsschritt beobachtet den
Zustand im Sekundentakt und blättert selbsttätig weiter, sobald der Nutzer zugestimmt hat.

Der Abschluss wird an zwei Stellen vermerkt: beim Druck auf „Done" und — unabhängig davon
— beim Schließen des Fensters. Die zweite Stelle ist der Grund für FB-01.

## Seiten und Routen

Keine Routen. Drei Schritte in einem Fenster:

| Schritt | Zeigt | Weiter durch |
|---|---|---|
| 1 · Willkommen | Symbol, „Welcome to Mika+Grid", „Snap. Organize. Focus." | „Get Started" |
| 2 · Berechtigung (bedingt) | Schloss oder Häkchen, Begründung, „Open System Settings", „Skip for now" | selbsttätig nach Zustimmung, oder Überspringen |
| 3 · Kürzel | Liste aller elf, Anmeldeschalter | „Done" |

## Komponentenstruktur

```
AppDelegate
└── OnboardingWindowController              bei jedem Aufruf neu erzeugt
    ├── NSWindow 480×560                    titellos, randlos, per Hintergrund verschiebbar
    ├── windowWillClose → hasCompletedOnboarding = true    ← auch bei Abbruch (FB-01)
    └── OnboardingView
        ├── needsPermission                 einmal beim Aufbau ausgewertet
        ├── pageCount                       3 oder 2
        ├── TabView(selection: currentPage)
        │   ├── WelcomeScreen        .tag(0)
        │   ├── PermissionScreen     .tag(1)   nur wenn nötig
        │   └── ShortcutsScreen      .tag(1 oder 2)
        ├── Punktanzeige                    eigene Darstellung, nicht anklickbar
        └── onKeyPress(.escape) → schließen

PermissionScreen
├── startPolling / stopPolling              Takt im Verwalter (B05)
├── Timer.publish(every: 1)                 ZWEITER Takt in der Ansicht (FB-05)
├── autoAdvanceTask                         wird bei jedem Tick NEU angelegt (FB-03)
└── „Skip for now" → permissionSkipped = true

ShortcutsScreen
├── shortcuts: [(keys, label)]              ELF FESTE PAARE — nicht die echte Belegung (FB-02)
├── launchAtLogin = true                    fest, ohne das System zu fragen (FB-04)
└── „Done" → Schalter anwenden, Abschluss vermerken, schließen
```

## Datenmodell

Zwei Wahrheitswerte in den Einstellungen, beide beschrieben in `docs/datenmodell.md`:

| Wert | Wird gesetzt | Wirkung |
|---|---|---|
| `hasCompletedOnboarding` | „Done" **und** jedes Schließen des Fensters | unterdrückt das Onboarding beim Start |
| `permissionSkipped` | „Skip for now" | unterdrückt den Berechtigungsdialog beim Start, dauerhaft |

Ein dritter Zustand lebt nur im Fenster: die aktuelle Schrittnummer.

## Zugriffsregeln

Nicht anwendbar — keine Konten, keine Rollen, keine fremden Datensätze. Der einzige
Zugriff nach außen ist das Öffnen der Systemeinstellungen, ausgelöst durch den Nutzer.

## Missbrauchsschutz

| Fläche | Grenze |
|---|---|
| Häufigkeit des Onboardings | einmalig, danach nur auf ausdrücklichen Wunsch |
| Berechtigungsdialog | vom System begrenzt (siehe B05) |
| Abfragetakt | endet mit dem Verschwinden der Ansicht |

## Externe Dienste

Keine.

## Erkennbare Entscheidungen

Die sechs tragenden stehen im Decision Log der Spezifikation. Ergänzend:

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 7 | Schrittzahl beim Aufbau festgelegt | fortlaufend auswerten | Einfacher — mit der Folge aus EC-01 |
| 8 | Eigene Punktanzeige | die der Blätteransicht nutzen | Erlaubt die Markenfarbe für den aktiven Punkt |
| 9 | Fensterhalter bei jedem Aufruf neu | einmal anlegen und behalten | Der Zustand soll bei jedem Aufruf frisch sein — insbesondere die Schrittzahl |
| 10 | Kürzelliste fest hinterlegt | aus dem Aktionstyp erzeugen | **Grund nicht erkennbar.** Die Daten liegen bereit; die Folge steht in FB-02 |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | Fensteraufbau + Verlauf | |
| AK-02 | Auswertung des Berechtigungszustands | |
| AK-03 | dieselbe Auswertung | |
| AK-04 | „Get Started" mit Überblendung | |
| AK-05 | „Open System Settings" → B05 | |
| AK-06 | Takt + selbsttätiges Weiterblättern | mehrfach ausgelöst — FB-03 |
| AK-07 | „Skip for now" | dauerhaft — B05/FB-05 |
| AK-08 | feste Liste + Anmeldeschalter | Liste teils falsch — FB-02 |
| AK-09 | „Done" | |
| AK-10 | Rückruf aus dem Einstellungsfenster (B07) | |
| AK-11 ⚠ | Vermerk beim Schließen des Fensters | offen als OF-01 |
| AK-12 ⚠ | feste Liste statt gelesener Belegung | offen als OF-02 |
| AK-13 ⚠ | fester Anfangswert + Anwendung nur bei „Done" | offen als OF-03 |
| AK-14 | Text im Berechtigungsschritt | |
| AK-15 | nur zwei Wahrheitswerte geschrieben | |

Keine Zeile ohne Zuordnung.
