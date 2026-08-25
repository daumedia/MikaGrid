# B04 · Menüleisten-Popover — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Die gesamte App besteht aus einer einzigen Szene: einem Menüleisteneintrag im
Fenstermodus. Dessen Inhalt ist eine Ansicht mit drei Bereichen — Kopfzeile mit Ampel,
Raster aus elf Zonen, Fußzeile mit drei Befehlen. Zwei der drei Fußzeilenbefehle
erreichen ihre Ziele über eine Nachricht, weil die Szene keinen Zugriff auf den
Anwendungsdelegaten hat.

Jede Zone ist eine Schaltfläche, die eine Aktion auslöst und zugleich zwei Dinge anzeigt:
wohin das Fenster springt (als Miniaturbild) und mit welcher Taste man dasselbe erreicht.

## Seiten und Routen

Keine. Eine Menüleisten-Anwendung hat keine Navigation — siehe `docs/app-shell.md`.

| Fläche | Maß | Auslöser |
|---|---|---|
| Popover | 280 pt breit, Höhe aus dem Inhalt | Klick auf das Menüleistensymbol |

## Komponentenstruktur

```
MikaGridApp (Szene)
└── MenuBarExtra                      Beschriftung: Systemzeichen "square.grid.3x3"
    └── PopoverGridView               feste Breite 280 pt
        ├── headerView
        │   ├── Symbol (Markenfarbe) + Wortmarke
        │   └── Circle 8×8            grün / orange — nur Farbe (FB-03)
        ├── accessibilityWarning      nur wenn Berechtigung fehlt → Systemeinstellungen
        ├── Divider
        ├── snapGrid
        │   ├── Zeile 1: linke · rechte Hälfte
        │   ├── Zeile 2: obere · untere Hälfte
        │   ├── Zeile 3: oben links · oben rechts
        │   ├── Zeile 4: unten links · unten rechts
        │   └── Zeile 5: Maximieren · Zentrieren · Zurücksetzen
        ├── Divider
        └── footerView
            ├── „Preferences" → Nachricht → Delegat → Einstellungsfenster
            ├── „Updates"     → direkt am Aktualisierer (B08)
            └── „Quit"        → Anwendung beenden

SnapZoneButton                        eine Zone
├── Monitorumriss 40×26, Radius 2
├── highlightedZone                   Verzweigung über 11 Fälle — VON HAND (FB-01)
├── Beschriftung 9 pt
├── Kürzeltext 8 pt monospaced        aus der aktuellen Belegung (B03)
└── Hover-Zustand → Fläche in Markenfarbe, 15 % Deckkraft
```

## Datenmodell

Keines. Die Ansicht hält einen einzigen eigenen Zustand — ob der Mauszeiger über der
Zone steht. Alles andere wird gelesen:

| Angezeigt | Quelle | Aktualität |
|---|---|---|
| Berechtigungszustand | B05 | beim Erscheinen geprüft (FB-05) |
| Kürzel je Aktion | B03 | beim Aufbau gelesen |
| Beschriftung und Symbol | Aktions-Aufzählungstyp | fest |
| Zielfläche der Vorschau | **eigene Verzweigung**, nicht die Zielgeometrie | fest, teils falsch (FB-01) |

### Die Abweichung im Einzelnen

| Zone | Vorschau zeigt | Tatsächliches Ziel | Stimmt |
|---|---|---|---|
| Hälften, Viertel | genau halbe Kanten | genau halbe Kanten | ✅ |
| Maximieren | ganze Fläche | ganze Fläche | ✅ |
| **Zentrieren** | Innenabstand 4 pt auf 40×26 → **80 % × 69 %** | 66,7 % × 66,7 % | ❌ |
| Zurücksetzen | Pfeilsymbol | keine feste Fläche | sinnvoll |

## Zugriffsregeln

| Wer | Darf | Erzwungen durch |
|---|---|---|
| jeder Nutzer am Gerät | alle Zonen und Befehle bedienen | keine Beschränkung — es gibt keine Konten |
| die Ansicht | Zustände lesen, Aktionen auslösen | Verweis auf den zentralen Zustand |
| die Ansicht | Zustände **ändern** | nur mittelbar über die Verwalter |

## Missbrauchsschutz

Nicht anwendbar: keine Eingabefelder, keine Endpunkte, keine Kosten. Ein schneller
Klickverlauf reiht mehrere Snaps hintereinander ein; jeder ist durch die Zeitgrenzen aus
B01 begrenzt.

## Externe Dienste

Keine. Die Schaltfläche „Updates" löst B08 aus, das seinerseits GitHub anspricht.

## Erkennbare Entscheidungen

Die sieben tragenden stehen im Decision Log der Spezifikation. Ergänzend:

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 8 | Zonen als flache Schaltflächen | Standardstil | Der Standardstil würde die Miniaturvorschau in einen Rahmen zwängen |
| 9 | Hover ohne Animation | weiche Blende | Sofortige Rückmeldung; passt zum sprunghaften Verhalten der Snaps |
| 10 | Prüfung beim Erscheinen statt laufend | Beobachtung | Sparsam — eine im Hintergrund liegende Menüleisten-App soll nichts tun |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | Menüleisteneintrag + `LSUIElement` | |
| AK-02 | Aufbau der Popover-Ansicht | |
| AK-03 | Zonenschaltfläche → B01 | |
| AK-04 | Aufbau der Zone | Vorschau teils falsch — FB-01 |
| AK-05 | Lesen der aktuellen Belegung | |
| AK-06 | Hover-Zustand | |
| AK-07 | Kopfzeilenpunkt | nur Farbe — FB-03 |
| AK-08 | Warnbanner (bedingt) | |
| AK-09 | Nachricht an den Delegaten | |
| AK-10 | direkter Aufruf am Aktualisierer | |
| AK-11 | Beenden der Anwendung | |
| AK-12 ⚠ | **nichts** — es gibt keinen Schließbefehl | offen als OF-01 |
| AK-13 ⚠ | fester Innenabstand statt Zielgeometrie | offen als OF-02 |
| AK-14 ⚠ | Prüfung nur beim Erscheinen | deckungsgleich mit B05/OF-02 |
| AK-15 | Beschränkung auf eigene Zustände | |

Ohne Kriterium bleibt nichts. Umgekehrt fehlt in der Fußzeile ein Weg zum Über-Fenster,
den es bis 1.1.0 gab — kein Kriterium verletzt das, aber es macht 85 Zeilen unerreichbar
(FB-06).
