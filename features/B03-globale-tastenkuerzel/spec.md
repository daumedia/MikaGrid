# B03 · Globale Tastenkürzel — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1 · Repariert in: v1.2.0

> **Rückerfassung, danach repariert.** Erfasst aus v1.1.1, überarbeitet in **v1.2.0**
> (2026-08-25). Die Kriterien beschreiben den Stand **nach** der Reparatur; was vorher
> anders war, steht in Klammern dabei. ⚠ markiert die Punkte, die **nicht** aus dem
> Repository heraus lösbar sind. *Behobener Fehlbestand* führt jede geschlossene Lücke mit
> ihrer Fundstelle — eine Rekonstruktion, die verschweigt, was falsch war, ist wertlos.

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
- **AK-11** · Angenommen, ein Kürzel ist bereits systemweit von einer anderen Anwendung
  belegt, wenn Mika+Grid es zu registrieren versucht, dann erscheint in den Einstellungen
  neben der Aktion ein Warndreieck und unter der Liste die Zeile „… already in use by
  another app and stays inactive".
  *(Bis 1.1.1 ging der Fehlschlag nur auf die Konsole, und die Einstellungen zeigten das
  Kürzel weiterhin als aktiv an — die Oberfläche behauptete etwas Falsches.)*
- **AK-12** · Angenommen, die Aufnahme läuft, wenn ⌘Q, ⌘W oder ein anderes reserviertes
  Systemkürzel gedrückt wird, dann wird es abgelehnt und es erscheint „… is reserved by
  macOS".
  *(Bis 1.1.1 wurde es übernommen — wer sich ⌘Q auf „Maximieren" legte, konnte kein
  Programm mehr beenden. Nachweis: `HotkeyBindingTests.reservedShortcutsAreRejected`.)*
- **AK-13** · Angenommen, ein Kürzelfeld befindet sich in Aufnahme, wenn das
  Einstellungsfenster geschlossen wird, dann endet die Aufnahme und der
  Tastatur-Beobachter wird abgemeldet.
  *(Bis 1.1.1 blieb er bestehen und schluckte weiterhin Tastendrücke; es fehlte ein
  `onDisappear`.)*

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

## Behobener Fehlbestand

- **FB-01 ✅ Fehlgeschlagene Registrierung blieb unsichtbar.**
  **Behoben:** `HotkeyManager.failedRegistrations` sammelt die betroffenen Aktionen; die
  Einstellungen zeigen sie je Zeile und als Sammelhinweis an.
- **FB-02 ✅ Fehlende Kürzel wurden nicht mit Standardwerten aufgefüllt.**
  **Behoben:** `loadBindings` beginnt mit der vollständigen Standardbelegung und
  überschreibt nur, was gespeichert ist. Eine künftig ergänzte Aktion hat damit sofort ein
  Kürzel. Nachweis: `HotkeyPersistenceTests.missingActionsAreBackfilled`.
- **FB-03 ✅ Keine Schemaversion.**
  **Behoben:** `hotkeyBindingsSchemaVersion` wird mitgeschrieben; ein Stand aus einer
  neueren Fassung wird verworfen statt halb gelesen. Nachweis:
  `futureSchemaFallsBackToDefaults`, `corruptDataYieldsDefaults`.
- **FB-04 ✅ Keine Prüfung gegen systemweite Belegungen.**
  **Behoben:** `HotkeyBinding.isReserved` mit einer Sperrliste (⌘Q, ⌘W, ⌘⇥, ⌘Leertaste,
  ⌘., ⌘⎋, ⌥⌘Q, ⌥⌘⎋). Ergänzt um die sichtbare Rückmeldung aus FB-01, wenn das System die
  Registrierung dennoch ablehnt.
- **FB-05 ✅ Der Tastatur-Beobachter wurde beim Verschwinden nicht abgemeldet.**
  **Behoben:** `onDisappear` im Kürzelfeld.
- **FB-06 ✅ Kein Test.**
  **Behoben:** `HotkeyTests` mit 16 Fällen — Anzeige, Sperrliste, Eindeutigkeit der
  Standardbelegungen und Kennzahlen, Laden, Auffüllen, Schemaversion, beschädigte Daten.
- **FB-07 ✅ `deinit` läuft praktisch nie.**
  **Behoben** im Sinne von geklärt: Das ist kein Fehler, sondern die Folge davon, dass der
  Verwalter so lange lebt wie die App. Die Aufräumlogik bleibt als Absicherung stehen; die
  Eigenschaften sind mit einem Kommentar versehen, warum sie `nonisolated(unsafe)` sein
  müssen (der Makro-Ausbau von `@Observable` lässt `nonisolated` dort nicht zu).

## Entschiedene Fragen

- **OF-01 ✅ Fehlgeschlagene Registrierung ist sichtbar** — Warndreieck an der Zeile und
  eine Sammelzeile darunter. Es war der wahrscheinlichste „warum geht das nicht"-Fall.
- **OF-02 ✅ Reservierte Systemkürzel sind gesperrt.** Eine kurze Sperrliste statt einer
  vollständigen: Sie deckt die Kombinationen ab, deren Verlust den Rechner unbedienbar
  macht, ohne dem Nutzer sinnvolle Belegungen zu verbieten.
- **OF-03 ✅ Der Beobachter wird beim Schließen abgemeldet.**

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
