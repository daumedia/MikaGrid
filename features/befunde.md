# Befunde

Laufende Sammelliste über alle Features. Wird von `sdd-qa` fortgeschrieben, nie von Hand.

Ein einzelner `qa-report.md` zeigt einen Befund; erst projektweit wird sichtbar, dass
dieselbe Lücke mehrfach steckt — und das ist der eigentliche Ertrag.

Stand: 2026-08-26

## Offen

| ID | Feature | Befund | Grad | Fundstelle | Status |
|---|---|---|---|---|---|
| BF-02 | 01 | Zwei gleichnamige Kurzbefehle machen den Aufruf unmöglich (`shortcuts run` → „Kurzbefehl nicht gefunden"). `CompanionShortcutManager.alternativeName(attempt:)` ist gebaut, wird aber nirgends aufgerufen — EC-02 ist damit nicht abgedeckt | mittel | `Sources/MikaGridMAS/CompanionShortcutManager.swift:101` | offen |
| BF-03 | 01 | Die Store-Fassung kann nicht erkennen, ob der gesetzte Rahmen tatsächlich angekommen ist. Kurzbefehle liefert die Rahmenwerte nicht zurück, also gibt es keine Rückmessung wie in der Direktfassung (B01: bis 3 Durchläufe, 2 pt Toleranz). Eine Zielanwendung, die den Rahmen beschneidet, bleibt unbemerkt | mittel | `Sources/MikaGridCore/SnapReply.swift` — die im Entwurf vorgesehenen `actual`-Felder sind nicht baubar (OF-02, OF-07) | offen |
| BF-04 | 01 | Die Integritätsprüfung des Companion-Kurzbefehls kann nur Name, Aktionszahl und Eingabeverhalten vergleichen — **nicht, was die Aktionen tun**. Erkennt einen versehentlich ersetzten Kurzbefehl, keinen absichtlich mit gleicher Aktionszahl nachgebauten. AK-26 dadurch nur teilweise erfüllt | mittel | `Sources/MikaGridMAS/CompanionShortcutManager.swift:74` — Grenze der Skripting-Schnittstelle, nicht der Umsetzung (OF-11) | offen |
| BF-05 | 01 | `Move Window` nimmt keine negativen Koordinaten an; ein Bildschirm links oder oberhalb des Hauptbildschirms ist nicht erreichbar. AK-10 auf dem Prüfrechner nicht abschließend prüfbar (dort liegt der zweite Bildschirm oberhalb) | mittel | `Sources/MikaGridMAS/ShortcutsWindowSnapper.swift` — `screenForFrontmostWindow` (OF-10) | offen |

## Behoben

| ID | Feature | Befund | Grad | Fundstelle | Behoben |
|---|---|---|---|---|---|
| BF-01 | 01 | Fenster landen nicht auf dem berechneten Rahmen — 0 von 5 Läufen exakt. Ursache: Der Kurzbefehl schrieb Position → Größe → Position; macOS begrenzt einen Positionswechsel gegen die **aktuelle** Fenstergröße, weshalb große Zielrahmen danebengingen. Die Direktfassung schreibt seit 1.1.1 aus genau diesem Grund Größe → Position → Größe (CLAUDE.md), `design.md` (Entscheidung 10) schrieb es falsch vor | hoch | `scripts/make-companion-shortcut.sh` | 2026-08-26 · Reihenfolge umgestellt, Pausen 0,15 → 0,2 s. Gegenprobe **10 von 10 exakt**, 0,83–0,85 s |
| BF-06 | 01 | Die Zeitgrenze des Kurzbefehl-Aufrufs war deklariert (`timeout = 1.0`), aber nirgends gelesen — EC-04 damit nicht umgesetzt. `NSAppleScript` kennt keine Zeitgrenze; ein hängender Aufruf hätte die Menüleiste eingefroren | mittel | `Sources/MikaGridMAS/ShortcutsRunner.swift:57` | 2026-08-26 · Aufruf auf Hintergrund-Warteschlange mit `DispatchSemaphore.wait(timeout:)`, Grenze 2,0 s (1,0 s hätte laufende Snaps abgeschnitten) |

## Akzeptiert

| ID | Feature | Befund | Grad | Begründung | Datum |
|---|---|---|---|---|---|
| BF-07 | 01 | **AK-22 ist nicht erfüllt:** Beide Fassungen tragen dieselbe Bundle-Kennung `lu.daumedia.mikagrid` und sind deshalb nicht nebeneinander installierbar — gemeinsame Einstellungen, gemeinsames Anmeldeobjekt, LaunchServices kann sie nicht unterscheiden | hoch | **Betreiberentscheidung.** In App Store Connect gibt es nur diese eine Kennung. Der Entwurf sah `.mas` vor; die Folgen sind benannt und bewusst in Kauf genommen. Folgenlos, solange nur ein Vertriebsweg ausgespielt wird. Rücknehmbar über OF-04 in `spec.md` | 2026-08-26 |

## Muster

**Muster 1 · Eine Schnittstelle, die keinen Erfolg zurückmeldet, verbirgt ihre Fehler.**

BF-01 (Rahmen saß nicht) blieb nur deshalb unbemerkt, weil BF-03 danebensteht: Kurzbefehle
meldet in jedem Fall `ok`. In der Direktfassung wäre BF-01 harmlos gewesen — dort fängt
die Rückmessung ihn ab (B01: bis 3 Durchläufe, 2 pt Toleranz). Aus einer Ungenauigkeit
wurde erst durch das fehlende Echo ein stiller Fehler.

*Für den nächsten Durchgang:* Wo ein Feature auf eine Schnittstelle ohne Erfolgsmeldung
setzt, gehört von Anfang an eine eigene Messung dazu — sonst prüft niemand das Ergebnis,
sondern nur die Absicht.

**Muster 2 · Bestandswissen stand in `CLAUDE.md`, der Entwurf hat es überschrieben.**

Die Ursache von BF-01 war seit 1.1.1 dokumentiert („Snap write sequence — do not
simplify"). `design.md` hat für den neuen Weg trotzdem die umgekehrte Reihenfolge
vorgeschrieben, und der Bau ist ihr gefolgt.

*Für den nächsten Durchgang:* Wenn ein Entwurf eine Abfolge festlegt, die das Projekt
schon einmal anders gelöst hat, gehört die Abweichung begründet — oder sie ist ein
Versehen.
