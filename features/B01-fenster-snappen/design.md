# B01 · Fenster snappen — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Ein Auslöser — Tastenkürzel oder Klick — nennt eine von elf Aktionen. Der Fenstermanager
ermittelt die Ziel-App, greift sich deren fokussiertes Fenster über die
Accessibility-API, liest dessen aktuellen Rahmen, bestimmt daraus den Bildschirm, lässt
die Aktion den Zielrahmen berechnen und schreibt ihn.

Das Schreiben ist der heikle Teil und alles andere als ein einzelner Aufruf: Größe,
Position, nochmals Größe — dann zurücklesen und bis zu zweimal nachkorrigieren, mit
Zeitgrenze und Stillstandserkennung. Rundherum werden zwei Fallen entschärft: die
Animation, die AppKit über `AXEnhancedUserInterface` einschaltet, und die blockierende
Ziel-App, die ohne Nachrichtengrenze die Menüleiste mitreißen würde.

## Einstiegspunkte

| Auslöser | Über | Gehört zu |
|---|---|---|
| ⌃⌥ + Taste | Carbon-Ereignisbehandlung → Rückruf | B03 |
| Klick auf eine Rasterzone | SwiftUI-Schaltfläche | B04 |

Beide münden in denselben einen Einstieg mit der Aktion als einzigem Argument.

## Komponentenstruktur

```
SnapAction                          enum, 11 Fälle, Sendable
├── label / systemImage             Beschriftung im Raster
├── hotkeyID (1…11)                 Zuordnung im Carbon-Rückruf
├── defaultBinding                  Standardkürzel (B03)
├── targetFrame(on:) -> CGRect?     Zielrahmen in AX-Koordinaten, nil bei restore
└── rect(l,t,r,b)                   baut aus GERUNDETEN KANTEN, nicht aus Breite/Höhe

WindowManager                       @MainActor
├── snapFrontmostWindow(to:)        der einzige Einstieg
├── targetPID()                     vorderste App, sonst zuletzt aktive fremde
├── observeAppActivation()          merkt sich fremde Aktivierungen
├── focusedWindow(of:)              kAXFocusedWindow, typgeprüft
├── frame(of:)                      Position + Größe, typgeprüft
├── isSettable(_:on:)               darf überhaupt geschrieben werden
├── screenForWindow(_:)             Bildschirm über den Mittelpunkt
├── windowKey(pid:window:)          "<PID>_<Titel>" → B02
├── applyFrame(_:to:of:)            Schreiben + Nachkorrektur
│   ├── enhancedUIEnabled / setEnhancedUI
│   └── write(size:) / write(position:)
└── Konstanten: Toleranz 2 pt · 3 Durchgänge · 0,25 s je Nachricht · 0,6 s gesamt

NSScreen.primaryHeight              Bildschirm am Ursprung (0,0) — nicht screens.first
CGRect.isNear(_:tolerance:)         kantenweiser Soll/Ist-Vergleich
```

## Ablauf eines Snaps

```
snapFrontmostWindow(action)
├── Berechtigung erteilt?                       nein → still zurück
├── Ziel-Prozess bestimmen                      keiner → still zurück
├── App-Element erzeugen, Nachrichtengrenze setzen
├── fokussiertes Fenster holen                  keins → still zurück
│   └── Nachrichtengrenze auch hier setzen      (gilt je Objekt!)
├── aktuellen Rahmen lesen                      nicht lesbar → still zurück
├── Schlüssel bilden  "<PID>_<Titel>"
├── restore?  → gespeicherten Rahmen anwenden, fertig            (B02)
├── Bildschirm über den Mittelpunkt bestimmen
├── Zielrahmen berechnen
├── aktuellen Rahmen sichern                    ← überschreibt frühere Sicherung (AK-15)
└── applyFrame
    ├── Position UND Größe setzbar?             nein → still zurück
    ├── EnhancedUI merken und ausschalten
    ├── defer: EnhancedUI wiederherstellen      ← läuft auf jedem Rückweg
    └── bis zu 3 Durchgänge
        ├── Größe → Position → Größe schreiben
        ├── zurücklesen
        ├── nahe genug (2 pt)?      → fertig
        ├── wie beim letzten Mal?   → Stillstand, aufgeben
        └── Zeit abgelaufen (0,6 s)? → aufgeben
```

## Zielgeometrie

Bezugsfläche ist der **nutzbare** Bereich des Bildschirms — ohne Menüleiste, ohne Dock.

| Aktion | Waagerecht | Senkrecht |
|---|---|---|
| Linke / rechte Hälfte | links–Mitte / Mitte–rechts | ganz |
| Obere / untere Hälfte | ganz | oben–Mitte / Mitte–unten |
| Vier Viertel | je halb | je halb |
| Maximieren | ganz | ganz |
| Zentriert | Einzug ⅙ je Seite → ⅔ | Einzug ⅙ je Seite → ⅔ |
| Zurücksetzen | kein Zielrahmen — kommt aus der Historie (B02) | |

### Zwei Umrechnungen, die leicht falsch gehen

**Ursprung.** Die Accessibility-API zählt von oben links, Cocoa von unten links. Die
Umrechnung braucht die Höhe des Bildschirms am globalen Ursprung `(0,0)` — **nicht** die
des ersten Bildschirms in der Liste, denn dessen Reihenfolge bestimmt die Anordnung in
den Systemeinstellungen.

**Rundung.** Gerundet werden die vier **Kanten**, nie Breite oder Höhe. Bei einem
nutzbaren Bereich von 1512,5 pt Breite ergäbe „Breite runden" zweimal 756 pt und damit
einen halben Punkt Lücke in der Mitte; „Kanten runden" ergibt eine gemeinsame Kante bei
756 und lückenlose Nachbarschaft. Genau das war einer der Fehler von 1.1.0.

## Datenhaltung

Keine. Der einzige geschriebene Zustand ist die zuletzt aktive fremde Prozesskennung im
Arbeitsspeicher; die Rahmenhistorie gehört zu B02.

## Zugriffsregeln

| Wer | Darf was | Erzwungen durch |
|---|---|---|
| Mika+Grid mit Berechtigung | Rahmen des fokussierten Fensters jeder App lesen und setzen | macOS TCC |
| Mika+Grid ohne Berechtigung | nichts | vorgeschaltete Prüfung **und** die API selbst |
| die Ziel-App | darf jeden Schreibvorgang beschneiden oder verweigern | Rückmessung erkennt es, gibt aber nach 3 Durchgängen auf |

Die dritte Zeile ist bemerkenswert: Die Ziel-App hat das letzte Wort. Der Fenstermanager
kann nur vorschlagen, prüfen und begrenzt beharren.

## Missbrauchsschutz

| Fläche | Grenze | Verhalten |
|---|---|---|
| einzelne AX-Nachricht | 0,25 s, je Objekt gesetzt | Aufruf schlägt fehl statt zu blockieren |
| ganzer Snap | 0,6 s | Abbruch nach dem laufenden Durchgang |
| Nachkorrektur | 3 Durchgänge | verhindert Endlosschleifen bei Mindestgrößen |
| Aufrufhäufigkeit | keine | jeder Aufruf ist lokal, synchron und kostenlos |

## Externe Dienste

Keine.

## Erkennbare Entscheidungen

Die tragenden acht stehen im Decision Log der Spezifikation. Ergänzend:

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 10 | `defer` für die Wiederherstellung von `AXEnhancedUserInterface` | am Ende der Methode | Es gibt sechs Rückwege aus `applyFrame`; nur `defer` erwischt alle. Bliebe die Einstellung aus, verlöre VoiceOver Funktionalität — bei einer App, die im Menü der Bedienungshilfen steht, wäre das besonders schlecht |
| 11 | `NSNumber(value:)` statt der CF-Konstante | `kCFBooleanTrue` | Die CF-Konstante ist unter strikter Nebenläufigkeit kein sicherer Zugriff; zur Laufzeit identisch |
| 12 | Beobachter auf App-Aktivierung statt Fensterliste | alle Fenster auflisten | Sparsam: eine Kennung statt einer Abfrage über alle Prozesse |
| 13 | Nur das fokussierte Fenster | Auswahl anbieten | Entspricht der Erwartung „das, was ich gerade benutze"; alles andere bräuchte eine Oberfläche |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01…AK-05 | `SnapAction.targetFrame` + `applyFrame` | ungetestet — FB-02 |
| AK-06 | Kantenrundung in `rect(_:_:_:_:)` | der Kern des Fixes von 1.1.1 |
| AK-07 | `screenForWindow` über den Mittelpunkt | Rückfall bei EC-01 |
| AK-08 | `targetPID` + Beobachter auf App-Aktivierung | |
| AK-09 | Schreibfolge Größe→Position→Größe | |
| AK-10 | Aus- und Wiedereinschalten von `AXEnhancedUserInterface` | |
| AK-11 | `AXUIElementSetMessagingTimeout` auf **beiden** Elementen + Zeitgrenze | |
| AK-12 | `isSettable` für Position und Größe | Vollbild unbelegt — FB-04 |
| AK-13 | Stillstandserkennung + Durchgangsgrenze | |
| AK-14 | `defer` in `applyFrame` | |
| AK-15 ⚠ | Sicherung **vor jedem** Snap, ohne Prüfung auf bereits gesnappt | offen als OF-01 |
| AK-16 ⚠ | leerer Rückfallwert vor der ersten fremden Aktivierung | offen als OF-02 |
| AK-17 | verwendete Attribute: Position, Größe, Titel | |
| AK-18 | Abwesenheit von Ausgabe und Netzzugriff | |
| AK-19 | vorgeschaltete Berechtigungsprüfung | |

Keine Zeile ohne Zuordnung. Ohne Kriterium bleibt nichts — jede Methode des
Fenstermanagers wird auf mindestens einem Pfad erreicht.
