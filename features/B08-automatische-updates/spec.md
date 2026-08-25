# B08 · Automatische Updates — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1

> **Rückerfassung.** Beschrieben ist das **tatsächliche** Verhalten der ausgelieferten
> Version, nicht das gewünschte. ⚠ markiert Verhalten, das der Code heute zeigt und das
> zur Klärung vorliegt — siehe *Offene Fragen*.

## Zweck

Mika+Grid hält sich selbst aktuell: Es prüft ein signiertes Update-Verzeichnis auf
GitHub, lädt bei Bedarf das neue DMG und installiert es. Ohne dieses Feature erreichte
eine Fehlerbehebung nur, wer von sich aus auf der Releases-Seite nachsieht.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| — | — | B08 läuft eigenständig; es ist der einzige Teil der App, der ohne Accessibility-Berechtigung vollständig funktioniert |

Umgekehrt hängt **B09** von B08 ab: Die Build-Kette erzeugt das Artefakt, dessen Echtheit
B08 prüft.

## User Stories

- **US-01** · Als Nutzer möchte ich Fehlerbehebungen bekommen, ohne die Projektseite zu
  beobachten, damit ich nicht monatelang eine kaputte Version benutze.
- **US-02** · Als Nutzer möchte ich selbst nachsehen können, ob eine neue Version
  vorliegt, damit ich nicht auf den nächsten automatischen Lauf warten muss.
- **US-03** · Als Betreiber möchte ich sicher sein, dass niemand fremden Code über
  meinen Update-Weg ausliefern kann, damit die App kein Einfallstor ist.

## Nicht im Scope

- **Das Erzeugen und Signieren des DMG** — das ist B09. B08 beginnt bei einem fertig
  signierten Artefakt und einem gepflegten `appcast.xml`.
- **Delta-Updates**, Beta-Kanäle, Phased Rollouts. Sparkle beherrscht das; die App nutzt
  nichts davon.

## Akzeptanzkriterien

- **AK-01** · Angenommen, die App startet und die automatische Prüfung ist aktiv, wenn
  Sparkles Prüfintervall erreicht ist, dann wird
  `https://raw.githubusercontent.com/daumedia/MikaGrid/master/appcast.xml` abgerufen.
  *(Nachweis 2026-08-25: HTTP 200, 4174 Bytes, inhaltsgleich mit der Fassung im Repo.)*
- **AK-02** · Angenommen, die App läuft, wenn im Popover „Updates" angeklickt wird, dann
  startet eine Update-Prüfung mit sichtbarer Rückmeldung von Sparkle.
- **AK-03** · Angenommen, die Einstellungen sind offen, wenn unter „Allgemein" auf
  „Check Now" geklickt wird, dann startet dieselbe Prüfung wie in AK-02.
- **AK-04** · Angenommen, eine Prüfung lief bereits, wenn die Einstellungen geöffnet
  werden, dann steht dort „Last checked: <Zeitspanne> ago".
- **AK-05** · Angenommen, der Schalter „Automatic updates" wird umgelegt, wenn die App
  neu gestartet wird, dann gilt der neue Zustand weiterhin (persistiert als
  `SUEnableAutomaticChecks`).
- **AK-06** · Angenommen, ein Update wird angeboten, wenn das DMG geladen ist, dann wird
  es nur installiert, falls seine EdDSA-Signatur zum in der `Info.plist` hinterlegten
  `SUPublicEDKey` passt.
  *(Nachweis 2026-08-25: Der Schlüssel im Keychain des Betreibers ist identisch mit
  `SUPublicEDKey`; das ausgelieferte DMG verifiziert gegen die appcast-Signatur mit
  Exit 0. Negativkontrollen: ein einzelnes gekipptes Byte wird abgelehnt, die Signatur
  des Vorgängers 1.1.0 wird abgelehnt.)*
- **AK-07** · Angenommen, ein Angreifer tauscht das DMG hinter der Download-Adresse aus,
  wenn die Installation läuft, dann bricht Sparkle ab und installiert nichts.
  *(Deckungsgleich mit der Negativkontrolle zu AK-06.)*
- **AK-08** · Angenommen, das DMG wird geladen, wenn seine Größe von der im appcast
  deklarierten `length` abweicht, dann gilt es als beschädigt.
  *(Nachweis 2026-08-25: deklariert 2543170, ausgeliefert 2543170 Bytes.)*
- **AK-09** · Angenommen, ein System läuft unter macOS 13, wenn der Feed gelesen wird,
  dann wird 1.1.1 nicht angeboten (`sparkle:minimumSystemVersion` = 14.0).
- **AK-10** ⚠ · Angenommen, ein Update wird gefunden und `SUAutomaticallyUpdate` ist
  gesetzt, wenn nichts weiter geschieht, dann lädt und installiert sich die neue Version
  **ohne Rückfrage** — und die Oberfläche der App bietet keinen Weg, das abzuschalten.
  *(So verhält sich der Code heute. Auf dem geprüften System steht der Wert auf `1`;
  gesetzt wurde er von Sparkles eigenem Erstdialog, nicht von Mika+Grid.
  `GeneralTabView` kennt nur `automaticallyChecksForUpdates`. Als Kriterium aufgenommen,
  damit die QA es reproduziert — siehe OF-01.)*

### Datenschutz und Missbrauchsschutz

Geprüft gegen `~/.claude/sdd/sicherheit.md`.

- **AK-11** · Angenommen, eine Update-Prüfung läuft, wenn der Netzwerkverkehr betrachtet
  wird, dann werden **keine** Hardware- oder Systemdaten übertragen.
  *(`SUEnableSystemProfiling` fehlt in der `Info.plist`, Sparkle-Standard ist aus; auf
  dem geprüften System steht `SUSendProfileInfo = 0`.)*
- **AK-12** · Angenommen, eine Update-Prüfung läuft, wenn sie abgeschlossen ist, dann
  hat die App keine personenbezogenen Daten gesendet — die Verbindung überträgt allein
  das, was jeder HTTPS-Abruf überträgt: IP-Adresse und Zeitpunkt an GitHub.
- **AK-13** · Angenommen, die Update-Prüfung ist der einzige Netzzugriff der App, wenn
  der Quelltext durchsucht wird, dann findet sich keine weitere ausgehende Verbindung.
  *(Kein `URLSession`, kein `NSURLConnection` außerhalb von Sparkle.)*
- **Rate Limits:** trifft nicht zu — es gibt keinen eigenen Endpunkt. Die Abrufhäufigkeit
  bestimmt Sparkle; die Gegenstelle ist GitHubs CDN.
- **Kosten pro Aufruf:** trifft nicht zu — GitHub Releases und `raw.githubusercontent.com`
  sind für öffentliche Repositories kostenlos.
- **Geheimnisse:** Der **private** Signierschlüssel liegt im Keychain des Betreibers und
  ist nicht Teil des Repositories. Im Auslieferungsartefakt steckt nur der öffentliche
  Teil (`SUPublicEDKey`) — korrekt, das ist seine Bestimmung.

## Edge Cases

- **EC-01** · Kein Netz beim Prüflauf → Sparkle scheitert still. Bei einer automatischen
  Prüfung ist das richtig; bei einem Klick auf „Updates" oder „Check Now" sieht der
  Nutzer Sparkles eigenes Fehlerfenster.
- **EC-02** · Feed-URL liefert 404 (Repository umbenannt, Zweig gelöscht) → die App
  meldet an keiner eigenen Stelle etwas; es gibt keinen `updaterDelegate`, der den
  Fehlschlag protokollieren oder anzeigen könnte. Für den Nutzer sieht eine dauerhaft
  tote Update-Kette genauso aus wie „ich bin aktuell". Siehe FB-04.
- **EC-03** · Signatur passt nicht → Installation bricht ab. Verifiziert (AK-07).
- **EC-04** · Zwei Prüfungen gleichzeitig (Popover-Klick während einer automatischen
  Prüfung) → Sparkle serialisiert das selbst; `canCheckForUpdates` liegt als Eigenschaft
  vor, wird aber **von keiner Stelle der Oberfläche abgefragt**. Die Schaltflächen sind
  immer aktiv.
- **EC-05** · Nutzer auf 1.0.0 → der zugehörige appcast-Eintrag trägt **kein**
  `<enclosure>`. Er dient nur als Verlaufsnotiz; Sparkle überspringt ihn und bietet die
  neueste gültige Fassung an. Funktioniert, ist aber formal ein unvollständiges Item
  (FB-03).

## Fehlbestand

Nicht vorhanden, aus dem Code belegt. Kein Kriterium — `sdd-qa` prüft nichts davon als
bestanden, sondern nimmt es als Suchliste.

- **FB-01 · Der Update-Feed hängt an einem anderen Zweig als die Entwicklung.**
  `Resources/Info.plist` (`SUFeedURL`) zeigt auf `…/master/appcast.xml`, entwickelt und
  veröffentlicht wird auf `main`. Beide waren bis zum 2026-08-25 deckungsgleich; seit
  dem Merge der SDD-Erfassung liegt `main` einen Commit vorn.
  **Folge:** Landet ein neuer appcast-Eintrag nur auf `main`, erreicht das Update
  **keine einzige** bestehende Installation — die App sucht an genau dieser Adresse und
  an keiner anderen. Der Fehler wäre am Tag des Release unsichtbar und fiele erst auf,
  wenn sich niemand aktualisiert.
- **FB-02 · `sparkle:version` ist über die Einträge hinweg uneinheitlich.**
  `appcast.xml` nennt für 1.1.1 den Wert `2` (passend zu `CFBundleVersion`), für 1.1.0
  aber `1.1.0` und für 1.0.0 `1.0.0` — dort also die Marketing-Version im Feld für die
  Build-Nummer. **Folge:** Der Versionsvergleich funktioniert heute zufällig, weil
  `2` beim komponentenweisen Vergleich vor `1.1.0` liegt. Eine künftige `CFBundleVersion`
  wie `10` bliebe korrekt, `1` dagegen nicht — die Kette ist gegen einen Zahlendreher
  ungeschützt.
- **FB-03 · Der Eintrag für 1.0.0 hat kein `<enclosure>`.** `appcast.xml`, drittes
  `<item>`. **Folge:** Kein akuter Schaden (Sparkle überspringt ihn), aber ein Item ohne
  Anhang ist im appcast-Format ungültig und kann bei künftigen Sparkle-Versionen anders
  behandelt werden.
- **FB-04 · Kein `updaterDelegate`, keine Fehlerbehandlung.**
  `SparkleUpdater.swift:20` erzeugt `SPUStandardUpdaterController` mit
  `updaterDelegate: nil, userDriverDelegate: nil`. **Folge:** Ein dauerhaft
  fehlschlagender Update-Weg — falsche URL, gelöschter Zweig, abgelaufenes Zertifikat —
  bleibt vollständig unbemerkt. Weder Nutzer noch Betreiber erfahren davon.
- **FB-05 · Die automatische Installation ist nicht abschaltbar.** `GeneralTabView.swift:56`
  bindet ausschließlich `automaticallyChecksForUpdates`. **Folge:** Wer das unbeaufsichtigte
  Installieren beenden will, muss `defaults write lu.daumedia.mikagrid SUAutomaticallyUpdate
  -bool false` im Terminal ausführen. Siehe AK-10 und OF-01.
- **FB-06 · Der Feed selbst ist nicht signiert.** Sparkle 2 kann das (`sign_update`
  signiert XML-Feeds und bettet die Signatur ein); `appcast.xml` enthält keine.
  **Folge:** Die Echtheit der einzelnen Fassung ist über die enclosure-Signatur
  gesichert — nicht aber die Aussage *welche* Fassung die neueste ist. Wer den Feed
  ersetzen könnte, könnte eine ältere, weiterhin gültig signierte Version als „neu"
  ausgeben (Downgrade). Praktisch schwierig, weil der Abruf über HTTPS gegen GitHub
  läuft; formal die verbleibende Lücke der Kette.
- **FB-07 · Kein Test.** Es gibt kein `Tests/`-Verzeichnis. **Folge:** Weder die
  Erreichbarkeit des Feeds noch die Übereinstimmung von `CFBundleVersion` und
  `sparkle:version` wird vor einem Release maschinell geprüft. Beides ist prüfbar, und
  beides ist genau die Art Fehler, die erst nach der Veröffentlichung auffällt.
- **FB-08 · Der Auslieferungsstand ist nicht notarisiert.** Gehört zu B09, wirkt aber
  hier: Sparkle installiert ein Artefakt, das Gatekeeper auf fremden Rechnern beanstandet.

## Offene Fragen

- **OF-01** · Soll sich die App unbeaufsichtigt aktualisieren dürfen? Heute tut sie es
  (AK-10), ohne dass die Oberfläche das anbietet oder zurücknehmen kann. Drei Wege:
  einen zweiten Schalter ergänzen, `SUAutomaticallyUpdate` beim Start hart auf `false`
  setzen, oder es bewusst so lassen und dokumentieren. — *Betreiber, vor dem nächsten
  Release.*
- **OF-02** · Welcher Zweig trägt künftig den Feed (FB-01)? Umstellen auf `main` erreicht
  bestehende Installationen erst über ein Update, das noch von `master` kommt — die
  Reihenfolge ist also nicht beliebig. Alternative: `master` bleibt reiner Feed-Zweig und
  wird bei jedem Release mitgezogen. — *Betreiber, vor dem nächsten Release.*
- **OF-03** · Soll der appcast signiert werden (FB-06)? Kostet einen zusätzlichen Schritt
  je Release und schließt den Downgrade-Weg. — *Betreiber, ohne Frist.*

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Update-Mechanismus | Sparkle 2.6+ | Der Standard für Direktvertrieb außerhalb des App Store; EdDSA-Signaturen ohne eigene Infrastruktur |
| 2 | Wo liegt der Feed | GitHub `raw.githubusercontent.com` | Kein eigener Server nötig, keine Kosten, versioniert im selben Repository |
| 3 | Signaturverfahren | EdDSA (Ed25519) | Sparkles heutige Empfehlung; DSA gilt als überholt (das mitgelieferte `old_dsa_scripts` wird nicht benutzt) |
| 4 | Delegate | keiner | Grund nicht erkennbar — vermutlich Sparsamkeit beim Aufsetzen. Die Folge steht in FB-04 |
| 5 | Prüfintervall | Sparkle-Standard (24 h) | nicht überschrieben; kein `SUScheduledCheckInterval` in der `Info.plist` |
