# B02 · Position wiederherstellen — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Ein Wörterbuch im Arbeitsspeicher bildet einen Fensterschlüssel auf einen Rahmen ab.
Geschrieben wird es im Ablauf von B01 — unmittelbar bevor ein Zielrahmen gesetzt wird —,
gelesen ausschließlich von der Aktion „Zurücksetzen", die deshalb als einzige der elf
keinen berechneten Zielrahmen hat.

Der ganze Speicher ist eine Klasse mit drei Methoden und ohne jede Nebenwirkung. Die
Schwierigkeit liegt nicht in der Umsetzung, sondern im Schlüssel.

## Einstiegspunkte

| Auslöser | Über |
|---|---|
| ⌃⌥⌫ | Carbon-Ereignisbehandlung (B03) |
| Rasterfeld „Restore" | SwiftUI-Schaltfläche (B04) |

## Komponentenstruktur

```
SnapHistory                         @MainActor, keine Beobachtbarkeit nötig
├── positions: [String: CGRect]     der gesamte Zustand
├── savePosition(_:for:)            ← WindowManager, vor jedem Snap
├── getPosition(for:) -> CGRect?    ← WindowManager, nur bei restore
└── clearAll()                      von NIEMANDEM gerufen (FB-04)

WindowManager
├── windowKey(pid:window:)          "<PID>_<Titel>", Ersatz "untitled"
└── snapFrontmostWindow
    ├── restore  → getPosition → applyFrame          KEINE neue Sicherung
    └── sonst    → savePosition(aktuell) → applyFrame
```

Der Unterschied der beiden Zweige ist die ganze Fachlogik: Der Zurücksetzen-Zweig
sichert **nicht**, sonst wäre der Rücksprungpunkt nach dem ersten Zurücksetzen verloren.

## Datenmodell

Keine Tabelle, keine Datei. Ein Eintrag sieht so aus:

| Teil | Aufbau | Beispiel |
|---|---|---|
| Schlüssel | `"<Prozesskennung>_<Fenstertitel>"` | `"4711_Quartalsbericht.pdf"` |
| Schlüssel ohne Titel | `"<Prozesskennung>_untitled"` | `"4711_untitled"` |
| Wert | Rahmen in AX-Koordinaten, Ursprung oben links | `{x: 120, y: 80, w: 900, h: 620}` |

**Lebensdauer:** Prozesslaufzeit von Mika+Grid. Kein Schreiben auf die Platte, kein
Aufräumen, keine Obergrenze.

**Personenbezug:** möglich, im Schlüssel. Siehe `docs/datenmodell.md`, Abschnitt 2 — dies
ist die einzige Stelle der ganzen App, an der überhaupt etwas Personenbeziehbares
vorkommt.

## Zugriffsregeln

| Wer | Darf | Erzwungen durch |
|---|---|---|
| der Fenstermanager | lesen und schreiben | Sichtbarkeit im Prozess |
| jeder andere Teil der App | nichts — es gibt keine weiteren Aufrufer | Zugriffsschutz der Sprache |
| ein anderer Prozess | nichts | Prozessgrenze |

Die Historie ist nicht beobachtbar und wird von keiner Ansicht gelesen. Das ist der
Grund, warum sie keinen Beobachtungsmechanismus braucht.

## Missbrauchsschutz

| Fläche | Grenze | Bewertung |
|---|---|---|
| Wachstum der Historie | **keine** | FB-03 — unbegrenzt |
| Aufrufhäufigkeit | keine nötig | lokal, synchron, kostenlos |
| Wiederherstellen | greift auf dieselbe Nachkorrektur wie jeder Snap zurück | B01 |

## Externe Dienste

Keine.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so (soweit rekonstruierbar) |
|---|---|---|---|
| 1 | Arbeitsspeicher statt Datei | `UserDefaults`, eigene Datei | Datenschutzfreundlich und einfach. Preis: AK-09 |
| 2 | Prozesskennung + Titel als Schlüssel | `_AXUIElementGetWindow` (private API), `kAXWindowNumber` | Ohne private Schnittstelle die naheliegendste Kennung. `kAXWindowNumber` wäre der beständige Weg gewesen und ist öffentlich — **warum er nicht gewählt wurde, ist nicht rekonstruierbar** |
| 3 | Eine Ebene Rückgängig | Stapel je Fenster | Mehr bräuchte eine Oberfläche |
| 4 | Beim Zurücksetzen nicht sichern | auch dort sichern | Sonst wäre der Rücksprungpunkt nach dem ersten Zurücksetzen der gesnappte Rahmen — das Zurücksetzen würde sich selbst entwerten |
| 5 | Eintrag bleibt nach dem Zurücksetzen bestehen | verbrauchen | Wiederholtes Zurücksetzen bleibt so folgenlos statt überraschend |
| 6 | Keine Beobachtbarkeit | `@Observable` | Keine Ansicht liest die Historie — richtig sparsam |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | Sicherung vor dem Snap + Zurücksetzen-Zweig | |
| AK-02 | Prozesskennung im Schlüssel trennt die Apps | |
| AK-03 | `getPosition` liefert nichts → stiller Rückweg | FB-07 |
| AK-04 | Eintrag wird nicht verbraucht | |
| AK-05 | Rasterfeld ruft denselben Einstieg | B04 |
| AK-06 ⚠ | Sicherung **vor jedem** Snap, ohne Prüfung auf bereits gesnappt | offen — B01/OF-01 |
| AK-07 ⚠ | Titel im Schlüssel | offen als OF-01 |
| AK-08 ⚠ | Ersatzwert `untitled` für alle titellosen Fenster | offen als OF-02 |
| AK-09 | Wörterbuch nur im Arbeitsspeicher | |
| AK-10 | kein Schreibpfad vorhanden | prüfbar durch Durchsuchen der Ablagen |
| AK-11 | dasselbe | |

Ohne Kriterium bleibt `clearAll()` — es wird von niemandem gerufen und erfüllt daher
kein einziges Kriterium. Genau so soll diese Spalte toten Code sichtbar machen (FB-04).
