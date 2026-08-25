# B03 · Globale Tastenkürzel — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1

> **Rückerfassung.** ⚠ markiert Verhalten, das zur Klärung vorliegt.

## Zweck

Elf Tastenkombinationen lösen die Snap-Aktionen aus, gleichgültig welche App gerade im
Vordergrund ist. Jede davon lässt sich in den Einstellungen neu belegen. Ohne dieses
Feature wäre Mika+Grid eine Maus-Anwendung — und damit langsamer als das Ziehen von Hand.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 | rekonstruiert | Ein Kürzel ist nur die Auslösung; die Wirkung liegt dort |

## User Stories

- **US-01** · Als Nutzer möchte ich Fenster ordnen, ohne die Hand von der Tastatur zu
  nehmen, damit es schneller geht als von Hand zu ziehen.
- **US-02** · Als Nutzer möchte ich Kürzel ändern, die mit meinen anderen Programmen
  kollidieren, damit ich nicht zwischen zwei Werkzeugen wählen muss.
- **US-03** · Als Nutzer möchte ich gewarnt werden, wenn ich ein Kürzel doppelt vergebe,
  damit nicht heimlich eine Aktion unerreichbar wird.

## Nicht im Scope

- **Was beim Auslösen geschieht** — das ist B01 und B02.
- **Kürzel für Nicht-Snap-Funktionen** (Popover öffnen, Einstellungen). Gibt es nicht;
  siehe `docs/app-shell.md`, Fehlbestand.

## Akzeptanzkriterien

- **AK-01** · Angenommen, die App läuft und die Berechtigung liegt vor, wenn in einer
  beliebigen anderen App ⌃⌥← gedrückt wird, dann wird deren Fenster gesnappt — ohne dass
  Mika+Grid in den Vordergrund kommt.
- **AK-02** · Angenommen, die App startet zum ersten Mal, wenn die Kürzel geprüft werden,
  dann gelten die elf Standardbelegungen auf ⌃⌥ mit Pfeiltasten, U/I/J/K, Return, C und
  Rückschritt.
- **AK-03** · Angenommen, die Einstellungen sind offen, wenn im Bereich „Shortcuts" ein
  Kürzelfeld angeklickt wird, dann steht dort „Press shortcut…" und die nächste
  Tastenkombination wird übernommen.
- **AK-04** · Angenommen, die Aufnahme läuft, wenn Esc gedrückt wird, dann bricht sie ab
  und das bisherige Kürzel bleibt.
- **AK-05** · Angenommen, die Aufnahme läuft, wenn eine Kombination **ohne** Befehls-
  und ohne Steuerungstaste gedrückt wird, dann wird sie nicht übernommen und die Aufnahme
  läuft weiter.
- **AK-06** · Angenommen, ein Kürzel ist bereits einer anderen Aktion zugewiesen, wenn es
  aufgenommen wird, dann erscheint in Rot „Conflict with \"<Aktion>\"" und die Zuweisung
  unterbleibt.
- **AK-07** · Angenommen, ein Kürzel wurde geändert, wenn die App neu gestartet wird,
  dann gilt weiterhin das geänderte.
- **AK-08** · Angenommen, Kürzel wurden geändert, wenn „Restore Defaults" gedrückt wird,
  dann gelten wieder alle elf Standardbelegungen — sofort, ohne Neustart.
- **AK-09** · Angenommen, ein Kürzel wurde geändert, wenn das Popover geöffnet wird, dann
  zeigt die zugehörige Rasterzone die neue Kombination an.
- **AK-10** · Angenommen, die Kürzel wurden mehrfach hintereinander geändert, wenn danach
  eines gedrückt wird, dann löst es **genau einmal** aus.
  *(Der Fehler von 1.1.0: Bei jeder Änderung wurde ein weiterer Ereignisbehandler
  installiert, ohne den alten zu entfernen — ein Tastendruck feuerte danach mehrfach und
  überschrieb dabei die Wiederherstellungs-Historie mit dem bereits gesnappten Rahmen.)*
- **AK-11** ⚠ · Angenommen, ein Kürzel ist bereits systemweit von einer anderen
  Anwendung belegt, wenn Mika+Grid es zu registrieren versucht, dann schlägt das fehl
  und **der Nutzer erfährt nichts davon** — die Aktion bleibt stumm, die Einstellungen
  zeigen das Kürzel weiterhin an.
  *(So verhält sich der Code heute: Der Fehlschlag wird auf die Konsole geschrieben und
  sonst nirgends. Siehe OF-01.)*
- **AK-12** ⚠ · Angenommen, die Aufnahme läuft, wenn ⌘Q, ⌘W oder ein anderes reserviertes
  Systemkürzel gedrückt wird, dann wird es als Snap-Kürzel übernommen.
  *(Geprüft wird nur, ob Befehls- **oder** Steuerungstaste beteiligt ist; eine Liste
  geschützter Kombinationen gibt es nicht. Siehe OF-02.)*
- **AK-13** ⚠ · Angenommen, ein Kürzelfeld befindet sich in Aufnahme, wenn das
  Einstellungsfenster geschlossen wird, dann bleibt der Tastatur-Beobachter aktiv und
  schluckt weiterhin Tastendrücke in Fenstern von Mika+Grid.
  *(Der Beobachter wird nur beim Wechsel von „Aufnahme" auf „keine Aufnahme" abgemeldet,
  nicht beim Verschwinden der Ansicht. Siehe OF-03.)*

### Datenschutz und Missbrauchsschutz

Geprüft gegen `~/.claude/sdd/sicherheit.md`.

- **AK-14** · Angenommen, die App läuft, wenn geprüft wird, welche Tastendrücke sie
  mitbekommt, dann sind es ausschließlich die elf registrierten Kombinationen — Carbon
  meldet nur diese. **Es findet kein Mitschnitt der Tastatur statt.**
- **AK-15** · Angenommen, eine Kürzelaufnahme läuft, wenn geprüft wird, welche
  Tastendrücke der Beobachter sieht, dann nur solche, die an Fenster von Mika+Grid
  gehen — nicht die anderer Programme.
- **AK-16** · Angenommen, Kürzel wurden geändert, wenn die Einstellungsdatei gelesen
  wird, dann enthält sie ausschließlich Tastencodes und Umschaltmasken — keine Texte,
  keine Zeitstempel, nichts Personenbezogenes.
- **Rate Limits, externe Dienste, Rollen, Geheimnisse:** treffen nicht zu.

## Edge Cases

- **EC-01** · Zwei Aktionen bekommen dasselbe Kürzel → wird beim Aufnehmen verhindert
  (AK-06). Über eine von Hand bearbeitete Einstellungsdatei bliebe es möglich; dann
  gewinnt bei der Registrierung die zuletzt eingetragene.
- **EC-02** · Die gespeicherten Kürzel lassen sich nicht lesen (Formatfehler) → es gelten
  stillschweigend wieder die Standardbelegungen; alle Anpassungen sind ohne Meldung weg.
- **EC-03** · Die gespeicherten Kürzel enthalten eine unbekannte Aktion (etwa nach einer
  Umbenennung) → der Eintrag wird übersprungen.
- **EC-04** · Die gespeicherten Kürzel enthalten **nicht alle** Aktionen → die fehlenden
  bekommen **keinen** Standardwert nachgezogen und werden gar nicht erst registriert.
  Sie sind per Tastatur tot, bis „Restore Defaults" gedrückt wird. Siehe FB-02.
- **EC-05** · Kürzel wird gedrückt, während die App noch startet → der Behandler ist
  bereits installiert; der Aufruf wird auf den Hauptstrang gereiht.
- **EC-06** · Kürzel wird sehr schnell wiederholt gedrückt → jeder Druck reiht einen
  eigenen Snap ein; sie laufen nacheinander. Bei gedrückt gehaltener Taste
  wiederholt macOS nicht — Carbon meldet nur den ersten Druck.

## Fehlbestand

- **FB-01 · Fehlgeschlagene Registrierung bleibt unsichtbar.**
  `HotkeyManager.registerHotkeys()`, Zweig `else` — der Fehlschlag geht auf die Konsole.
  **Folge:** AK-11. Ein Kürzel, das eine andere Anwendung bereits hält, wirkt für den
  Nutzer wie ein Fehler in Mika+Grid. Die Einstellungen zeigen es weiterhin an, als wäre
  es aktiv — die Oberfläche behauptet also etwas Falsches.
- **FB-02 · Fehlende Kürzel werden nicht mit Standardwerten aufgefüllt.**
  `HotkeyManager.init`, Ladezweig. **Folge:** EC-04. Der Fall tritt zwangsläufig ein,
  sobald eine zwölfte Aktion hinzukommt: Alle Bestandsnutzer hätten sie ohne Kürzel.
  Derselbe Befund steht in `docs/datenmodell.md`.
- **FB-03 · Keine Schemaversion für die gespeicherten Kürzel.** **Folge:** EC-02 — jede
  künftige Änderung an der Struktur verwirft die Belegung aller Nutzer stillschweigend.
- **FB-04 · Keine Prüfung gegen systemweite Belegungen.** Weder beim Aufnehmen noch beim
  Registrieren wird ermittelt, ob eine Kombination bereits vergeben oder vom System
  reserviert ist. **Folge:** AK-11 und AK-12 zusammen — der Nutzer kann sich ⌘Q auf
  „Maximieren" legen und damit das Beenden aller Programme lahmlegen.
- **FB-05 · Der Tastatur-Beobachter wird beim Verschwinden der Ansicht nicht abgemeldet.**
  `ShortcutRecorderView` reagiert nur auf den Zustandswechsel, nicht auf `onDisappear`.
  **Folge:** AK-13.
- **FB-06 · Kein Test.** Weder das Laden und Speichern der Kürzel noch die
  Konflikterkennung ist abgesichert. Beides ist reine Logik ohne Systemabhängigkeit —
  und AK-10 beschreibt genau die Art Fehler, die ein Test verhindert hätte.
- **FB-07 · `deinit` läuft praktisch nie.** Der Kürzelverwalter lebt in `AppState` und
  damit so lange wie die App. Die Aufräumlogik im `deinit` ist damit ungenutzt — nicht
  falsch, aber auch nicht geprüft.

## Offene Fragen

- **OF-01** · Soll eine fehlgeschlagene Registrierung sichtbar werden (FB-01)? Etwa als
  rote Markierung am betroffenen Kürzelfeld. — *Betreiber, empfohlen: es ist der
  wahrscheinlichste „warum geht das nicht"-Fall.*
- **OF-02** · Sollen reservierte Systemkürzel gesperrt werden (AK-12, FB-04)? Eine
  Sperrliste (⌘Q, ⌘W, ⌘Tab, ⌘Leertaste …) wäre eine kleine Ergänzung mit großer
  Schutzwirkung. — *Betreiber.*
- **OF-03** · Soll der Beobachter beim Schließen des Fensters abgemeldet werden (AK-13)?
  Rein technisch eindeutig ja; als Bestandsverhalten hier nur vermerkt. — *Betreiber.*

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie systemweite Kürzel | Carbon `RegisterEventHotKey` | Die einzige Möglichkeit ohne Eingabeüberwachung. Ein `CGEventTap` bräuchte eine weitere, weitreichendere Berechtigung — und wäre ein echter Tastaturmitschnitt |
| 2 | Kennung „MKGD" | eigene Signatur | Grenzt die Kürzel gegenüber MikaScreenSnap („MSNS") ab, das dasselbe Muster benutzt |
| 3 | Ereignisbehandler genau einmal installieren | bei jeder Änderung neu | Der Fehler von 1.1.0. Der Behandler ist zustandslos und verteilt über die Kennung — eine Installation genügt für alle Neuregistrierungen |
| 4 | Statische Instanzreferenz | Kontextzeiger von Carbon nutzen | Der Rückruf ist eine C-Funktion ohne Swift-Kontext; die statische Referenz ist die einfachste Brücke |
| 5 | Aufnahme nur mit Befehls- oder Steuerungstaste | beliebige Kombinationen | Verhindert, dass eine einzelne Buchstabentaste systemweit gekapert wird. Reserviert Systemkürzel schützt es aber nicht (FB-04) |
| 6 | Konfliktprüfung nur innerhalb der App | zusätzlich systemweit | Systemweit gibt es keine öffentliche Abfrage. Der Rückgabewert der Registrierung wäre der verfügbare Ersatz — er wird verworfen (FB-01) |
| 7 | Speichern erst bei Änderung | Standardwerte sofort schreiben | Sparsam; die Einstellungsdatei bleibt leer, solange nichts geändert wurde. Bestätigt am laufenden System |
