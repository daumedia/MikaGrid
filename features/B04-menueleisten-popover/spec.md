# B04 · Menüleisten-Popover — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1

> **Rückerfassung.** ⚠ markiert Verhalten, das zur Klärung vorliegt.

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
- **AK-12** ⚠ · Angenommen, eine Zone wurde angeklickt, dann bleibt das Popover
  **geöffnet**.
  *(So verhält sich der Code heute: Es gibt keinen Schließbefehl. Praktisch für mehrere
  Snaps hintereinander, unerwartet für den, der einen Menübefehl erwartet. Siehe OF-01.)*
- **AK-13** ⚠ · Angenommen, die Zone „Center" wird betrachtet, wenn ihre Vorschau mit der
  tatsächlichen Wirkung verglichen wird, dann zeigt die Vorschau eine **zu große** Fläche:
  rund 80 % der Breite und 69 % der Höhe statt der tatsächlichen zwei Drittel.
  *(Die Vorschau entsteht aus einem festen Innenabstand von 4 pt auf einer Fläche von
  40 × 26 pt, nicht aus der Zielgeometrie. Siehe OF-02.)*
- **AK-14** ⚠ · Angenommen, die Berechtigung wird erteilt, während das Popover offen ist,
  dann bleibt die Ampel orange, bis das Popover geschlossen und erneut geöffnet wird.
  *(Deckungsgleich mit B05/AK-11.)*

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

## Fehlbestand

- **FB-01 · Die Vorschau kennt die echte Zielgeometrie nicht.** `SnapZoneButton` baut
  alle elf Zielflächen als eigenen Verzweigungsblock aus Stapeln nach; maßgeblich ist
  aber `SnapAction.targetFrame`. **Folge:** AK-13. Die beiden Darstellungen können
  beliebig auseinanderlaufen, ohne dass es auffällt — und tun es bereits. Bemerkenswert:
  Die Landingpage rechnet dieselbe Zone korrekt mit zwei Dritteln (B10/AK-08).
- **FB-02 · Kein Zugang für Hilfstechnologien.** Keine Beschriftung, kein Hinweistext,
  keine Angabe des Zustands. **Folge:** Für VoiceOver sind elf Schaltflächen ohne
  brauchbare Ansage vorhanden. Die einzige Beschriftung ist 9-pt-Text.
- **FB-03 · Die Ampel ist allein farbcodiert.** Ein 8-pt-Punkt in Grün oder Orange, ohne
  Form- oder Textunterschied. **Folge:** Für Menschen mit Rot-Grün-Schwäche nicht
  unterscheidbar. Die Statuszeile im Einstellungsfenster macht es besser — dort gibt es
  Symbol **und** Text.
- **FB-04 · Kein Menüleistensymbol als Bilddatei.** Das Symbol ist ein Systemzeichen.
  `scripts/build.sh` sucht `MenubarIconTemplate.png` und `…@2x.png` in `Resources/` —
  **beide existieren nicht**, der Kopierschritt läuft bei jedem Bau ins Leere. **Folge:**
  Kein Schaden, aber toter Code im Bauskript und ein Hinweis darauf, dass hier einmal
  etwas anderes geplant war.
- **FB-05 · Die Zustandsprüfung hängt am Erscheinen.** Kein laufender Takt, keine
  Beobachtung. **Folge:** AK-14.
- **FB-06 · Kein Weg zum Über-Fenster.** Die Fußzeile führt „Preferences", „Updates" und
  „Quit". Bis 1.1.0 stand hier „About"; seither ist das gestaltete Über-Fenster
  unerreichbar. Siehe B07 und `docs/app-shell.md`.
- **FB-07 · Kein Test.** Die Zuordnung von Aktion zu Vorschaufläche ist reine Logik und
  ließe sich gegen `targetFrame` prüfen — genau der Vergleich, der FB-01 aufgedeckt hätte.

## Offene Fragen

- **OF-01** · Soll sich das Popover nach einem Zonenklick schließen (AK-12)? Dagegen
  spricht das schnelle Anordnen mehrerer Fenster, dafür die Erwartung an ein Menü. —
  *Betreiber.*
- **OF-02** · Soll die Vorschau aus `SnapAction.targetFrame` abgeleitet werden (AK-13,
  FB-01)? Behebt die Abweichung dauerhaft statt einmalig. — *Betreiber, empfohlen.*

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
