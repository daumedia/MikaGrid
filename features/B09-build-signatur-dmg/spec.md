# B09 · Build-, Signatur- und DMG-Kette — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1 · Repariert in: v1.2.0 · Repariert in: v1.2.0

> **Rückerfassung, danach repariert.** Erfasst aus v1.1.1, überarbeitet in **v1.2.0**
> (2026-08-25). Die Kriterien beschreiben den Stand **nach** der Reparatur; was vorher
> anders war, steht in Klammern dabei. ⚠ markiert die Punkte, die **nicht** aus dem
> Repository heraus lösbar sind.

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
- **AK-11** ⚠ · Angenommen, ein Nutzer lädt das ausgelieferte DMG und öffnet die App, wenn
  Gatekeeper prüft, dann fragt macOS beim ersten Start nach einer Bestätigung.
  *(Signiert wird seit 1.2.0 mit einer Developer ID; `spctl` meldet jetzt
  `source=Unnotarized Developer ID` statt einer rundweg abgelehnten Ad-hoc-Signatur. Die
  Notarisierung steht noch aus — der Marker bleibt deshalb stehen. Siehe FB-01.)*
- **AK-12** · Angenommen, die Kette hat Sparkles Bestandteile einzeln von innen nach außen
  signiert, wenn anschließend das Gesamtbundle signiert wird, dann bleiben diese Signaturen
  erhalten und die Bestandteile behalten ihre eigenen (leeren) Entitlements.
  *(Bis 1.1.1 rief das Skript `codesign --force --deep --entitlements …` auf das ganze
  Bundle und machte die vorherigen Schritte damit wirkungslos: `Downloader.xpc`,
  `Installer.xpc` und `Updater.app` trugen anschließend `disable-library-validation`,
  obwohl Sparkle sie ohne jede Entitlement ausliefert. Nachgeprüft am gebauten Bundle:
  jetzt leer.)*

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

## Behobener Fehlbestand

- **FB-01 ⚠ Keine Notarisierung.**
  **Teilweise behoben:** Signiert wird mit `Developer ID Application: Michael Rodrigues
  (CWJM4J4HFN)`; `scripts/build.sh` findet die Identität selbst und fällt nur lokal auf
  ad-hoc zurück. Die **Notarisierung** ist in `scripts/release.sh` vorbereitet und läuft,
  sobald `NOTARY_PROFILE` gesetzt ist — die Zugangsdaten dafür gehören nicht ins
  Repository und müssen einmalig eingerichtet werden:
  `xcrun notarytool store-credentials MikaGrid --apple-id <id> --team-id CWJM4J4HFN
  --password <app-spezifisch>`. **Der einzige verbliebene Punkt dieses Features.**
- **FB-02 ✅ `codesign --deep` beim Signieren.**
  **Behoben:** `--deep` ist aus dem Signierschritt entfernt. Nachgeprüft am gebauten
  Bundle: Sparkles XPC-Dienste tragen wieder leere Entitlements.
- **FB-03 ✅ `disable-library-validation` war ein Symptom.**
  **Behoben und nachgewiesen:** Die Entitlement ist entfernt. Ein Bau ohne sie startet und
  lädt Sparkle einwandfrei (geprüft: Prozess läuft, `Sparkle.framework` im Adressraum).
  Für Ad-hoc-Bauten ergänzt `build.sh` sie automatisch, weil dort ohne gemeinsame
  Team-Kennung tatsächlich kein Laden möglich ist. Der Hardened Runtime ist damit im
  Auslieferungsfall nicht mehr abgeschwächt.
- **FB-04 ✅ Das Einbetten von Sparkle scheiterte lautlos.**
  **Behoben:** Fehlt das Framework, bricht das Skript mit einer Erklärung ab, statt ein
  Bundle zu erzeugen, das nicht aktualisieren kann und beim Start abstürzt.
- **FB-05 ✅ Das DMG wurde weder signiert noch geprüft.**
  **Behoben:** `release.sh` signiert es mit derselben Identität und prüft danach.
- **FB-06 ✅ Die Sparkle-Signatur entstand von Hand.**
  **Behoben:** `release.sh` ruft `sign_update` auf, gibt den fertigen Eintrag aus und
  **verifiziert** die im Feed stehende Signatur gegen das eben gebaute DMG.
- **FB-07 ✅ Kein Freigabeschritt prüfte die Zusammengehörigkeit.**
  **Behoben:** `release.sh --check` vergleicht `Info.plist`, `CHANGELOG.md`, `appcast.xml`
  und `web/lib/app.ts`; `scripts/check-web-sync.mjs` vergleicht zusätzlich die
  Aktionsliste und die DMG-Größe. Beides läuft in der CI bei jedem Push.
- **FB-08 ✅ Kein Universal Binary.**
  **Behoben:** `build.sh --universal` baut für arm64 und x86_64; `release.sh` benutzt das.

## Entschiedene Fragen

- **OF-01 ⚠ Die Auslieferung soll notarisiert werden** — die Entscheidung ist gefallen, die
  Ausführung steht aus. Ein Developer-ID-Zertifikat ist vorhanden, die Mitgliedschaft
  besteht also bereits; es fehlt nur das einmalige Hinterlegen der
  App-Store-Connect-Zugangsdaten. Siehe FB-01.
- **OF-02 ✅ `--deep` ist aus dem Signierschritt entfernt.**
- **OF-03 ✅ Das Release ist automatisiert** — `scripts/release.sh` deckt Bau, Signatur,
  Notarisierung, DMG, appcast-Signatur, Konsistenzprüfung und den Hinweis auf den
  Feed-Zweig ab.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Bundle-Erzeugung | eigenes Shell-Skript | SPM baut kein `.app`; XcodeGen hätte ein zweites Werkzeug bedeutet |
| 2 | Signatur | ad-hoc (`--sign -`) | Kein Developer-ID-Zertifikat im Einsatz. Reicht lokal, nicht für Vertrieb — siehe FB-01 |
| 3 | Hardened Runtime | eingeschaltet | Voraussetzung für spätere Notarisierung; kostet nichts |
| 4 | Library Validation | abgeschaltet | Notlösung für das ad-hoc signierte Sparkle — siehe FB-03 |
| 5 | DMG-Werkzeug | zwei Wege | `create-dmg` liefert das bessere Ergebnis, `hdiutil` läuft ohne Homebrew. Sinnvoll für einen Rechnerwechsel |
| 6 | DMG-Hintergrund | aus Swift erzeugt | Bleibt versioniert und reproduzierbar, statt als Binärdatei im Repository zu liegen |
