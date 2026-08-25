# B02 · Position wiederherstellen — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1

> **Rückerfassung.** ⚠ markiert Verhalten, das zur Klärung vorliegt.

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
- **AK-06** ⚠ · Angenommen, ein Fenster wurde erst auf die linke Hälfte und dann auf die
  rechte gesnappt, wenn ⌃⌥⌫ gedrückt wird, dann landet es auf der **linken Hälfte** —
  nicht auf seiner ursprünglichen freien Größe.
  *(So verhält sich der Code heute: Vor jedem Snap wird der aktuelle Rahmen gesichert und
  der vorherige überschrieben. Siehe B01/OF-01.)*
- **AK-07** ⚠ · Angenommen, ein Fenster wurde gesnappt und danach ändert sich sein Titel
  — ein anderer Browser-Tab, eine gespeicherte Datei —, wenn ⌃⌥⌫ gedrückt wird, dann
  passiert **nichts**.
  *(Der Schlüssel enthält den Fenstertitel; nach der Änderung passt er nicht mehr. Siehe
  OF-01.)*
- **AK-08** ⚠ · Angenommen, eine App hat mehrere Fenster **ohne** Titel, wenn nacheinander
  beide gesnappt werden, dann überschreibt das zweite den gesicherten Rahmen des ersten,
  und ⌃⌥⌫ setzt beide auf denselben Rahmen.
  *(Alle titellosen Fenster einer App teilen sich den Schlüssel `"<PID>_untitled"`.
  Siehe OF-02.)*
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

## Fehlbestand

- **FB-01 · Der Schlüssel enthält den Fenstertitel und ist damit unbeständig.**
  `WindowManager.windowKey(pid:window:)`. **Folge:** AK-07 — bei jeder Titeländerung
  verliert das Fenster seinen Rücksprungpunkt, ohne dass der Nutzer erfährt, warum. Bei
  Browsern und Editoren ist das der Normalfall, nicht die Ausnahme. Ein beständiger
  Schlüssel wäre `kAXWindowNumber` bzw. `_AXUIElementGetWindow`.
- **FB-02 · Titellose Fenster einer App kollidieren.** Derselbe Ort. **Folge:** AK-08.
- **FB-03 · Die Historie wächst unbegrenzt.** `SnapHistory` kennt kein Limit und keine
  Verdrängung. **Folge:** Jedes je gesnappte Fenster hinterlässt dauerhaft einen Eintrag
  samt Titel im Arbeitsspeicher. Bei langer Laufzeit ein stetig wachsender Bestand — klein
  je Eintrag, aber unbegrenzt, und er besteht aus genau den Zeichenketten, die man nicht
  aufheben möchte.
- **FB-04 · `clearAll()` wird von keiner Stelle aufgerufen.** **Folge:** Toter Code, und
  zugleich fehlt die naheliegende Aufräumgelegenheit — etwa beim Zurücksetzen der
  Einstellungen oder beim Entzug der Berechtigung.
- **FB-05 · Kein Löschkonzept, weil kein Speicher — noch nicht.** Die heutige Lösung ist
  datenschutzrechtlich unbedenklich, **weil** sie flüchtig ist. Der naheliegende
  Wunsch „Zurücksetzen soll einen Neustart überleben" würde aus einem
  Arbeitsspeicher-Wörterbuch eine Datei mit Fenstertiteln machen. **Folge:** Wer das
  umsetzt, muss zwingend die Stufe im PRD neu bewerten. Dieser Eintrag ist die Bremse
  dafür.
- **FB-06 · Kein Test.** Die Schlüsselbildung ist reine Zeichenkettenlogik und ließe sich
  vollständig prüfen — einschließlich der Kollision aus AK-08.
- **FB-07 · Kein Hinweis, wenn nichts wiederherzustellen ist.** Wie überall in B01 endet
  der Pfad still.

## Offene Fragen

- **OF-01** · Soll der Schlüssel auf die Fensternummer umgestellt werden (FB-01)? Das
  behebt AK-07 und AK-08 gemeinsam und nimmt zugleich den Fenstertitel aus dem
  Arbeitsspeicher — es ist die einzige Änderung in diesem Feature, die drei Befunde auf
  einmal erledigt. — *Betreiber, empfohlen.*
- **OF-02** · Soll die Historie begrenzt werden (FB-03)? Etwa auf die letzten 50
  Einträge, oder durch Aufräumen beim Beenden der Ziel-App. — *Betreiber.*
- **OF-03** · Soll wiederholtes Snappen den ursprünglichen Rahmen bewahren (AK-06)?
  Identisch mit B01/OF-01 — dort entschieden. — *Betreiber.*

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wo liegt die Historie | Wörterbuch im Arbeitsspeicher | Kein Speicherbedarf über die Sitzung hinaus, und keine Datei mit Fenstertiteln — der datenschutzfreundlichste Weg |
| 2 | Schlüssel | Prozesskennung + Fenstertitel | Ohne private API die einzige unmittelbar verfügbare Kennung. Der Preis steht in FB-01 |
| 3 | Tiefe | ein Rahmen je Fenster | Mehrstufiges Rückgängig bräuchte eine Oberfläche, die es hier nicht gibt |
| 4 | Verbrauchen beim Zurücksetzen | nein | Zweimal ⌃⌥⌫ soll nicht überraschen; der Rahmen bleibt gültig |
| 5 | `restore` als Teil der Aktionsliste | ja | So bekommt es Kürzel und Rasterfeld geschenkt, statt einen Sonderweg zu brauchen |
