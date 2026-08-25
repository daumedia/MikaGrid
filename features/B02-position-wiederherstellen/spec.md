# B02 · Position wiederherstellen — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1 · Repariert in: v1.2.0

> **Rückerfassung, danach repariert.** Erfasst aus v1.1.1, überarbeitet in **v1.2.0**
> (2026-08-25). Die Kriterien beschreiben den Stand **nach** der Reparatur; was vorher
> anders war, steht in Klammern dabei. ⚠ markiert die Punkte, die **nicht** aus dem
> Repository heraus lösbar sind. *Behobener Fehlbestand* führt jede geschlossene Lücke mit
> ihrer Fundstelle — eine Rekonstruktion, die verschweigt, was falsch war, ist wertlos.

## Zweck

Wer ein Fenster versehentlich gesnappt hat, bekommt seine vorherige Größe und Position
mit ⌃⌥⌫ zurück. Ohne das wäre jeder Snap unumkehrbar — die Ausgangsmaße kennt danach
niemand mehr.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 | rekonstruiert | Der Rahmen wird im Ablauf von B01 gesichert; B02 liest ihn nur zurück |

## User Stories

- **US-01** · Als Nutzer möchte ich einen versehentlichen Snap rückgängig machen, damit
  ich die von Hand eingestellte Fenstergröße nicht neu treffen muss.
- **US-02** · Als Nutzer möchte ich das je Fenster getrennt können, damit das
  Zurücksetzen des einen nicht das andere betrifft.

## Nicht im Scope

- **Mehrstufiges Rückgängig.** Gespeichert wird genau ein Rahmen je Fenster.
- **Wiederherstellen über einen Neustart hinweg.** Die Historie lebt im Arbeitsspeicher.
- **Ein „Vorwärts" nach dem Zurücksetzen.**

## Akzeptanzkriterien

- **AK-01** · Angenommen, ein Fenster steht frei auf dem Schreibtisch, wenn es gesnappt
  und danach ⌃⌥⌫ gedrückt wird, dann hat es wieder genau die vorherige Position und Größe.
- **AK-02** · Angenommen, zwei Fenster verschiedener Apps wurden gesnappt, wenn für eines
  ⌃⌥⌫ gedrückt wird, dann kehrt nur dieses zurück.
- **AK-03** · Angenommen, für das aktive Fenster wurde nie ein Rahmen gesichert, wenn
  ⌃⌥⌫ gedrückt wird, dann passiert nichts — und nichts wird beschädigt.
- **AK-04** · Angenommen, ein Fenster wurde zurückgesetzt, wenn ⌃⌥⌫ erneut gedrückt wird,
  dann bleibt es, wo es ist (der gesicherte Rahmen wird nicht verbraucht).
- **AK-05** · Angenommen, die Aktion „Zurücksetzen" wird im Popover angeklickt, dann
  wirkt sie wie das Tastenkürzel.
- **AK-06** · Angenommen, ein Fenster wurde erst auf die linke Hälfte und dann auf die
  rechte gesnappt, wenn ⌃⌥⌫ gedrückt wird, dann landet es auf seiner **ursprünglichen
  freien Größe**.
  *(Bis 1.1.1 auf der linken Hälfte — jeder Snap überschrieb den Rücksprungpunkt.)*
- **AK-07** · Angenommen, ein Fenster wurde gesnappt und danach ändert sich sein Titel,
  wenn ⌃⌥⌫ gedrückt wird, dann wird es unverändert wiederhergestellt.
  *(Bis 1.1.1 passierte nichts, weil der Titel Teil des Schlüssels war. Seit 1.2.0 ist der
  Schlüssel das Fenster selbst, verglichen über `CFEqual`.)*
- **AK-08** · Angenommen, eine App hat mehrere Fenster ohne Titel, wenn nacheinander beide
  gesnappt werden, dann behält jedes seinen eigenen Rücksprungpunkt.
  *(Bis 1.1.1 teilten sie sich den Schlüssel `"<PID>_untitled"`. Nachweis:
  `SnapHistoryTests.differentElementsDoNotCollide`.)*
- **AK-09** · Angenommen, die App wird beendet und neu gestartet, wenn ⌃⌥⌫ gedrückt wird,
  dann passiert nichts — die Historie ist leer.

### Datenschutz und Missbrauchsschutz

Geprüft gegen `~/.claude/sdd/sicherheit.md`.

- **AK-10** · Angenommen, Fenster wurden gesnappt, wenn die Festplatte durchsucht wird,
  dann findet sich **kein** Fenstertitel — weder in den Einstellungen, noch in einer
  Datei, noch in einem Protokoll.
- **AK-11** · Angenommen, die App wird beendet, wenn geprüft wird, was von der Historie
  übrig bleibt, dann nichts.
- **Besondere Kategorien:** Ein Fenstertitel kann mittelbar sensibel sein — der Name
  einer Arztpraxis in einem Browser-Tab, der Betreff einer E-Mail. Die Daten entstehen
  nicht in dieser App, werden aber von ihr gelesen und im Arbeitsspeicher gehalten.
  Deshalb ist AK-10 kein Formalkriterium, sondern die Zusage, auf der Stufe A ruht.
- **Löschfristen:** Prozesslaufzeit. Kein Löschkonzept nötig, solange nichts persistiert
  wird — genau deshalb ist FB-05 relevant.
- **Rate Limits, Rollen, externe Dienste, Geheimnisse:** treffen nicht zu.

## Edge Cases

- **EC-01** · Fenstertitel ist leer oder nicht lesbar → Ersatzwert `untitled`, mit der
  Kollisionsfolge aus AK-08.
- **EC-02** · Die App des Fensters wurde beendet und neu gestartet → neue
  Prozesskennung, neuer Schlüssel; der alte Eintrag bleibt als Karteileiche liegen.
- **EC-03** · Prozesskennung wird vom System wiederverwendet → theoretisch könnte ein
  fremdes Fenster einen fremden Rahmen erben, sofern zusätzlich der Titel übereinstimmt.
  Sehr unwahrscheinlich, aber nicht ausgeschlossen.
- **EC-04** · Der gesicherte Rahmen liegt auf einem inzwischen abgezogenen Bildschirm →
  das Fenster wird dorthin gesetzt und von macOS notdürftig zurückgeholt. Nicht behandelt.
- **EC-05** · Der gesicherte Rahmen lässt sich nicht wiederherstellen (die App verweigert
  die Größe) → dieselbe Nachkorrektur wie bei jedem Snap greift, danach wird aufgegeben.

## Behobener Fehlbestand

- **FB-01 ✅ Der Schlüssel enthielt den Fenstertitel und war unbeständig.**
  **Behoben:** `WindowKey` trägt das `AXUIElement` des Fensters; die Accessibility-API
  sichert zu, dass zwei Referenzen auf dasselbe Fenster `CFEqual` sind. Nachweis:
  `SnapHistoryTests.sameElementSameKey`.
- **FB-02 ✅ Titellose Fenster kollidierten.** **Behoben** mit FB-01.
- **FB-03 ✅ Die Historie wuchs unbegrenzt.** **Behoben:** Obergrenze von 100 Einträgen mit
  Verdrängung der ältesten. Nachweis: `historyIsBounded`, `oldestEntriesAreEvicted`.
- **FB-04 ✅ `clearAll()` wurde nie aufgerufen.** **Behoben:** Es läuft bei „Alle
  Einstellungen zurücksetzen", bei Entzug der Berechtigung und bei einer Änderung der
  Bildschirmanordnung.
- **FB-05 ✅ Kein Löschkonzept, weil kein Speicher.** **Behoben** im Sinne von ausdrücklich
  festgehalten: Die Bremse steht in `docs/datenschutz.md`. Mit FB-01 ist der Punkt
  zusätzlich entschärft — im Arbeitsspeicher liegt kein Fenstertitel mehr, sondern eine
  Fensterreferenz ohne Aussagewert.
- **FB-06 ✅ Kein Test.** **Behoben:** `SnapHistoryTests` mit acht Fällen.
- **FB-07 ✅ Kein Hinweis, wenn nichts wiederherzustellen ist.** **Behoben:**
  `.nothingToRestore` mit Systemton und der Meldung „Nothing to restore".

## Entschiedene Fragen

- **OF-01 ✅ Der Schlüssel ist umgestellt** — auf die Fensterreferenz statt auf die
  Fensternummer. `CFEqual` ist der öffentliche Weg und erspart die private Funktion
  `_AXUIElementGetWindow`. Erledigt FB-01, FB-02 und den Personenbezug in einem Zug.
- **OF-02 ✅ Die Historie ist auf 100 Einträge begrenzt.**
- **OF-03 ✅ Wiederholtes Snappen bewahrt den ursprünglichen Rahmen** (B01/OF-01).

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wo liegt die Historie | Wörterbuch im Arbeitsspeicher | Kein Speicherbedarf über die Sitzung hinaus, und keine Datei mit Fenstertiteln — der datenschutzfreundlichste Weg |
| 2 | Schlüssel | Prozesskennung + Fenstertitel | Ohne private API die einzige unmittelbar verfügbare Kennung. Der Preis steht in FB-01 |
| 3 | Tiefe | ein Rahmen je Fenster | Mehrstufiges Rückgängig bräuchte eine Oberfläche, die es hier nicht gibt |
| 4 | Verbrauchen beim Zurücksetzen | nein | Zweimal ⌃⌥⌫ soll nicht überraschen; der Rahmen bleibt gültig |
| 5 | `restore` als Teil der Aktionsliste | ja | So bekommt es Kürzel und Rasterfeld geschenkt, statt einen Sonderweg zu brauchen |
