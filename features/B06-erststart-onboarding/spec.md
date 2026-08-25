# B06 · Erststart-Onboarding — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1 · Repariert in: v1.2.0

> **Rückerfassung, danach repariert.** Erfasst aus v1.1.1, überarbeitet in **v1.2.0**
> (2026-08-25). Die Kriterien beschreiben den Stand **nach** der Reparatur; was vorher
> anders war, steht in Klammern dabei. ⚠ markiert die Punkte, die **nicht** aus dem
> Repository heraus lösbar sind. *Behobener Fehlbestand* führt jede geschlossene Lücke mit
> ihrer Fundstelle — eine Rekonstruktion, die verschweigt, was falsch war, ist wertlos.

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
- **AK-11** · Angenommen, das Onboarding steht auf Schritt 1, wenn der Nutzer Esc drückt
  oder das Fenster schließt, dann gilt es **nicht** als abgeschlossen und erscheint beim
  nächsten Start erneut.
  *(Bis 1.1.1 setzte jedes Schließen das Kennzeichen — wer das Fenster wegklickte, um es
  später anzusehen, bekam es nie wieder zu Gesicht. Seit 1.2.0 setzt es ausschließlich
  „Done".)*
- **AK-12** · Angenommen, ein Nutzer hat seine Kürzel geändert, wenn er das Onboarding
  erneut aufruft, dann zeigt der letzte Schritt **seine** Belegung.
  *(Bis 1.1.1 stand dort eine fest hinterlegte Liste — eine zweite Wahrheit für dieselbe
  Sache.)*
- **AK-13** · Angenommen, der Schalter für den Start bei der Anmeldung wird umgelegt, dann
  wirkt er sofort und zeigt danach den tatsächlichen Systemzustand — unabhängig davon, wie
  das Fenster verlassen wird.
  *(Bis 1.1.1 stand er unabhängig vom System auf „an" und wurde nur bei „Done"
  angewendet.)*

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

## Behobener Fehlbestand

- **FB-01 ✅ Abbruch zählte als Abschluss.**
  **Behoben:** Das Kennzeichen setzt nur noch der Abschluss über „Done"; `windowWillClose`
  gibt lediglich das Fenster frei.
- **FB-02 ✅ Die Kürzelliste war fest hinterlegt.**
  **Behoben:** Sie wird aus der laufenden Belegung erzeugt, mit der Standardbelegung als
  Rückfall. Damit gibt es nur noch eine Wahrheit.
- **FB-03 ✅ Der Berechtigungsschritt legte Verzögerungsaufgaben mehrfach an.**
  **Behoben:** Ein Merker sorgt dafür, dass genau einmal weitergeblättert wird; die Aufgabe
  wird beim Verlassen abgebrochen.
- **FB-04 ✅ Der Anmeldeschalter zeigte nicht den tatsächlichen Zustand.**
  **Behoben:** Er liest beim Erscheinen den Systemzustand, wirkt sofort und liest danach
  zurück — bei einem Fehlschlag springt er zurück.
- **FB-05 ✅ Zwei Zeitgeber für dieselbe Aufgabe.**
  **Behoben:** Der eigene Zeitgeber der Ansicht ist entfallen; ausgewertet wird die
  Zustandsänderung.
- **FB-06 ✅ Kein Weg zurück.**
  **Behoben:** Eine Schaltfläche „Back" ab dem zweiten Schritt.
- **FB-07 ✅ Darstellung der Schrittleiste unklar.**
  **Behoben:** Die Blätteransicht ist durch eine eigene Umschaltung ersetzt. Damit kann
  auf macOS keine unbeschriftete Reiterleiste erscheinen — die Frage stellt sich nicht mehr.
- **FB-08 ✅ Kein Test.**
  **Behoben** für den prüfbaren Teil: Die Kürzelliste bezieht ihre Werte aus
  `HotkeyManager`, dessen Laden und Auffüllen in `HotkeyPersistenceTests` abgedeckt ist.
  Der Fensterablauf selbst bleibt Sache der QA.

## Entschiedene Fragen

- **OF-01 ✅ Ein Abbruch gilt nicht als Abschluss.** Das Onboarding erscheint erneut, bis
  es tatsächlich durchlaufen wurde. Es ist zweistufig und dauert Sekunden — die
  Wiederholung wiegt leichter als ein Nutzer, der die Berechtigung nie erteilt.
- **OF-02 ✅ Die Kürzelliste zeigt die tatsächliche Belegung.**
- **OF-03 ✅ Der Anmeldeschalter liest den Systemzustand** und wirkt sofort statt erst bei
  „Done".

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Eigenes Fenster statt Popover | — | Das Popover schließt bei Fokusverlust; für einen Ablauf, der in die Systemeinstellungen führt, unbrauchbar |
| 2 | Schrittzahl abhängig vom Zustand | immer drei Schritte | Wer die Berechtigung schon erteilt hat, soll nicht danach gefragt werden |
| 3 | Selbsttätiges Weiterblättern | Schaltfläche „Weiter" | Der Nutzer ist in diesem Moment in den Systemeinstellungen; nach der Rückkehr soll das Fenster bereits weitergegangen sein |
| 4 | Überspringen möglich | Zwang | Die App bleibt teilweise nutzbar; ein Zwang wäre unhöflich |
| 5 | Erzwungen dunkles Erscheinungsbild | dem System folgen | Markenauftritt. Der Preis ist der Bruch aus `docs/design-system.md` |
| 6 | Esc schließt | nur die Fenstertaste | Übliche Erwartung — mit der Folge aus FB-01 |
