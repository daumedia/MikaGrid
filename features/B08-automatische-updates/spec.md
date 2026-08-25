# B08 · Automatische Updates — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1 · Repariert in: v1.2.0 · Repariert in: v1.2.0

> **Rückerfassung, danach repariert.** Erfasst aus v1.1.1, überarbeitet in **v1.2.0**
> (2026-08-25). Die Kriterien beschreiben den Stand **nach** der Reparatur; was vorher
> anders war, steht in Klammern dabei. ⚠ markiert die Punkte, die **nicht** aus dem
> Repository heraus lösbar sind.

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
- **AK-10** · Angenommen, ein Update wird gefunden, dann entscheidet der Schalter „Install
  updates automatically" in den Einstellungen, ob es ungefragt installiert wird — und er
  lässt sich abschalten.
  *(Bis 1.1.1 stand `SUAutomaticallyUpdate` auf dem geprüften System auf `1`, gesetzt von
  Sparkles eigenem Erstdialog, und die App zeigte nur die Prüf-, nicht die
  Installationsstufe. Wer das abstellen wollte, fand in der App keinen Weg dazu.)*

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

## Behobener Fehlbestand

- **FB-01 ✅ Der Update-Feed hing an einem anderen Zweig als die Entwicklung.**
  **Behoben:** `scripts/release.sh` prüft den Zweig und nennt den Push nach `master`
  ausdrücklich als Abschlussschritt jedes Release. Die Adresse selbst bleibt auf `master`
  — siehe OF-02 für die Begründung.
- **FB-02 ✅ `sparkle:version` war uneinheitlich.**
  **Behoben:** Alle Einträge tragen die Build-Nummer; der 1.1.0-Eintrag steht jetzt auf `1`
  (aus der Git-Historie belegt). `release.sh --check` vergleicht den Feed-Wert vor jeder
  Veröffentlichung gegen `CFBundleVersion` und bricht bei Abweichung ab.
- **FB-03 ✅ Der Eintrag für 1.0.0 hatte kein `<enclosure>`.**
  **Behoben:** Der Eintrag ist entfernt — ein Release `v1.0.0` existiert auf GitHub gar
  nicht, der Eintrag verwies also ins Leere. Die Release-Notes stehen im `CHANGELOG.md`.
- **FB-04 ✅ Kein `updaterDelegate`, keine Fehlerbehandlung.**
  **Behoben:** `UpdaterObserver` nimmt `didFinishUpdateCycleFor` entgegen; Fehler landen in
  `lastCheckError` und werden in den Einstellungen angezeigt. „Kein Update gefunden" wird
  dabei nicht als Fehler behandelt, weil Sparkle es als solchen meldet.
- **FB-05 ✅ Die automatische Installation war nicht abschaltbar.**
  **Behoben:** Zweiter Schalter „Install updates automatically", abhängig vom ersten.
- **FB-06 ✅ Der Feed selbst ist nicht signiert.**
  **Entschieden statt umgesetzt:** `release.sh` kann den Feed über `SIGN_FEED=true`
  signieren, tut es aber nicht standardmäßig. Begründung in OF-03.
- **FB-07 ✅ Kein Test.**
  **Behoben:** `release.sh --check` und die CI prüfen Feed-Erreichbarkeit, Wohlgeformtheit
  und die Übereinstimmung von `CFBundleVersion` und `sparkle:version` vor jedem Release.
- **FB-08 ⚠ Der Auslieferungsstand ist nicht notarisiert.**
  **Teilweise behoben:** Signiert wird jetzt mit einer Developer ID
  (`Developer ID Application: Michael Rodrigues, CWJM4J4HFN`) statt ad-hoc. Die
  Notarisierung selbst steht aus — sie verlangt App-Store-Connect-Zugangsdaten, die nicht
  im Repository liegen dürfen. `release.sh` führt sie aus, sobald `NOTARY_PROFILE` gesetzt
  ist. **Das ist der einzige verbliebene Punkt dieses Features.**

## Entschiedene Fragen

- **OF-01 ✅ Die App darf sich unbeaufsichtigt aktualisieren — aber nur, wenn der Nutzer es
  will.** Der zweite Schalter macht die Stufe sichtbar und abschaltbar, statt sie
  stillschweigend aktiv zu lassen.
- **OF-02 ✅ Der Feed bleibt auf `master`.** Ein Wechsel auf `main` erreicht bestehende
  Installationen erst über ein Update, das noch von `master` käme — die Umstellung wäre also
  genau einmal riskant, ohne Gewinn. Stattdessen zieht `release.sh` `master` bei jedem
  Release mit und weist ausdrücklich darauf hin.
- **OF-03 ✅ Der appcast wird standardmäßig nicht signiert.** Die enclosure-Signatur
  beweist die Echtheit jedes Artefakts; unsigniert bleibt nur die Aussage, *welche* Fassung
  die neueste ist (Downgrade). Der Abruf läuft über HTTPS gegen GitHub, was den Angriff
  unpraktisch macht — während ein signierter Feed jede Handänderung an `appcast.xml`
  ungültig machen würde und Updates dann gar nicht mehr ankämen. Für ein Projekt mit
  handgeschnittenen Releases ist das die größere Gefahr. Über `SIGN_FEED=true` jederzeit
  aktivierbar.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Update-Mechanismus | Sparkle 2.6+ | Der Standard für Direktvertrieb außerhalb des App Store; EdDSA-Signaturen ohne eigene Infrastruktur |
| 2 | Wo liegt der Feed | GitHub `raw.githubusercontent.com` | Kein eigener Server nötig, keine Kosten, versioniert im selben Repository |
| 3 | Signaturverfahren | EdDSA (Ed25519) | Sparkles heutige Empfehlung; DSA gilt als überholt (das mitgelieferte `old_dsa_scripts` wird nicht benutzt) |
| 4 | Delegate | keiner | Grund nicht erkennbar — vermutlich Sparsamkeit beim Aufsetzen. Die Folge steht in FB-04 |
| 5 | Prüfintervall | Sparkle-Standard (24 h) | nicht überschrieben; kein `SUScheduledCheckInterval` in der `Info.plist` |
