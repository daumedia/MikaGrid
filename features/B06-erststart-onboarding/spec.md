# B06 · Erststart-Onboarding — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1

> **Rückerfassung.** ⚠ markiert Verhalten, das zur Klärung vorliegt.

## Zweck

Beim ersten Start führt ein Fenster in zwei oder drei Schritten durch das, was die App
zum Arbeiten braucht: eine Begrüßung, die Accessibility-Berechtigung und eine Übersicht
der Kürzel mit der Frage nach dem Start bei der Anmeldung. Ohne das stünde ein Symbol in
der Menüleiste, das ohne Erklärung nichts tut.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B05 | rekonstruiert | Schritt 2 ist die Berechtigungsführung; die Schrittzahl hängt am Zustand |

## User Stories

- **US-01** · Als neuer Nutzer möchte ich beim ersten Start erfahren, was die App braucht,
  damit ich nicht selbst herausfinden muss, warum nichts passiert.
- **US-02** · Als neuer Nutzer möchte ich die Kürzel einmal gesehen haben, damit ich sie
  ausprobieren kann.
- **US-03** · Als Nutzer möchte ich die Einführung später erneut ansehen können.

## Nicht im Scope

- **Die Berechtigungslogik selbst** — B05.
- **Kürzel ändern** — im Onboarding nicht möglich, das ist B07.
- **Eine Tour durch die Oberfläche** oder Beispielfenster.

## Akzeptanzkriterien

- **AK-01** · Angenommen, die App wird zum ersten Mal gestartet, dann erscheint ein
  480 × 560 pt großes Fenster mit dunklem Verlauf und ohne sichtbaren Fenstertitel.
- **AK-02** · Angenommen, die Berechtigung fehlt, wenn das Onboarding erscheint, dann hat
  es **drei** Schritte und drei Punkte in der Fortschrittsanzeige.
- **AK-03** · Angenommen, die Berechtigung liegt bereits vor, dann hat es **zwei**
  Schritte — der Berechtigungsschritt entfällt.
- **AK-04** · Angenommen, Schritt 1 ist sichtbar, wenn „Get Started" gedrückt wird, dann
  erscheint der nächste Schritt mit einer Überblendung.
- **AK-05** · Angenommen, Schritt 2 ist sichtbar, wenn „Open System Settings" gedrückt
  wird, dann öffnen sich die Systemeinstellungen.
- **AK-06** · Angenommen, Schritt 2 ist sichtbar, wenn der Nutzer die Berechtigung
  außerhalb erteilt, dann wechselt das Symbol auf ein grünes Häkchen und nach etwa einer
  Sekunde erscheint der nächste Schritt — ohne Klick.
- **AK-07** · Angenommen, Schritt 2 ist sichtbar, wenn „Skip for now" gedrückt wird, dann
  geht es weiter und die Berechtigung wird beim Start **nie wieder** erfragt.
- **AK-08** · Angenommen, der letzte Schritt ist sichtbar, dann listet er alle elf
  Aktionen mit ihren Kürzeln und zeigt einen Schalter für den Start bei der Anmeldung.
- **AK-09** · Angenommen, der letzte Schritt ist sichtbar, wenn „Done" gedrückt wird,
  dann wird der Schalterzustand angewendet, das Fenster schließt und das Onboarding
  erscheint künftig nicht mehr.
- **AK-10** · Angenommen, das Onboarding wurde durchlaufen, wenn in den Einstellungen
  unter „About" auf „Show Onboarding Again" geklickt wird, dann erscheint es erneut.
- **AK-11** ⚠ · Angenommen, das Onboarding steht auf Schritt 1, wenn der Nutzer Esc
  drückt oder das Fenster schließt, dann gilt es als **abgeschlossen** und erscheint bei
  keinem weiteren Start.
  *(So verhält sich der Code heute: Das Kennzeichen wird beim Schließen des Fensters
  gesetzt, gleich aus welchem Grund. Der Nutzer hat dann weder die Berechtigung erteilt
  noch die Kürzel gesehen. Siehe OF-01.)*
- **AK-12** ⚠ · Angenommen, ein Nutzer hat seine Kürzel geändert, wenn er das Onboarding
  erneut aufruft, dann zeigt der letzte Schritt trotzdem die **Standardbelegung**.
  *(Die Liste ist fest im Quelltext hinterlegt und liest die tatsächliche Belegung nicht.
  Siehe OF-02.)*
- **AK-13** ⚠ · Angenommen, der Schalter für den Start bei der Anmeldung steht sichtbar
  auf „an", wenn der Nutzer das Fenster über die Fenstertaste schließt statt über „Done",
  dann wird der Start bei der Anmeldung **nicht** eingerichtet.
  *(Der Schalter steht anfangs unabhängig vom tatsächlichen Systemzustand auf „an", und
  angewendet wird er ausschließlich beim Druck auf „Done". Siehe OF-03.)*

### Datenschutz und Missbrauchsschutz

- **AK-14** · Angenommen, der Berechtigungsschritt ist sichtbar, dann nennt er den Grund
  für die Berechtigung und stellt fest: „Your data stays on your Mac."
- **AK-15** · Angenommen, das Onboarding läuft, wenn geprüft wird, was es speichert, dann
  sind es zwei Wahrheitswerte in den Einstellungen — sonst nichts.
- **Weitere Punkte des Katalogs:** treffen nicht zu — keine Eingaben, keine Konten,
  keine externen Dienste.

## Edge Cases

- **EC-01** · Berechtigung wird erteilt, während Schritt 1 sichtbar ist → die Schrittzahl
  wurde beim Aufbau festgelegt und bleibt bei drei; Schritt 2 zeigt dann sofort das
  Häkchen und blättert selbsttätig weiter.
- **EC-02** · Der Nutzer bleibt nach erteilter Berechtigung auf Schritt 2 stehen → bei
  jedem Takt wird eine weitere Verzögerungsaufgabe angelegt, ohne die vorherige
  abzubrechen; es wird mehrfach weitergeblättert. Ohne sichtbare Folge, weil das Ziel
  ohnehin der letzte Schritt ist. Siehe FB-03.
- **EC-03** · „Show Onboarding Again" bei bereits erteilter Berechtigung → zwei Schritte.
- **EC-04** · Mehrfaches „Show Onboarding Again" → jedes Mal wird ein neuer Fensterhalter
  angelegt; der vorherige wird freigegeben.
- **EC-05** · Heller Systemmodus → das Fenster bleibt dunkel (erzwungener Verlauf).

## Fehlbestand

- **FB-01 · Abbruch zählt als Abschluss.** `OnboardingWindowController.windowWillClose`.
  **Folge:** AK-11. Der Nutzer, der das Fenster wegklickt, weil er es später ansehen
  will, sieht es nie wieder — und der Wiederaufruf liegt zwei Ebenen tief unter
  Einstellungen → About.
- **FB-02 · Die Kürzelliste ist fest hinterlegt.** `ShortcutsScreen`, ein Feld mit elf
  Paaren aus Zeichenketten. **Folge:** AK-12. Die Liste kann außerdem von der
  Standardbelegung im Aktions-Aufzählungstyp abweichen, ohne dass es auffällt — es sind
  zwei getrennte Wahrheiten für dieselbe Sache.
- **FB-03 · Der Berechtigungsschritt legt Verzögerungsaufgaben mehrfach an.**
  `PermissionScreen`, Auswertung des Takts: bei jedem Tick wird eine neue Aufgabe
  erzeugt, das Feld überschrieben und die vorherige nicht abgebrochen. **Folge:** EC-02.
  Heute folgenlos, bei einer künftigen Änderung der Reihenfolge nicht mehr.
- **FB-04 · Der Anmeldeschalter zeigt nicht den tatsächlichen Zustand.**
  `ShortcutsScreen` setzt ihn fest auf „an", ohne das System zu fragen. Das
  Einstellungsfenster macht es richtig. **Folge:** AK-13 — die Anzeige behauptet etwas,
  das erst durch „Done" wahr wird.
- **FB-05 · Zwei Zeitgeber für dieselbe Aufgabe.** Der Berechtigungsverwalter hält einen
  Takt, die Ansicht einen zweiten. Beide laufen im Sekundentakt. **Folge:** Doppelte
  Arbeit, keine falsche Wirkung.
- **FB-06 · Kein Weg zurück.** Es gibt keine Schaltfläche „Zurück"; die Punkte der
  Fortschrittsanzeige sind nicht anklickbar.
- **FB-07 · Darstellung der Schrittleiste unklar.** Die Schritte liegen in einer
  Blätteransicht mit Standardstil, versehen mit Kennungen, aber ohne eigene
  Reiterbeschriftungen; zusätzlich gibt es eine eigene Punktanzeige. **In der QA zu
  prüfen:** ob am oberen Rand eine leere Reiterleiste erscheint.
- **FB-08 · Kein Test.** Die Verzweigung zwei/drei Schritte und die Abschlusslogik sind
  reine Zustandslogik.

## Offene Fragen

- **OF-01** · Soll ein Abbruch als Abschluss gelten (AK-11)? Alternative: das Kennzeichen
  nur bei „Done" setzen und beim nächsten Start erneut zeigen. — *Betreiber.*
- **OF-02** · Soll die Kürzelliste die tatsächliche Belegung anzeigen (AK-12, FB-02)?
  Beseitigt zugleich die zweite Wahrheit. — *Betreiber, empfohlen.*
- **OF-03** · Soll der Anmeldeschalter den Systemzustand lesen (AK-13, FB-04)? —
  *Betreiber.*

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Eigenes Fenster statt Popover | — | Das Popover schließt bei Fokusverlust; für einen Ablauf, der in die Systemeinstellungen führt, unbrauchbar |
| 2 | Schrittzahl abhängig vom Zustand | immer drei Schritte | Wer die Berechtigung schon erteilt hat, soll nicht danach gefragt werden |
| 3 | Selbsttätiges Weiterblättern | Schaltfläche „Weiter" | Der Nutzer ist in diesem Moment in den Systemeinstellungen; nach der Rückkehr soll das Fenster bereits weitergegangen sein |
| 4 | Überspringen möglich | Zwang | Die App bleibt teilweise nutzbar; ein Zwang wäre unhöflich |
| 5 | Erzwungen dunkles Erscheinungsbild | dem System folgen | Markenauftritt. Der Preis ist der Bruch aus `docs/design-system.md` |
| 6 | Esc schließt | nur die Fenstertaste | Übliche Erwartung — mit der Folge aus FB-01 |
