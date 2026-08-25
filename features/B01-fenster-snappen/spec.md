# B01 · Fenster snappen — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1

> **Rückerfassung.** ⚠ markiert Verhalten, das zur Klärung vorliegt.

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
- **AK-15** ⚠ · Angenommen, ein Fenster wurde bereits gesnappt, wenn eine zweite
  Snap-Aktion folgt, dann wird die **gesnappte** Zwischenposition als Rücksprungpunkt
  gemerkt, nicht die ursprüngliche.
  *(So verhält sich der Code heute: Vor jedem Snap wird der aktuelle Rahmen gesichert.
  Nach ⌃⌥← gefolgt von ⌃⌥→ führt ⌃⌥⌫ also auf die linke Hälfte zurück, nicht auf die
  Ausgangsgröße. Gehört zur Mechanik von B02, entsteht aber hier. Siehe OF-01.)*
- **AK-16** ⚠ · Angenommen, Mika+Grid ist seit dem Start die einzige benutzte App, wenn
  eine Zone im Popover angeklickt wird, dann passiert **nichts**.
  *(Es gibt noch keine zuletzt aktive fremde App; `frontmostApplication` ist Mika+Grid
  selbst, der Rückfallwert ist leer. Ohne Rückmeldung. Siehe OF-02.)*

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

## Fehlbestand

- **FB-01 · Keine Rückmeldung, wenn ein Snap nichts bewirkt.** Alle sechs Abbruchpfade in
  `WindowManager.snapFrontmostWindow` und `applyFrame` enden mit einem stillen `return`:
  fehlende Berechtigung, keine Ziel-App, kein fokussiertes Fenster, kein lesbarer Rahmen,
  nicht setzbare Attribute, kein Zielrahmen. **Folge:** Aus Nutzersicht sind sechs sehr
  verschiedene Ursachen nicht unterscheidbar — es passiert einfach nichts.
- **FB-02 · Kein Test für die Zielgeometrie.** `SnapAction.targetFrame` ist reine
  Rechnung ohne Systemabhängigkeit und ließe sich vollständig prüfen: Hälften stoßen
  aneinander, Viertel überlappen nicht, die Vereinigung ergibt den nutzbaren Bereich,
  die zentrierte Fläche misst zwei Drittel. Nichts davon ist abgesichert — und genau
  diese Klasse von Fehlern machte 1.1.1 nötig.
- **FB-03 · `NSScreen.primaryHeight` kann 0 liefern.** Die Kette endet mit `?? 0`.
  **Folge:** Jede Koordinatenumrechnung wäre still falsch statt erkennbar kaputt. Ein
  Absturz wäre hier das bessere Verhalten.
- **FB-04 · Die Vollbild-Annahme ist unbelegt.** Der Kommentar in `applyFrame` nennt
  Vollbildfenster als abgedeckt, geprüft wird aber nur, ob Position und Größe setzbar
  sind. Ob das bei einem Vollbildfenster tatsächlich `false` ergibt, ist nicht
  nachgewiesen. **Folge:** Möglicherweise wird an einem Vollbildfenster herumgeschrieben,
  mit unklarem Ergebnis. `kAXFullScreenAttribute` würde die Frage eindeutig beantworten.
- **FB-05 · Die zuletzt aktive fremde App wird nie vergessen.** Die Kennung wird bei
  jeder Aktivierung gesetzt, aber nie geleert — auch nicht, wenn die App endet. **Folge:**
  EC-02, und im Extremfall wird eine wiederverwendete Prozesskennung getroffen.
- **FB-06 · Keine Behandlung von Bildschirmwechseln.** Wird ein Monitor abgezogen,
  während ein Fenster darauf liegt, ordnet macOS es neu an; die App bemerkt nichts. Kein
  Beobachter auf `NSApplication.didChangeScreenParametersNotification`.
- **FB-07 · Der Beobachter für App-Wechsel wird nie abgemeldet.** Bewusst so, mit
  Begründung im Code („lebt so lange wie die App"). Sauber wäre es dennoch, und bei
  einem künftigen zweiten `WindowManager` wäre es ein Fehler.

## Offene Fragen

- **OF-01** · Soll wiederholtes Snappen den ursprünglichen Rahmen behalten (AK-15)?
  Heute überschreibt jeder Snap den Rücksprungpunkt. Alternative: nur sichern, wenn der
  aktuelle Rahmen keinem Snap-Ziel entspricht. — *Betreiber.*
- **OF-02** · Soll ein Snap ohne verfügbares Ziel eine Rückmeldung geben (AK-16, FB-01)?
  — *Betreiber.*
- **OF-03** · Sollen Vollbildfenster ausdrücklich erkannt werden (FB-04)? — *nach QA.*

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
