# B07 · Einstellungsfenster — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1

> **Rückerfassung.** ⚠ markiert Verhalten, das zur Klärung vorliegt.

## Zweck

Ein Fenster mit drei Bereichen bündelt alles, was sich einstellen lässt: Start bei der
Anmeldung und Updates unter „Allgemein", die elf Kürzel unter „Shortcuts", sowie
Versionsangabe, erneutes Onboarding und das Zurücksetzen aller Einstellungen unter
„About".

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B03 | rekonstruiert | Der Kürzelbereich bearbeitet die Belegung |
| B05 | rekonstruiert | „Allgemein" zeigt den Berechtigungszustand |
| B08 | rekonstruiert | „Allgemein" steuert die Update-Prüfung |

## User Stories

- **US-01** · Als Nutzer möchte ich einstellen, dass die App mit dem Rechner startet.
- **US-02** · Als Nutzer möchte ich sehen, ob die Berechtigung vorliegt, und sie
  gegebenenfalls nachreichen.
- **US-03** · Als Nutzer möchte ich alle Einstellungen zurücksetzen können, wenn ich mich
  verkonfiguriert habe.

## Nicht im Scope

- **Kürzelverwaltung im Einzelnen** — B03.
- **Update-Mechanik** — B08.
- **Snap-Verhalten einstellen.** Es gibt keine Einstellungen dafür; der Schalter für
  Snap-Animationen wurde in 1.1.1 entfernt, weil ihn kein Code las.

## Akzeptanzkriterien

- **AK-01** · Angenommen, im Popover wird „Preferences" angeklickt, dann öffnet sich ein
  580 × 420 pt großes Fenster mit Seitenleiste und Inhaltsbereich, im Vordergrund.
- **AK-02** · Angenommen, das Fenster ist offen, dann führt die Seitenleiste genau drei
  Einträge: General, Shortcuts, About.
- **AK-03** · Angenommen, das Fenster ist bereits offen, wenn „Preferences" erneut
  angeklickt wird, dann wird es in den Vordergrund geholt statt ein zweites zu öffnen.
- **AK-04** · Angenommen, „Allgemein" ist sichtbar, dann zeigt es den tatsächlichen
  Zustand des Anmeldeobjekts — nicht einen gespeicherten Wunschwert.
- **AK-05** · Angenommen, der Anmeldeschalter wird umgelegt, dann wird das Anmeldeobjekt
  entsprechend registriert oder entfernt.
- **AK-06** · Angenommen, „Allgemein" ist sichtbar, dann zeigt es den Berechtigungszustand
  mit Symbol **und** Text, bei fehlender Berechtigung zusätzlich „Open Settings".
- **AK-07** · Angenommen, „Allgemein" ist sichtbar, dann bietet es einen Schalter für die
  automatische Update-Prüfung, den Zeitpunkt der letzten Prüfung und „Check Now".
- **AK-08** · Angenommen, „About" ist sichtbar, dann zeigt es Symbol, Name, die Version
  aus dem Bundle und den Hinweis auf das Mika+-Ökosystem.
- **AK-09** · Angenommen, „About" ist sichtbar, wenn „Show Onboarding Again" gedrückt
  wird, dann erscheint das Onboarding erneut.
- **AK-10** · Angenommen, „Reset All Settings" wird gedrückt, dann erscheint zuerst eine
  Rückfrage mit „Cancel" und „Reset".
- **AK-11** · Angenommen, die Rückfrage wird bestätigt, dann werden alle gespeicherten
  Schlüssel gelöscht, das Anmeldeobjekt entfernt und die elf Standardkürzel sofort wieder
  angemeldet — ohne Neustart.
- **AK-12** · Angenommen, das Fenster wird geschlossen und erneut geöffnet, dann steht die
  Auswahl wieder auf „General".
- **AK-13** ⚠ · Angenommen, „Reset All Settings" wurde bestätigt, wenn die App neu
  gestartet wird, dann erscheint das Onboarding **nicht** erneut.
  *(So verhält sich der Code heute: Beim Zurücksetzen wird das Abschlusskennzeichen
  ausdrücklich wieder auf „abgeschlossen" gesetzt, nicht gelöscht. „Alle Einstellungen
  zurücksetzen" führt also nicht in den Auslieferungszustand. Siehe OF-01.)*
- **AK-14** ⚠ · Angenommen, das Einrichten des Anmeldeobjekts schlägt fehl, dann bleibt
  der Schalter auf „an" stehen.
  *(Der Fehler wird abgefangen und auf die Konsole geschrieben; die Anzeige wird nicht
  zurückgesetzt. Siehe OF-02.)*
- **AK-15** ⚠ · Angenommen, ein Nutzer sucht das gestaltete Über-Fenster, dann findet er
  keinen Weg dorthin.
  *(Die Nachricht, die es öffnen würde, wird von keiner Stelle gesendet — siehe
  `docs/app-shell.md`. Erreichbar ist nur der Bereich „About" im Einstellungsfenster.
  Siehe OF-03.)*

### Datenschutz und Missbrauchsschutz

- **AK-16** · Angenommen, „Reset All Settings" wurde bestätigt, wenn die
  Einstellungsdatei geprüft wird, dann sind die vier bekannten Schlüssel entfernt.
- **AK-17** ⚠ · Angenommen dasselbe, wenn die Einstellungsdatei geprüft wird, dann sind
  die **Sparkle-Schlüssel weiterhin vorhanden** — Prüfintervall, Zeitpunkt der letzten
  Prüfung und die automatische Installation bleiben unangetastet.
  *(Die Löschliste nennt nur die vier eigenen Schlüssel. Siehe OF-04.)*
- **Weitere Punkte des Katalogs:** keine Konten, keine Rollen, keine Endpunkte, keine
  Geheimnisse.

## Edge Cases

- **EC-01** · Anmeldeobjekt wird außerhalb der App entfernt → beim nächsten Anzeigen von
  „Allgemein" wird der Zustand neu gelesen; die Anzeige stimmt wieder.
- **EC-02** · Zurücksetzen, während der Kürzelbereich sichtbar ist → die Arbeitskopie der
  Ansicht wird beim Anzeigen geladen und zeigt bis zum erneuten Öffnen die alten Werte.
- **EC-03** · Beim Anzeigen von „Allgemein" wird der Schalter auf den Systemzustand
  gesetzt; die Zustandsänderung löst denselben Vorgang erneut aus (Registrieren eines
  bereits registrierten Objekts). Folgenlos, aber überflüssig.
- **EC-04** · Fenster wird geschlossen, während ein Kürzel aufgenommen wird → der
  Tastatur-Beobachter bleibt bestehen (B03/FB-05).

## Fehlbestand

- **FB-01 · Das Zurücksetzen führt nicht in den Auslieferungszustand.**
  `AppPreferences.resetAllPreferences()` setzt das Abschlusskennzeichen ausdrücklich
  wieder auf „abgeschlossen". **Folge:** AK-13. Ob beabsichtigt (der Nutzer kennt die App
  bereits) oder ein Versehen, ist aus dem Code nicht ablesbar — die Löschung des
  Schlüssels unmittelbar davor spricht eher für ein Versehen.
- **FB-02 · Die Sparkle-Einstellungen werden nicht zurückgesetzt.** Dieselbe Stelle.
  **Folge:** AK-17. Insbesondere bleibt die unbeaufsichtigte Installation aktiv, die der
  Nutzer über die Oberfläche ohnehin nicht abschalten kann (B08/FB-05).
- **FB-03 · Fehlschläge beim Anmeldeobjekt bleiben unsichtbar.**
  `LaunchAtLoginManager.setEnabled` fängt den Fehler ab und schreibt ihn auf die Konsole.
  **Folge:** AK-14 — die Oberfläche behauptet einen Zustand, den das System nicht hat.
- **FB-04 · Das Über-Fenster ist nicht erreichbar.** **Folge:** AK-15; 85 Zeilen toter
  Code.
- **FB-05 · Das Zurücksetzen erzeugt einen eigenen Anmeldeverwalter.** Statt den
  vorhandenen aus dem zentralen Zustand zu benutzen, wird an dieser Stelle ein neuer
  angelegt. Funktioniert, weil der Verwalter zustandslos ist — aber es ist ein Muster,
  das beim nächsten Verwalter mit Zustand fehlschlägt.
- **FB-06 · Fenstermaße sind doppelt festgelegt** — im Fenster und in der Ansicht. Wird
  nur eines geändert, wird der Inhalt beschnitten oder gepolstert. Gilt ebenso für B06.
- **FB-07 · Kein Standardkürzel für die Einstellungen.** Ohne Programmmenü gibt es kein
  ⌘, — siehe `docs/app-shell.md`.
- **FB-08 · Kein Test.** Insbesondere das Zurücksetzen ist reine Zustandslogik und wäre
  vollständig prüfbar — es ist zugleich die Stelle mit den meisten Befunden.

## Offene Fragen

- **OF-01** · Soll „Reset All Settings" das Onboarting erneut zeigen (AK-13, FB-01)? —
  *Betreiber.*
- **OF-02** · Soll ein Fehlschlag beim Anmeldeobjekt sichtbar werden (AK-14, FB-03)? —
  *Betreiber.*
- **OF-03** · Soll das Über-Fenster wieder erreichbar werden — oder ersatzlos entfallen
  (AK-15, FB-04)? Beides ist vertretbar; der heutige Zwischenzustand ist es nicht. —
  *Betreiber, empfohlen: entscheiden statt liegen lassen.*
- **OF-04** · Soll das Zurücksetzen auch die Sparkle-Einstellungen umfassen (AK-17,
  FB-02)? — *Betreiber.*

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Aufbau | Seitenleiste mit Inhaltsbereich | Entspricht den Systemeinstellungen ab Ventura |
| 2 | Fensterhalter mit Wiederverwendung | jedes Mal neu | Verhindert zwei Einstellungsfenster nebeneinander |
| 3 | Anmeldezustand aus dem System lesen | in den Einstellungen spiegeln | Das System ist die Wahrheit; ein Spiegel liefe auseinander |
| 4 | Rückfrage vor dem Zurücksetzen | sofort ausführen | Der Vorgang ist nicht umkehrbar |
| 5 | Kürzel nach dem Zurücksetzen sofort neu anmelden | Neustart verlangen | Sonst hätte der Nutzer bis zum Neustart gar keine Kürzel |
| 6 | Verwaisten Schlüssel weiter löschen | aus der Liste entfernen | Räumt Altbestände auf — richtig und ausdrücklich kommentiert |
