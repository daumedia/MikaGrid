# B01 · Fenster snappen — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1 · Repariert in: v1.2.0

> **Rückerfassung, danach repariert.** Erfasst aus v1.1.1, überarbeitet in **v1.2.0**
> (2026-08-25). Die Kriterien beschreiben den Stand **nach** der Reparatur; was vorher
> anders war, steht in Klammern dabei. ⚠ markiert die Punkte, die **nicht** aus dem
> Repository heraus lösbar sind. *Behobener Fehlbestand* führt jede geschlossene Lücke mit
> ihrer Fundstelle — eine Rekonstruktion, die verschweigt, was falsch war, ist wertlos.

## Zweck

Das aktive Fenster einer beliebigen App springt auf einen Tastendruck oder Klick an eine
vorbestimmte Stelle des Bildschirms: halb, viertel, ganz oder mittig auf zwei Dritteln.
Ohne Ziehen, ohne Zielen, ohne dass die Maus den Rand treffen muss.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B05 | rekonstruiert | Ohne erteilte Accessibility-Berechtigung tut dieses Feature nichts |

Umgekehrt bauen B02, B03 und B04 darauf auf.

## User Stories

- **US-01** · Als Nutzer möchte ich zwei Fenster nebeneinander legen, ohne sie von Hand
  auf Kante zu ziehen, damit ich Editor und Browser gleichzeitig sehe.
- **US-02** · Als Nutzer möchte ich, dass ein Fenster auf **dem** Bildschirm einrastet,
  auf dem es gerade steht, damit es bei mehreren Monitoren nicht wegspringt.
- **US-03** · Als Nutzer möchte ich, dass linke und rechte Hälfte lückenlos aneinander
  stoßen, damit kein Streifen Schreibtisch durchscheint.

## Nicht im Scope

- **Wiederherstellen der vorherigen Position** — das ist B02, obwohl `restore` technisch
  eine der elf Aktionen ist.
- **Fenster auf einen anderen Bildschirm verschieben.** Heute nicht gebaut und laut PRD
  ausdrücklich **nicht** ausgeschlossen — wer es baut, legt ein eigenes Feature an.
- **Einrasten per Maus am Bildschirmrand.** Im PRD als Nicht-Ziel festgehalten.
- **Auswahl unter mehreren Fenstern einer App.** Es wird immer das fokussierte behandelt.

## Akzeptanzkriterien

- **AK-01** · Angenommen, ein veränderbares Fenster ist aktiv, wenn ⌃⌥← gedrückt wird,
  dann füllt es die linke Hälfte des nutzbaren Bereichs — unter der Menüleiste, neben
  dem Dock.
- **AK-02** · Angenommen dasselbe, wenn ⌃⌥→, ⌃⌥↑ oder ⌃⌥↓ gedrückt wird, dann füllt es
  die rechte, obere bzw. untere Hälfte.
- **AK-03** · Angenommen dasselbe, wenn ⌃⌥U, ⌃⌥I, ⌃⌥J oder ⌃⌥K gedrückt wird, dann füllt
  es das entsprechende Viertel.
- **AK-04** · Angenommen dasselbe, wenn ⌃⌥↩ gedrückt wird, dann füllt es den gesamten
  nutzbaren Bereich — **ohne** in den macOS-Vollbildmodus zu wechseln.
- **AK-05** · Angenommen dasselbe, wenn ⌃⌥C gedrückt wird, dann steht es mittig und
  belegt zwei Drittel der Breite und zwei Drittel der Höhe.
- **AK-06** · Angenommen, ein Fenster wurde auf die linke Hälfte gelegt und ein zweites
  auf die rechte, wenn beide Kanten verglichen werden, dann berühren sie sich exakt:
  kein Spalt, keine Überlappung — auch auf skalierten Displays und Macs mit Aussparung.
- **AK-07** · Angenommen, mehrere Bildschirme sind angeschlossen, wenn ein Fenster
  gesnappt wird, dann geschieht das auf dem Bildschirm, auf dem sein **Mittelpunkt**
  liegt — nicht auf dem Hauptbildschirm und nicht auf dem mit der Maus.
- **AK-08** · Angenommen, eine Zone im Popover wird angeklickt, wenn zuvor eine andere
  App aktiv war, dann wird **deren** Fenster gesnappt, nicht Mika+Grid selbst.
- **AK-09** · Angenommen, ein Fenster ist größer als das Ziel, wenn ein Snap ausgelöst
  wird, dann sitzt es nach **einem** Auslösen richtig — Position und Größe zugleich, kein
  zweiter Tastendruck nötig.
- **AK-10** · Angenommen, das Zielfenster gehört zu einer Chromium-, Electron- oder
  Java-App oder VoiceOver läuft, wenn gesnappt wird, dann gilt AK-09 unverändert.
- **AK-11** · Angenommen, das Zielfenster gehört zu einer App, die nicht mehr antwortet,
  wenn gesnappt wird, dann bleibt die Menüleiste bedienbar und der Vorgang endet nach
  spätestens etwa einer Sekunde.
- **AK-12** · Angenommen, ein Fenster lässt sich nicht verschieben oder nicht in der
  Größe ändern — ein modaler Dialog etwa —, wenn gesnappt wird, dann bleibt es
  unverändert und die App stürzt nicht ab.
- **AK-13** · Angenommen, eine App erzwingt eine Mindestgröße, wenn ein kleineres Ziel
  verlangt wird, dann wird der Versuch nach wenigen Durchgängen aufgegeben, statt endlos
  nachzukorrigieren.
- **AK-14** · Angenommen, VoiceOver läuft, wenn ein Snap abgeschlossen ist, dann ist
  `AXEnhancedUserInterface` der Ziel-App wieder eingeschaltet.
- **AK-15** · Angenommen, ein Fenster wurde bereits gesnappt, wenn eine zweite Snap-Aktion
  folgt, dann bleibt der **ursprüngliche** Rahmen als Rücksprungpunkt erhalten: ⌃⌥← gefolgt
  von ⌃⌥→ und dann ⌃⌥⌫ führt auf die von Hand eingestellte Größe zurück.
  *(Bis 1.1.1 wurde vor jedem Snap gesichert und der ursprüngliche Rahmen dabei
  überschrieben. Seit 1.2.0 prüft `isSnapTarget`, ob der aktuelle Rahmen bereits einem der
  zehn Ziele entspricht, und sichert dann nicht.)*
- **AK-16** · Angenommen, Mika+Grid ist seit dem Start die einzige benutzte App, wenn eine
  Zone im Popover angeklickt wird, dann ertönt ein Systemton und im Popover erscheint
  „No window to snap".
  *(Bis 1.1.1 passierte wortlos nichts. Seit 1.2.0 liefert `snapFrontmostWindow` ein
  `SnapResult`, das `AppState.performSnap` auswertet.)*

### Datenschutz und Missbrauchsschutz

Geprüft gegen `~/.claude/sdd/sicherheit.md`.

- **AK-17** · Angenommen, ein Snap läuft, wenn geprüft wird, welche Fensterattribute
  gelesen werden, dann sind es ausschließlich Position, Größe und Titel — keine
  Inhalte, keine Textfelder, keine Tastatureingaben.
- **AK-18** · Angenommen, ein Snap läuft, wenn geprüft wird, was die App nach außen
  sendet, dann ist es nichts. Kein Protokoll, keine Datei, keine Verbindung.
- **AK-19** · Angenommen, die Berechtigung fehlt, wenn ein Snap ausgelöst wird, dann
  wird kein einziger AX-Aufruf auf ein fremdes Fenster abgesetzt.
- **Rate Limits, Uploads, Rollen, Geheimnisse:** treffen nicht zu — lokaler Vorgang ohne
  Endpunkt, ohne Konten, ohne Kosten.
- **Fenstertitel:** werden gelesen, aber nur zur Schlüsselbildung an B02 gereicht. Siehe
  dort.

## Edge Cases

- **EC-01** · Kein Bildschirm enthält den Fenstermittelpunkt (Fenster ragt über den Rand
  hinaus oder liegt zwischen zwei Monitoren) → Rückfall auf den Hauptbildschirm; das
  Fenster springt dorthin.
- **EC-02** · Die zuletzt aktive fremde App wurde beendet → ihre Prozesskennung zeigt
  ins Leere, die AX-Aufrufe schlagen fehl, es passiert stillschweigend nichts.
- **EC-03** · Fenster im macOS-Vollbildmodus → Position und Größe sind laut System nicht
  setzbar, der Snap wird übersprungen. **In der QA zu bestätigen** — die Annahme steht
  als Kommentar im Code, ist aber nicht belegt.
- **EC-04** · Die Ziel-App zieht nach dem Verschieben die Größe nach (Chromium beschneidet
  die Breite auf den Platz rechts vom Ursprung) → der dritte Schreibvorgang und die
  Nachkorrektur fangen das ab.
- **EC-05** · Die App erfüllt den Zielrahmen nie (Terminal mit Zeichenraster) → zwei
  gleiche Messungen hintereinander gelten als Stillstand, der Vorgang endet.
- **EC-06** · Zeitgrenze von 0,6 s überschritten → Abbruch nach dem laufenden Durchgang.
  Die Prüfung erfolgt **nach** dem Schreiben, ein Durchgang läuft also immer vollständig.
- **EC-07** · Kein Bildschirm liegt am globalen Ursprung → Rückfall auf den ersten
  Bildschirm; liefert auch der nichts, wird mit Höhe 0 gerechnet und alle Ziele wären
  falsch. Praktisch unerreichbar, aber ungesichert.

## Behobener Fehlbestand

Alle sieben Lücken sind in v1.2.0 geschlossen. Sie bleiben mit Fundstelle stehen, weil eine
Rekonstruktion sonst verschweigt, was einmal falsch war.

- **FB-01 ✅ Keine Rückmeldung, wenn ein Snap nichts bewirkt.** Alle sechs Abbruchpfade
  endeten mit einem stillen `return`, sodass sehr verschiedene Ursachen gleich aussahen.
  **Behoben:** `snapFrontmostWindow` liefert ein `SnapResult` mit sechs unterscheidbaren
  Fällen; `AppState.performSnap` erzeugt Systemton und Begründung im Popover.
  Nachweis: `SnapResultTests`.
- **FB-02 ✅ Kein Test für die Zielgeometrie.**
  **Behoben:** `SnapGeometryTests` prüft lückenloses Kacheln, Vollabdeckung, die
  Zweidrittel-Fläche, gebrochene Bildschirmmaße und einen Bildschirm mit negativem
  Ursprung. `targetFrame` ist dafür in eine reine Funktion ohne Systemzugriff aufgeteilt.
- **FB-03 ✅ `NSScreen.primaryHeight` konnte still 0 liefern.**
  **Behoben:** Die Eigenschaft ist optional; `targetFrame(on:)` liefert `nil` statt falsch
  gerechneter Koordinaten.
- **FB-04 ✅ Die Vollbild-Annahme war unbelegt.**
  **Behoben:** `applyFrame` prüft `AXFullScreen` ausdrücklich, statt sich auf die
  Setzbarkeit zu verlassen.
- **FB-05 ✅ Die zuletzt aktive fremde App wurde nie vergessen.**
  **Behoben:** Ein Beobachter auf `didTerminateApplicationNotification` leert die Kennung —
  eine wiederverwendete Prozesskennung kann nicht mehr getroffen werden.
- **FB-06 ✅ Keine Behandlung von Bildschirmwechseln.**
  **Behoben:** `didChangeScreenParametersNotification` leert die Positionshistorie.
- **FB-07 ✅ Der Beobachter wurde nie abgemeldet.**
  **Behoben:** Alle drei Beobachter liegen in einer Liste und werden im `deinit` entfernt.

## Entschiedene Fragen

- **OF-01 ✅ Wiederholtes Snappen bewahrt den ursprünglichen Rahmen** (`isSnapTarget`).
  Das entspricht der Erwartung „⌃⌥⌫ bringt mich dahin zurück, wo ich war".
- **OF-02 ✅ Ein Snap ohne Ziel gibt Rückmeldung.** Systemton immer, Begründung im Popover.
  Eine Systembenachrichtigung wäre für einen Tastendruck zu aufdringlich und verlangte eine
  weitere Berechtigung.
- **OF-03 ✅ Vollbildfenster werden ausdrücklich erkannt** (siehe FB-04).

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Schreibreihenfolge | Größe → Position → Größe | macOS wägt einen Positionsschreibvorgang gegen die **aktuelle** Größe ab; ein zu großes Fenster lässt sich nicht an die Zielkante schieben, bevor es geschrumpft ist |
| 2 | `AXEnhancedUserInterface` vorübergehend aus | — | Ist es an, animiert AppKit die Rahmenänderung, und der Größenschreibvorgang bricht die Positionsanimation ab. Wird immer zurückgesetzt, weil VoiceOver darauf angewiesen ist |
| 3 | Nachkorrektur mit Rückmessung | blind schreiben | Apps beschneiden den Rahmen eigenmächtig; ohne Rückmessung bliebe das unbemerkt |
| 4 | Toleranz 2 pt | exakter Vergleich | Deckt HiDPI-Rundung ab, ohne echte Fehlschläge zu verstecken |
| 5 | Zeitgrenze 0,6 s, Nachrichtengrenze 0,25 s | ohne Grenze | Ohne sie hängt die Menüleiste mit, sobald die Ziel-App blockiert. Die Grenze gilt je Objekt und muss deshalb zweimal gesetzt werden |
| 6 | Kanten runden statt Breite/Höhe | Breite runden | Nur so stoßen zwei Hälften bei gebrochenen Maßen lückenlos aneinander |
| 7 | Bildschirm über den Fenstermittelpunkt | über die Mausposition oder den Hauptbildschirm | Der Mittelpunkt ist das, was der Nutzer als „wo das Fenster ist" erlebt |
| 8 | Rückfall auf die zuletzt aktive fremde App | das Popover nicht als Fenster führen | `.menuBarExtraStyle(.window)` macht Mika+Grid selbst zur vordersten App — ohne Rückfall würde sich die App selbst snappen |
| 9 | Typprüfung über `CFGetTypeID` | direkte Umwandlung | Eine unsichere Umwandlung stürzt ab, wenn eine App ein unerwartetes Attribut liefert |
