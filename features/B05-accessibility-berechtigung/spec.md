# B05 · Accessibility-Berechtigung — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1 · Repariert in: v1.2.0

> **Rückerfassung, danach repariert.** Erfasst aus v1.1.1, überarbeitet in **v1.2.0**
> (2026-08-25). Die Kriterien beschreiben den Stand **nach** der Reparatur; was vorher
> anders war, steht in Klammern dabei. ⚠ markiert die Punkte, die **nicht** aus dem
> Repository heraus lösbar sind. *Behobener Fehlbestand* führt jede geschlossene Lücke mit
> ihrer Fundstelle — eine Rekonstruktion, die verschweigt, was falsch war, ist wertlos.

## Zweck

Ohne die Zustimmung des Nutzers zur Accessibility-API darf Mika+Grid kein einziges
fremdes Fenster anfassen. Dieses Feature holt diese Zustimmung ein, zeigt ihren Zustand
an drei Stellen an und bringt den Nutzer mit einem Klick an die Stelle im System, an der
er sie erteilt.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| — | — | B05 ist die Wurzel. B01, B02 und B06 hängen davon ab |

## User Stories

- **US-01** · Als Nutzer möchte ich verstehen, warum diese App so weitreichenden Zugriff
  verlangt, damit ich die Zustimmung nicht blind erteile.
- **US-02** · Als Nutzer möchte ich mit einem Klick an die richtige Stelle in den
  Systemeinstellungen kommen, statt sie zu suchen.
- **US-03** · Als Nutzer möchte ich jederzeit sehen können, ob die Berechtigung noch
  gilt, damit ich weiß, warum die App gerade nichts tut.

## Nicht im Scope

- **Das Erteilen der Berechtigung selbst.** Das kann keine App; nur das System darf das,
  und nur auf Handlung des Nutzers.
- **Der Onboarding-Ablauf drumherum** — das ist B06. B05 liefert nur den Zustand und den
  Schritt, den B06 einbettet.

## Akzeptanzkriterien

- **AK-01** · Angenommen, die App startet, wenn `AppState` aufgebaut wird, dann steht
  der Berechtigungszustand fest, ohne dass ein Dialog erscheint.
- **AK-02** · Angenommen, das Onboarding ist abgeschlossen und wurde nicht übersprungen,
  wenn die App startet und die Berechtigung fehlt, dann erscheint der Systemdialog
  „… möchte auf Bedienungshilfen zugreifen".
- **AK-03** · Angenommen, die Berechtigung wurde im Onboarding übersprungen, wenn die
  App startet, dann erscheint **kein** Dialog — dauerhaft, bei jedem weiteren Start.
- **AK-04** · Angenommen, das Popover wird geöffnet, wenn die Berechtigung fehlt, dann
  ist der Punkt in der Kopfzeile orange und darunter steht das Warnbanner
  „Accessibility permission required".
- **AK-05** · Angenommen, die Berechtigung liegt vor, wenn das Popover geöffnet wird,
  dann ist der Punkt grün und das Warnbanner fehlt.
- **AK-06** · Angenommen, das Warnbanner ist sichtbar, wenn es angeklickt wird, dann
  öffnen sich die Systemeinstellungen im Bereich Datenschutz & Sicherheit.
- **AK-07** · Angenommen, die Einstellungen sind offen, wenn der Bereich „Allgemein"
  angezeigt wird, dann steht dort „Accessibility: Granted" (grün, Häkchen) oder
  „Accessibility: Not Granted" (orange, Warndreieck) mit Schaltfläche „Open Settings".
- **AK-08** · Angenommen, der Berechtigungsschritt des Onboardings ist sichtbar, wenn
  der Nutzer die Zustimmung außerhalb der App erteilt, dann wechselt die Darstellung
  binnen etwa einer Sekunde von Schloss auf grünes Häkchen — ohne Zutun im Fenster.
- **AK-09** · Angenommen, der Berechtigungsschritt wird verlassen, wenn das Fenster
  wechselt, dann endet die Abfrage im Sekundentakt.
- **AK-10** · Angenommen, die Berechtigung fehlt, wenn der Nutzer ein Tastenkürzel drückt
  oder eine Zone im Popover anklickt, dann ertönt ein Systemton, der Berechtigungszustand
  wird aufgefrischt, und im Popover steht „Accessibility permission required".
  *(Bis 1.1.1 passierte wortlos nichts — die App war in diesem Moment nicht von „kaputt"
  zu unterscheiden.)*
- **AK-11** · Angenommen, das Popover ist geöffnet und die Berechtigung wird währenddessen
  erteilt, dann wechselt die Anzeige binnen etwa einer Sekunde von selbst.
  *(Seit 1.2.0 melden Popover, Einstellungen und Onboarding einen Abfragebedarf an; der
  Takt läuft, solange mindestens eine dieser Stellen sichtbar ist.)*

### Datenschutz und Missbrauchsschutz

Geprüft gegen `~/.claude/sdd/sicherheit.md`.

- **AK-12** · Angenommen, die Berechtigung ist erteilt, wenn die App sie nutzt, dann
  liest sie ausschließlich Position, Größe und Titel des fokussierten Fensters und setzt
  Position und Größe — keine Fensterinhalte, keine Tastatureingaben fremder Apps.
- **AK-13** · Angenommen, die App fordert die Berechtigung an, wenn der Nutzer den
  Grund wissen will, dann steht er im Onboarding: „Mika+Grid needs Accessibility access
  to move and resize windows. Your data stays on your Mac."
- **Personenbezogene Daten:** Über die Berechtigung werden Fenstertitel lesbar, die
  Personenbezug haben können. Sie werden nur flüchtig verwendet (siehe B02) und nie
  gespeichert oder übertragen.
- **Rollen, Rate Limits, Uploads, Geheimnisse:** treffen nicht zu — kein Server, keine
  Konten, keine Endpunkte.

## Edge Cases

- **EC-01** · Berechtigung wird entzogen, während die App läuft → sie fällt still auf
  „tut nichts" zurück (AK-10). Die Anzeige folgt erst beim nächsten `onAppear` oder
  beim nächsten Öffnen der Einstellungen.
- **EC-02** · Nutzer klickt im Systemdialog auf „Ablehnen" → identisch zu „nie gefragt";
  macOS zeigt den Dialog danach nicht erneut. Der Weg führt nur noch über die
  Systemeinstellungen.
- **EC-03** · App wird verschoben oder neu gebaut → macOS bindet die Zustimmung an die
  Signatur. Bei einer **ad-hoc signierten** App (siehe B09) ändert sie sich mit jedem
  Bau, und die Berechtigung muss erneut erteilt werden. Der alte Eintrag bleibt als
  Karteileiche in den Systemeinstellungen stehen.
- **EC-04** · Zwei Kopien der App (etwa `build/` und `/Applications`) → jede braucht
  eine eigene Zustimmung, beide erscheinen gleichnamig in der Liste.
- **EC-05** · Abfragetakt läuft, während das Fenster geschlossen wird → `onDisappear`
  beendet ihn; der Timer hält keine starke Referenz auf die Ansicht.

## Behobener Fehlbestand

- **FB-01 ✅ Keine Rückmeldung bei fehlender Berechtigung im Betriebsfall.**
  **Behoben:** `.missingPermission` mit Systemton und Meldung; zusätzlich wird der Zustand
  sofort neu geprüft, damit Ampel und Banner stimmen.
- **FB-02 ✅ Der Deep-Link verwendete den alten Pfad.**
  **Behoben:** Zuerst `com.apple.settings.PrivacySecurity.extension` (ab Ventura), bei
  Fehlschlag die alte Kennung. `NSWorkspace.open` meldet den Erfolg, es wird also nicht
  blind geöffnet.
- **FB-03 ✅ `requestPermission()` verwarf sein Ergebnis.**
  **Behoben:** Der Rückgabewert wird übernommen und meldet die Änderung weiter.
- **FB-04 ✅ Der Zustand wurde nur an Sichtbarkeitspunkten aktualisiert.**
  **Behoben:** Ein gezählter Abfragebedarf; der Takt läuft, solange eine anzeigende Stelle
  sichtbar ist, und endet, sobald sich alle abgemeldet haben.
- **FB-05 ✅ `permissionSkipped` ließ sich nicht zurücknehmen.**
  **Behoben:** Sobald die Berechtigung tatsächlich vorliegt, wird das Überspringen
  aufgehoben — es ist dann gegenstandslos. Wird die Zustimmung später entzogen, fragt die
  App wieder.
- **FB-06 ✅ Kein Test.**
  **Behoben:** Der Zustandsautomat wird über `AppPreferences` und die Startlogik geprüft;
  die reine Berechtigungsabfrage bleibt systemabhängig und ist Sache der QA.

## Entschiedene Fragen

- **OF-01 ✅ Ein Snap-Versuch ohne Berechtigung gibt Rückmeldung** — Systemton und
  Begründung. Bewusst **kein** automatisches Öffnen der Systemeinstellungen: Ein
  Tastendruck darf nicht ungefragt ein fremdes Fenster in den Vordergrund holen.
- **OF-02 ✅ Die Ampel folgt live**, solange eine anzeigende Stelle sichtbar ist. Der
  gezählte Bedarf verhindert, dass der Takt im Hintergrund weiterläuft.
- **OF-03 ✅ Der Deep-Link ist umgestellt**, mit dem alten Pfad als Rückfall.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie prüfen | `AXIsProcessTrusted()` | Der einzige unterstützte Weg; ohne Nebenwirkung, löst keinen Dialog aus |
| 2 | Wie anfordern | `AXIsProcessTrustedWithOptions` mit Prompt | Löst den Systemdialog aus. Erscheint pro Signatur nur einmal |
| 3 | Wie erkennen, dass erteilt wurde | Abfrage im Sekundentakt | Es gibt keine Benachrichtigung für TCC-Änderungen; Abfragen ist der übliche Weg |
| 4 | Takt nur im Onboarding | ja | Sparsam. Der Preis ist AK-11 |
| 5 | Überspringen erlauben | ja, mit dauerhafter Wirkung | Die App bleibt benutzbar (Popover, Einstellungen, Updates), nur das Snappen nicht. Ob die Dauerhaftigkeit beabsichtigt war, ist nicht rekonstruierbar — FB-05 |
