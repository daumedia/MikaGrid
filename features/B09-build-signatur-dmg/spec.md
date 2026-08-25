# B09 · Build-, Signatur- und DMG-Kette — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1

> **Rückerfassung.** Beschrieben ist, was die Skripte tun, nachgeprüft am gebauten
> Bundle unter `build/` und am ausgelieferten DMG aus dem GitHub-Release.
> ⚠ markiert Verhalten, das zur Klärung vorliegt.

## Zweck

Aus dem Quelltext entsteht ein startfähiges, signiertes `.app`-Bundle und daraus ein
DMG, das Nutzer per Doppelklick installieren. Ohne diese Kette gäbe es nur eine
ausführbare Datei ohne Bundle-Kennung — und damit weder Hotkeys noch Sparkle.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B08 | rekonstruiert | Die Kette bettet Sparkle ein und erzeugt das Artefakt, dessen Signatur B08 prüft. Was hier schiefgeht, merkt der Nutzer erst beim Update |

## User Stories

- **US-01** · Als Betreiber möchte ich mit einem Befehl ein installierbares Paket
  erzeugen, damit ein Release keine Handarbeit an fünf Stellen ist.
- **US-02** · Als Nutzer möchte ich die App per Doppelklick und Ziehen installieren,
  damit ich mich nicht mit Terminalbefehlen befassen muss.
- **US-03** · Als Nutzer möchte ich darauf vertrauen können, dass die geladene App vom
  angegebenen Hersteller stammt und unterwegs nicht verändert wurde.

## Nicht im Scope

- **Der Update-Weg selbst** — das ist B08.
- **Fremde Architekturen.** Gebaut wird für den Rechner, auf dem das Skript läuft
  (arm64); ein Universal Binary entsteht nicht.

## Akzeptanzkriterien

- **AK-01** · Angenommen, ein sauberer Arbeitsstand, wenn `bash build.sh` läuft, dann
  entsteht `build/Mika+Grid.app` mit ausführbarer Datei, `Info.plist` und `AppIcon.icns`
  an den vom Bundle-Format erwarteten Stellen.
- **AK-02** · Angenommen, `--clean` wird übergeben, wenn der Build startet, dann wird
  `.build/` vorher gelöscht.
- **AK-03** · Angenommen, die Sparkle-Abhängigkeit ist aufgelöst, wenn das Bundle
  gebaut wird, dann liegt `Sparkle.framework` unter `Contents/Frameworks/` und die
  ausführbare Datei trägt den Suchpfad `@executable_path/../Frameworks`.
- **AK-04** · Angenommen, das Bundle ist fertig, wenn `codesign --verify --deep --strict`
  darauf läuft, dann meldet es keinen Fehler.
  *(Nachweis 2026-08-25: bestanden.)*
- **AK-05** · Angenommen, das Bundle ist signiert, wenn seine Signatur gelesen wird,
  dann trägt es das Kennzeichen `runtime` (Hardened Runtime) und die Entitlements aus
  `Resources/MikaGrid.entitlements`.
  *(Nachweis: `flags=0x10002(adhoc,runtime)`, beide Entitlements eingebettet.)*
- **AK-06** · Angenommen, `build/Mika+Grid.app` existiert, wenn
  `bash scripts/create-dmg-simple.sh` läuft, dann entsteht
  `installer/Mika+Grid-v<Version>.dmg` mit App-Symbol, Verknüpfung nach `/Applications`,
  gebrandetem Hintergrund und fester Fensteranordnung.
- **AK-07** · Angenommen, das App-Bundle fehlt, wenn ein DMG-Skript startet, dann bricht
  es mit einer verständlichen Meldung ab und verweist auf `build.sh`.
- **AK-08** · Angenommen, `create-dmg` ist nicht installiert, wenn
  `scripts/create-dmg.sh` startet, dann bricht es ab und nennt sowohl den
  Homebrew-Befehl als auch das Ausweichskript.
- **AK-09** · Angenommen, der DMG-Hintergrund fehlt, wenn ein DMG-Skript läuft, dann
  wird er über `scripts/GenerateDMGBackground.swift` erzeugt.
- **AK-10** · Angenommen, die Version steht in `Resources/Info.plist`, wenn ein DMG
  entsteht, dann trägt die Datei genau diese Versionsnummer im Namen.
- **AK-11** ⚠ · Angenommen, ein Nutzer lädt das ausgelieferte DMG und öffnet die App,
  wenn Gatekeeper prüft, dann **wird sie abgewiesen** und muss über den Rechtsklick-Weg
  freigegeben werden.
  *(So verhält sich der Auslieferungsstand heute: `spctl -a -vv build/Mika+Grid.app` →
  `rejected`; `xcrun stapler validate` am ausgelieferten DMG → „does not have a ticket
  stapled to it". Die Signatur ist ad-hoc, `TeamIdentifier=not set`. Die FAQ der
  Landingpage beschreibt diesen Umweg ausdrücklich — es ist also bekannt und in Kauf
  genommen. Als Kriterium aufgenommen, damit die QA es reproduziert; siehe OF-01.)*
- **AK-12** ⚠ · Angenommen, die Kette hat Sparkles Bestandteile einzeln von innen nach
  außen signiert, wenn anschließend das Gesamtbundle signiert wird, dann werden **alle
  diese Signaturen erneut überschrieben** und den Bestandteilen die Entitlements der App
  aufgeprägt.
  *(So verhält sich der Code heute: `scripts/build.sh:76` ruft
  `codesign --force --deep --sign - --entitlements …` auf das ganze Bundle. Nachgewiesen
  am Ergebnis: `Downloader.xpc`, `Installer.xpc` und `Updater.app` tragen
  `app-sandbox=false` und `disable-library-validation=true`, obwohl Sparkle sie mit
  **leeren** Entitlements ausliefert. Damit sind die Zeilen 64–72 des Skripts wirkungslos.
  Siehe FB-02 und OF-02.)*

### Datenschutz und Missbrauchsschutz

Geprüft gegen `~/.claude/sdd/sicherheit.md`.

- **AK-13** · Angenommen, die Skripte laufen, wenn ihr Inhalt geprüft wird, dann
  enthalten sie **keine** Geheimnisse: keinen privaten Signierschlüssel, kein
  App-spezifisches Passwort, kein Token. *(Der Signierschlüssel für Sparkle liegt
  ausschließlich im Keychain des Betreibers.)*
- **AK-14** · Angenommen, ein DMG wird erzeugt, wenn sein Inhalt betrachtet wird, dann
  enthält es nur das App-Bundle, die `/Applications`-Verknüpfung, den Hintergrund und
  das Datenträgersymbol — keine Quelltexte, keine Schlüssel, keine Konfiguration.
- **Personenbezogene Daten:** trifft nicht zu — die Kette verarbeitet ausschließlich
  Programmdateien.
- **Rate Limits / Kosten:** trifft nicht zu — alles läuft lokal.

## Edge Cases

- **EC-01** · `Sparkle.framework` nicht auffindbar → das Skript überspringt das
  Einbetten **stillschweigend** und baut ein Bundle ohne Update-Fähigkeit. Der Fehler
  fällt erst auf, wenn die App startet und Sparkle fehlt. Siehe FB-03.
- **EC-02** · `install_name_tool` schlägt fehl → wird mit `2>/dev/null || true`
  verschluckt; das Bundle entsteht trotzdem und stürzt beim Start ab.
- **EC-03** · `AppIcon.icns` fehlt → wird übersprungen, das Bundle bekommt das
  Standardsymbol. Für einen Testbau vertretbar.
- **EC-04** · Ein DMG desselben Namens existiert bereits → wird vorher gelöscht.
- **EC-05** · Der AppleScript-Block in `create-dmg-simple.sh` scheitert (Finder
  reagiert nicht, keine Rechte für Automation) → nur das Setzen des Hintergrunds ist
  mit `try` abgesichert; die übrigen Anweisungen brechen das Skript ab, nachdem das
  Sparse-Image bereits eingehängt ist. Es bleibt eingehängt zurück.
- **EC-06** · Zwei Datenträger gleichen Namens eingehängt → `MOUNT_POINT` wird über
  `grep "/Volumes/"` ermittelt und trifft möglicherweise den falschen.

## Fehlbestand

Nicht vorhanden, aus dem Code belegt.

- **FB-01 · Keine Notarisierung, keine Developer-ID-Signatur.** `scripts/build.sh:76`
  signiert mit `--sign -` (ad-hoc). Kein Skript ruft `notarytool` oder `stapler`.
  **Folge:** Gatekeeper weist die App auf jedem fremden Rechner ab (nachgewiesen:
  `spctl` → `rejected`, kein gestapeltes Ticket am ausgelieferten DMG). Jeder Nutzer
  muss den Rechtsklick-Umweg gehen — und genau dieser Umweg ist die Handlung, die man
  Nutzern sonst abgewöhnen möchte. Für ein Werkzeug, das sich selbst aktualisiert und
  Zugriff auf alle Fenster verlangt, ist das die schwerste Lücke der ganzen Kette.
- **FB-02 · `codesign --deep` beim Signieren.** `scripts/build.sh:76`. Apple rät davon
  ausdrücklich ab; `--deep` ist für die Prüfung gedacht, nicht fürs Signieren.
  **Folge:** Die sorgfältige Signierung von innen nach außen in den Zeilen 64–72 wird
  vollständig überschrieben, und alle verschachtelten Bestandteile erhalten die
  Entitlements der App. Nachgewiesen am Bundle: Sparkles XPC-Dienste tragen
  `disable-library-validation=true`, obwohl Sparkle sie ohne jede Entitlement
  ausliefert. Bei einer echten Developer-ID-Signatur führt dieses Muster regelmäßig zu
  abgelehnter Notarisierung.
- **FB-03 · `disable-library-validation` ist ein Symptom, keine Notwendigkeit.**
  `Resources/MikaGrid.entitlements`, eingeführt mit Commit `cb04fbe`
  („Fix Sparkle framework loading by disabling library validation").
  **Folge:** Die Entitlement wurde gebraucht, weil App und eingebettetes Framework
  ad-hoc signiert sind und daher keine gemeinsame Team-Kennung haben. Mit einer echten
  Developer-ID-Signatur entfiele der Grund. Solange sie gesetzt ist, darf der Prozess
  beliebige fremdsignierte Bibliotheken laden — eine Abschwächung des Hardened Runtime,
  die niemand mehr zurücknimmt, wenn ihr Anlass in Vergessenheit gerät.
- **FB-04 · Das Einbetten von Sparkle scheitert lautlos.** `scripts/build.sh:52–58`
  sucht das Framework und überspringt den ganzen Block, wenn nichts gefunden wird.
  **Folge:** Es entsteht ein Bundle ohne Update-Fähigkeit, ohne dass das Skript einen
  Fehler meldet. Das Skript läuft mit `set -euo pipefail`, umgeht diesen Schutz an
  dieser Stelle aber durch `|| true` und die `if`-Bedingung.
- **FB-05 · Das DMG wird weder signiert noch geprüft.** Weder `create-dmg.sh` noch
  `create-dmg-simple.sh` enthält einen einzigen `codesign`-Aufruf (nachgezählt: 0).
  **Folge:** Der Datenträger selbst ist nicht als vom Betreiber stammend erkennbar —
  auch dann nicht, wenn die App darin es später einmal sein sollte.
- **FB-06 · Die Sparkle-Signatur für den appcast entsteht von Hand.** Kein Skript ruft
  `sign_update` auf (nachgezählt: kein Treffer in `scripts/` und `build.sh`).
  **Folge:** Nach jedem Release müssen Signatur und Byte-Länge von Hand nach
  `appcast.xml` übertragen werden. Wird es vergessen oder verrutscht eine Ziffer, lehnt
  Sparkle das Update ab — sicher, aber unbemerkt: Der Betreiber erfährt nichts davon
  (siehe B08/FB-04), und die Nutzer bleiben auf der alten Fassung.
- **FB-07 · Kein Freigabeschritt prüft die Zusammengehörigkeit.**
  `CFBundleShortVersionString`, `CFBundleVersion`, der Eintrag in `CHANGELOG.md`, der
  appcast-Eintrag und `web/lib/app.ts` müssen zueinander passen; nichts prüft das.
  **Folge:** Die Landingpage kann eine Version bewerben, die es nicht gibt, oder eine
  Größe nennen, die nicht stimmt. `CLAUDE.md` benennt die Pflicht zur Handpflege
  ausdrücklich — eine Erinnerung ist kein Schutz.
- **FB-08 · Kein Universal Binary.** `swift build -c release` baut für die Architektur
  des Rechners, auf dem es läuft. **Folge:** Intel-Macs bekommen kein lauffähiges
  Artefakt; die FAQ der Landingpage nennt das offen und verweist auf den Selbstbau.

## Offene Fragen

- **OF-01** · Soll die Auslieferung notarisiert werden (FB-01)? Das setzt eine
  Mitgliedschaft im Apple Developer Program (99 USD/Jahr) voraus. Bei „Visitenkarte für
  Auftragsarbeit" als Zweck ist die Frage nicht rein technisch: Eine App, die beim ersten
  Start eine Sicherheitswarnung auslöst, wirbt schlecht. — *Betreiber, vor dem nächsten
  Release.*
- **OF-02** · Soll `--deep` aus dem Signierschritt entfernt werden (FB-02)? Ohne
  Notarisierung ist die praktische Auswirkung heute gering, mit Notarisierung wäre es
  ein Hindernis. Zusammen mit OF-01 zu entscheiden. — *Betreiber.*
- **OF-03** · Soll das Release automatisiert werden (FB-06, FB-07)? Ein Skript, das
  baut, signiert, das DMG erzeugt, `sign_update` aufruft und den appcast-Eintrag
  schreibt, würde drei Fehlerquellen auf einmal schließen. — *Betreiber, ohne Frist.*

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Bundle-Erzeugung | eigenes Shell-Skript | SPM baut kein `.app`; XcodeGen hätte ein zweites Werkzeug bedeutet |
| 2 | Signatur | ad-hoc (`--sign -`) | Kein Developer-ID-Zertifikat im Einsatz. Reicht lokal, nicht für Vertrieb — siehe FB-01 |
| 3 | Hardened Runtime | eingeschaltet | Voraussetzung für spätere Notarisierung; kostet nichts |
| 4 | Library Validation | abgeschaltet | Notlösung für das ad-hoc signierte Sparkle — siehe FB-03 |
| 5 | DMG-Werkzeug | zwei Wege | `create-dmg` liefert das bessere Ergebnis, `hdiutil` läuft ohne Homebrew. Sinnvoll für einen Rechnerwechsel |
| 6 | DMG-Hintergrund | aus Swift erzeugt | Bleibt versioniert und reproduzierbar, statt als Binärdatei im Repository zu liegen |
