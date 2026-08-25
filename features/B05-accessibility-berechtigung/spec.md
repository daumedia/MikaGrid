# B05 · Accessibility-Berechtigung — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1

> **Rückerfassung.** ⚠ markiert Verhalten, das zur Klärung vorliegt.

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
- **AK-10** ⚠ · Angenommen, die Berechtigung fehlt, wenn der Nutzer ein Tastenkürzel
  drückt oder eine Zone im Popover anklickt, dann passiert **nichts** — keine Meldung,
  kein Ton, kein Hinweis.
  *(So verhält sich der Code heute: `WindowManager.snapFrontmostWindow` beginnt mit
  `guard AXIsProcessTrusted() else { return }`. Aus Nutzersicht ist die App in diesem
  Moment nicht von „kaputt" zu unterscheiden. Als Kriterium aufgenommen, damit die QA es
  reproduziert; siehe OF-01.)*
- **AK-11** ⚠ · Angenommen, das Popover ist geöffnet und die Berechtigung wird währenddessen
  erteilt, wenn nichts weiter geschieht, dann bleibt die Ampel orange, bis das Popover
  geschlossen und erneut geöffnet wird.
  *(Der Zustand wird nur bei `onAppear` geprüft; die Abfrage im Sekundentakt läuft
  ausschließlich im Onboarding-Schritt. Siehe OF-02.)*

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

## Fehlbestand

- **FB-01 · Keine Rückmeldung bei fehlender Berechtigung im Betriebsfall.**
  `WindowManager.swift:46`. **Folge:** Der Nutzer drückt ⌃⌥← und nichts geschieht. Es
  gibt keinen Ton, keine Einblendung, keinen Hinweis im Popover-Kontext. Das ist der
  wahrscheinlichste Grund für „die App funktioniert nicht" — und der einzige Hinweis
  darauf liegt im Popover, das man dafür erst öffnen muss.
- **FB-02 · Der Deep-Link in die Systemeinstellungen verwendet den alten Pfad.**
  `AccessibilityManager.swift:27` öffnet
  `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`. Das
  ist die Kennung aus der Zeit vor macOS 13; ab Ventura heißt der Bereich
  `com.apple.settings.PrivacySecurity.extension`. **Folge:** Apple leitet den alten Pfad
  bislang weiter, garantiert ist das nicht. Die App verlangt ohnehin macOS 14+ und könnte
  den aktuellen Pfad verwenden. **Zu prüfen in der QA:** ob der Link auf dem
  Zielsystem tatsächlich im Bereich Bedienungshilfen landet oder nur die
  Systemeinstellungen allgemein öffnet.
- **FB-03 · `requestPermission()` verwirft sein Ergebnis.**
  `AccessibilityManager.swift:22` ruft `AXIsProcessTrustedWithOptions` auf, ohne den
  Rückgabewert zu verwenden, und aktualisiert `isGranted` nicht. **Folge:** Nach dem
  Aufruf steht der eigene Zustand möglicherweise auf `false`, obwohl das System bereits
  `true` meldet — bis irgendwann `checkPermission()` läuft.
- **FB-04 · Der Zustand wird nur an Sichtbarkeitspunkten aktualisiert.** Es gibt keine
  Beobachtung systemweiter Änderungen (etwa über eine `DistributedNotification`) und
  keinen laufenden Takt außerhalb des Onboarding-Schritts. **Folge:** AK-11.
- **FB-05 · `permissionSkipped` lässt sich nicht zurücknehmen.**
  `AppPreferences.swift:18`; gesetzt wird der Wert ausschließlich in
  `PermissionScreen`. **Folge:** Wer einmal „Skip for now" gewählt hat, wird beim Start
  nie wieder gefragt — auch nach Monaten nicht, und auch dann nicht, wenn die
  Berechtigung zwischenzeitlich erteilt und wieder entzogen wurde. Zurücksetzen geht nur
  über „Reset All Settings".
- **FB-06 · Kein Test.** Der Zustandsautomat aus `isGranted`, `permissionSkipped` und
  `hasCompletedOnboarding` bestimmt, ob beim Start ein Systemdialog erscheint. Drei
  Wahrheitswerte, acht Kombinationen, kein einziger Test.

## Offene Fragen

- **OF-01** · Soll die App auf einen Snap-Versuch ohne Berechtigung reagieren (FB-01)?
  Möglich wären ein Systemton, eine kurze Einblendung oder das Öffnen des Popovers mit
  hervorgehobenem Warnbanner. — *Betreiber.*
- **OF-02** · Soll die Ampel im Popover live folgen (AK-11)? Ein dauerhafter Takt kostet
  Ressourcen; eine Prüfung beim Öffnen ist sparsam, aber träge. — *Betreiber.*
- **OF-03** · Soll der Deep-Link auf die aktuelle Kennung umgestellt werden (FB-02)?
  Abhängig vom Prüfergebnis der QA. — *nach QA.*

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie prüfen | `AXIsProcessTrusted()` | Der einzige unterstützte Weg; ohne Nebenwirkung, löst keinen Dialog aus |
| 2 | Wie anfordern | `AXIsProcessTrustedWithOptions` mit Prompt | Löst den Systemdialog aus. Erscheint pro Signatur nur einmal |
| 3 | Wie erkennen, dass erteilt wurde | Abfrage im Sekundentakt | Es gibt keine Benachrichtigung für TCC-Änderungen; Abfragen ist der übliche Weg |
| 4 | Takt nur im Onboarding | ja | Sparsam. Der Preis ist AK-11 |
| 5 | Überspringen erlauben | ja, mit dauerhafter Wirkung | Die App bleibt benutzbar (Popover, Einstellungen, Updates), nur das Snappen nicht. Ob die Dauerhaftigkeit beabsichtigt war, ist nicht rekonstruierbar — FB-05 |
