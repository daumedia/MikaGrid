# B04 · Menüleisten-Popover — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1 · Repariert in: v1.2.0

> **Rückerfassung, danach repariert.** Erfasst aus v1.1.1, überarbeitet in **v1.2.0**
> (2026-08-25). Die Kriterien beschreiben den Stand **nach** der Reparatur; was vorher
> anders war, steht in Klammern dabei. ⚠ markiert die Punkte, die **nicht** aus dem
> Repository heraus lösbar sind. *Behobener Fehlbestand* führt jede geschlossene Lücke mit
> ihrer Fundstelle — eine Rekonstruktion, die verschweigt, was falsch war, ist wertlos.

## Zweck

Ein Klick auf das Rastersymbol in der Menüleiste öffnet ein Fenster mit elf anklickbaren
Zonen. Jede zeigt als kleine Monitorvorschau, wohin das Fenster springt, und darunter das
zugehörige Kürzel. Es ist zugleich die Bedienung für Mausnutzer und die Lernhilfe, die
die Kürzel beibringt.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 | rekonstruiert | Jeder Zonenklick löst einen Snap aus |
| B03 | rekonstruiert | Die angezeigten Kürzel stammen aus der aktuellen Belegung |
| B05 | rekonstruiert | Ampel und Warnbanner zeigen den Berechtigungszustand |

## User Stories

- **US-01** · Als neuer Nutzer möchte ich sehen, was die App kann, ohne Kürzel auswendig
  zu lernen.
- **US-02** · Als Nutzer möchte ich die Kürzel nebenbei lernen, damit ich das Popover
  bald nicht mehr brauche.
- **US-03** · Als Nutzer möchte ich sofort erkennen, ob die App einsatzbereit ist.

## Nicht im Scope

- **Was ein Klick bewirkt** — B01, B02.
- **Kürzel ändern** — B03, im Einstellungsfenster.
- **Ein Dock-Symbol oder Hauptfenster.** Die App ist als reine Menüleisten-Anwendung
  angelegt.

## Akzeptanzkriterien

- **AK-01** · Angenommen, die App läuft, wenn die Menüleiste betrachtet wird, dann steht
  dort ein Rastersymbol — und **kein** Eintrag im Dock und keiner im Programmwechsler.
- **AK-02** · Angenommen, das Symbol wird angeklickt, dann öffnet sich ein 280 pt breites
  Fenster mit Kopfzeile, Raster und Fußzeile.
- **AK-03** · Angenommen, das Popover ist offen, wenn eine Zone angeklickt wird, dann
  wird das Fenster der zuvor aktiven App entsprechend gesnappt.
- **AK-04** · Angenommen, das Popover ist offen, wenn eine Zone betrachtet wird, dann
  zeigt sie einen Monitorumriss mit eingefärbter Zielfläche, den Namen der Aktion und
  das aktuell zugewiesene Kürzel.
- **AK-05** · Angenommen, ein Kürzel wurde in den Einstellungen geändert, wenn das
  Popover geöffnet wird, dann steht dort das neue.
- **AK-06** · Angenommen, der Mauszeiger fährt über eine Zone, dann hinterlegt sie sich
  mit der Markenfarbe und die Zielfläche färbt sich kräftiger.
- **AK-07** · Angenommen, die Berechtigung liegt vor, wenn das Popover geöffnet wird,
  dann ist der Punkt in der Kopfzeile grün und es erscheint kein Warnbanner.
- **AK-08** · Angenommen, die Berechtigung fehlt, dann ist der Punkt orange, das
  Warnbanner erscheint und führt bei einem Klick in die Systemeinstellungen.
- **AK-09** · Angenommen, das Popover ist offen, wenn „Preferences" angeklickt wird, dann
  öffnet sich das Einstellungsfenster im Vordergrund.
- **AK-10** · Angenommen dasselbe, wenn „Updates" angeklickt wird, dann startet eine
  Update-Prüfung.
- **AK-11** · Angenommen dasselbe, wenn „Quit" angeklickt wird, dann endet die App.
- **AK-12** · Angenommen, eine Zone wurde angeklickt, dann bleibt das Popover geöffnet.
  *(Bewusst so: Das Popover ist für mehrere Snaps hintereinander gedacht, und die
  Zielanwendung bleibt dabei durchgehend die richtige. Siehe OF-01.)*
- **AK-13** · Angenommen, die Zone „Center" wird betrachtet, wenn ihre Vorschau mit der
  tatsächlichen Wirkung verglichen wird, dann zeigt sie zwei Drittel in Breite und Höhe.
  *(Bis 1.1.1 rund 80 % × 69 %, weil die Vorschau von Hand nachgebaut war. Seit 1.2.0 wird
  sie aus `SnapAction.previewRect` abgeleitet. Nachweis:
  `SnapPreviewTests.centerPreviewIsTwoThirds`.)*
- **AK-14** · Angenommen, die Berechtigung wird erteilt, während das Popover offen ist,
  dann wechselt die Anzeige binnen etwa einer Sekunde auf grün, ohne dass das Popover
  geschlossen werden muss.
  *(Seit 1.2.0 läuft die Abfrage, solange das Popover sichtbar ist.)*

### Datenschutz und Missbrauchsschutz

- **AK-15** · Angenommen, das Popover ist offen, wenn geprüft wird, was es anzeigt, dann
  sind es ausschließlich Zustände der eigenen App — kein Fenstertitel, kein Name einer
  fremden Anwendung, keine Vorschau fremder Inhalte.
- **Personenbezogene Daten, Rollen, Rate Limits, externe Dienste, Geheimnisse:** treffen
  nicht zu — reine Darstellung ohne Eingabe und ohne Netzzugriff.

## Edge Cases

- **EC-01** · Kürzelverwalter noch nicht aufgebaut → die Zone zeigt keinen Kürzeltext,
  der Rest bleibt bedienbar.
- **EC-02** · Fenstermanager noch nicht aufgebaut → der Klick verpufft folgenlos.
- **EC-03** · Menüleiste ist voll (viele Symbole, schmales Gerät) → macOS blendet das
  Symbol aus; die App ist dann nur noch über Kürzel erreichbar. Nicht behandelt.
- **EC-04** · Heller Systemmodus → Popover und Einstellungen erscheinen hell, Onboarding
  und Über-Fenster bleiben dunkel. Siehe `docs/design-system.md`.

## Behobener Fehlbestand

- **FB-01 ✅ Die Vorschau kannte die echte Zielgeometrie nicht.**
  **Behoben:** `SnapAction.previewRect` leitet die Fläche aus derselben Rechnung ab wie
  `targetFrame`; die Verzweigung über elf Fälle in `SnapZoneButton` ist entfallen.
  Nachweis: `SnapPreviewTests.previewMatchesTarget` vergleicht beide Seiten für alle
  Aktionen. Ein Test dieser Reihe deckte während der Reparatur einen Rundungsfehler in der
  neuen Ableitung auf.
- **FB-02 ✅ Kein Zugang für Hilfstechnologien.**
  **Behoben:** Jede Zone trägt Beschriftung und Hinweistext samt Kürzel, das Raster ist als
  Gruppe ausgewiesen, die Statusanzeige und die Fußzeilenbefehle sind beschriftet.
- **FB-03 ✅ Die Ampel war allein farbcodiert.**
  **Behoben:** Häkchen bzw. Warndreieck **und** Farbe — bei Rot-Grün-Schwäche lesbar.
- **FB-04 ✅ Kein Menüleistensymbol als Bilddatei.**
  **Behoben:** Der ins Leere laufende Kopierschritt ist aus `scripts/build.sh` entfernt.
  Das Systemzeichen bleibt und passt sich hell/dunkel von selbst an.
- **FB-05 ✅ Die Zustandsprüfung hing am Erscheinen.**
  **Behoben:** Das Popover meldet einen Abfragebedarf an, solange es sichtbar ist.
- **FB-06 ✅ Kein Weg zum Über-Fenster.**
  **Behoben:** Die Fußzeile führt wieder „About"; zusätzlich gibt es den Eintrag im
  Einstellungsbereich „About".
- **FB-07 ✅ Kein Test.**
  **Behoben:** `SnapPreviewTests` prüft die Vorschau gegen die Zielgeometrie.

## Entschiedene Fragen

- **OF-01 ✅ Das Popover bleibt nach einem Zonenklick offen.** Bewusst beibehalten: Wer
  drei Fenster nacheinander anordnet, will nicht dreimal das Menü öffnen — und die
  Zielanwendung bleibt dabei durchgehend die zuletzt aktive fremde. Der Marker ist damit
  aufgelöst, nicht weggelassen.
- **OF-02 ✅ Die Vorschau wird aus `SnapAction.previewRect` abgeleitet.** Damit können
  Vorschau und Wirkung nicht mehr auseinanderlaufen — und ein Test hält es fest.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Darstellungsart | `MenuBarExtra` im Fenstermodus | Erlaubt beliebige Ansichten statt eines Textmenüs — Voraussetzung für das Raster |
| 2 | Kein Dock-Symbol | `LSUIElement` | Ein Werkzeug, das den ganzen Tag läuft, soll keinen Platz im Dock belegen |
| 3 | Feste Breite 280 pt | mitwachsend | Vorhersehbare Anordnung der Zonen |
| 4 | Kürzel an jeder Zone | nur Beschriftungen | Macht das Popover zur Lernhilfe — der Nutzer soll es bald nicht mehr brauchen |
| 5 | Vorschau von Hand nachgebaut | aus der Zielgeometrie ableiten | **Grund nicht erkennbar.** Vermutlich schneller geschrieben; die Folge steht in FB-01 |
| 6 | Systemzeichen als Menüleistensymbol | eigenes Schablonenbild | Passt sich hell/dunkel automatisch an. Das Bauskript erwartet allerdings noch das Bild (FB-04) |
| 7 | Nachrichtenweitergabe statt direktem Zugriff | Verweis auf den Delegaten | Die Ansicht ist eine SwiftUI-Szene ohne Zugriff auf den Delegaten |
