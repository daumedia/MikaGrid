# B07 · Einstellungsfenster — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1 · Repariert in: v1.2.0

> **Rückerfassung, danach repariert.** Erfasst aus v1.1.1, überarbeitet in **v1.2.0**
> (2026-08-25). Die Kriterien beschreiben den Stand **nach** der Reparatur; was vorher
> anders war, steht in Klammern dabei. ⚠ markiert die Punkte, die **nicht** aus dem
> Repository heraus lösbar sind. *Behobener Fehlbestand* führt jede geschlossene Lücke mit
> ihrer Fundstelle — eine Rekonstruktion, die verschweigt, was falsch war, ist wertlos.

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
- **AK-13** · Angenommen, „Reset All Settings" wurde bestätigt, wenn die App neu gestartet
  wird, dann erscheint das Onboarding erneut.
  *(Bis 1.1.1 setzte das Zurücksetzen das Abschlusskennzeichen unmittelbar nach dem Löschen
  wieder auf „abgeschlossen" — es führte gerade nicht in den Auslieferungszustand.)*
- **AK-14** · Angenommen, das Einrichten des Anmeldeobjekts schlägt fehl, dann springt der
  Schalter zurück und darunter erscheint „Login item failed: …".
  *(Bis 1.1.1 ging der Fehler nur auf die Konsole, und der Schalter behauptete einen
  Zustand, den das System nicht hatte.)*
- **AK-15** · Angenommen, ein Nutzer sucht das gestaltete Über-Fenster, dann erreicht er es
  über „About" in der Fußzeile des Popovers oder über „About Mika+Grid" im
  Einstellungsbereich „About".
  *(Seit 1.1.0 gab es keinen Auslöser mehr: Die Schaltfläche war durch „Updates" ersetzt
  worden, der Empfänger blieb stehen.)*

### Datenschutz und Missbrauchsschutz

- **AK-16** · Angenommen, „Reset All Settings" wurde bestätigt, wenn die
  Einstellungsdatei geprüft wird, dann sind die vier bekannten Schlüssel entfernt.
- **AK-17** · Angenommen dasselbe, wenn die Einstellungsdatei geprüft wird, dann sind auch
  die Sparkle-Schlüssel entfernt — Prüfintervall, Zeitpunkt der letzten Prüfung und die
  automatische Installation eingeschlossen.
  *(Bis 1.1.1 nannte die Löschliste nur die vier eigenen Schlüssel; insbesondere die
  unbeaufsichtigte Installation überlebte jedes Zurücksetzen.)*
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

## Behobener Fehlbestand

- **FB-01 ✅ Das Zurücksetzen führte nicht in den Auslieferungszustand.**
  **Behoben:** `resetAllPreferences()` setzt beide Kennzeichen auf `false`.
- **FB-02 ✅ Die Sparkle-Einstellungen wurden nicht zurückgesetzt.**
  **Behoben:** Acht Sparkle-Schlüssel stehen jetzt in der Löschliste, darunter die
  unbeaufsichtigte Installation.
- **FB-03 ✅ Fehlschläge beim Anmeldeobjekt blieben unsichtbar.**
  **Behoben:** `LaunchAtLoginManager.lastError` wird in den Einstellungen angezeigt, und der
  Schalter liest den Systemzustand zurück.
- **FB-04 ✅ Das Über-Fenster war nicht erreichbar.**
  **Behoben:** Zwei Wege — Fußzeile des Popovers und Einstellungen → About.
- **FB-05 ✅ Das Zurücksetzen erzeugte einen eigenen Anmeldeverwalter.**
  **Behoben:** `AppState.resetEverything()` bündelt Einstellungen, Anmeldeobjekt, Historie
  und Kürzel an einer Stelle und benutzt die vorhandenen Verwalter.
- **FB-06 ✅ Fenstermaße waren doppelt festgelegt.**
  **Behoben:** `PreferencesWindowController.windowSize` ist die einzige Quelle; die Ansicht
  bezieht sich darauf. Ebenso im Onboarding und im Über-Fenster.
- **FB-07 ✅ Kein Standardkürzel für die Einstellungen.**
  **Behoben:** ⌘, und ⌘Q wirken, solange das Popover offen ist. Ein Programmmenü kann eine
  App mit `LSUIElement` nicht haben — das ist die erreichbare Annäherung.
- **FB-08 ✅ Kein Test.**
  **Behoben** für die Zustandslogik: Die Löschliste und das Laden der Kürzel sind über
  `HotkeyPersistenceTests` abgedeckt; die Oberfläche bleibt Sache der QA.

## Entschiedene Fragen

- **OF-01 ✅ „Reset All Settings" zeigt das Onboarding erneut.** Das ist die Bedeutung von
  „Auslieferungszustand"; wer nur die Kürzel zurücksetzen will, hat dafür „Restore
  Defaults" im Bereich Shortcuts.
- **OF-02 ✅ Ein Fehlschlag beim Anmeldeobjekt ist sichtbar.**
- **OF-03 ✅ Das Über-Fenster ist wieder erreichbar** — entschieden gegen das Streichen,
  weil es gestaltet ist und die Marke trägt. Der Zwischenzustand aus totem Code ist damit
  aufgelöst.
- **OF-04 ✅ Das Zurücksetzen umfasst die Sparkle-Einstellungen.**

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Aufbau | Seitenleiste mit Inhaltsbereich | Entspricht den Systemeinstellungen ab Ventura |
| 2 | Fensterhalter mit Wiederverwendung | jedes Mal neu | Verhindert zwei Einstellungsfenster nebeneinander |
| 3 | Anmeldezustand aus dem System lesen | in den Einstellungen spiegeln | Das System ist die Wahrheit; ein Spiegel liefe auseinander |
| 4 | Rückfrage vor dem Zurücksetzen | sofort ausführen | Der Vorgang ist nicht umkehrbar |
| 5 | Kürzel nach dem Zurücksetzen sofort neu anmelden | Neustart verlangen | Sonst hätte der Nutzer bis zum Neustart gar keine Kürzel |
| 6 | Verwaisten Schlüssel weiter löschen | aus der Liste entfernen | Räumt Altbestände auf — richtig und ausdrücklich kommentiert |
