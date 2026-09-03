# Vor der Einreichung

> **Freigegeben am 2026-09-03.** Die App steht als `id6805495907` im Mac App Store:
> <https://apps.apple.com/app/id6805495907>. Diese Liste bleibt stehen, weil sie bei jeder
> weiteren Fassung wieder durchzugehen ist. Abgehakt ist, **was die Freigabe belegt** —
> ohne App-Datensatz, Store-Zertifikat und beantwortete Fragebögen kommt keine zustande.
> Was sich aus dem Repository heraus nicht nachprüfen lässt, steht unter
> „Nicht nachprüfbar" und wartet auf eine Bestätigung.

Was im Repository liegt, ist fertig. Offen war nur, was sich ausschließlich im
Apple-Konto oder auf einem fremden Dienst erledigen lässt.

## Zwei Entscheidungen — unentschieden ausgeliefert

Beides sind Produktänderungen, keine Metadaten — deshalb stehen sie hier und wurden nicht
mit dem Store-Paket miterledigt.

**Nachtrag 2026-09-03:** Beide Kästchen sind leer geblieben, und die Fassung ist trotzdem
eingereicht **und durchgekommen**. Im Quelltext nachgesehen: `NSAppleEventsUsageDescription`
in `Resources/Info-MAS.plist` ist unverändert deutsch, `CFBundleDevelopmentRegion` fehlt
weiterhin ganz, und `ShortcutsWindowSnapper` beantwortet `.restore` nach wie vor mit
`.nothingToRestore`, während `PopoverGridView` alle elf Zonen zeigt. Die Prüfung hat daran
keinen Anstoß genommen. Beide Punkte bleiben damit **offen als Verbesserung**, nicht mehr
als Risiko vor der Einreichung — sie gehören in die nächste Fassung, nicht in eine
Nachreichung.

- [ ] **Der deutsche Systemdialog.** `NSAppleEventsUsageDescription` in
      `Resources/Info-MAS.plist` ist auf Deutsch formuliert, während Oberfläche, Website
      und Store-Eintrag englisch sind. Der Satz erscheint im Systemdialog, mit dem macOS
      die Erlaubnis zur Steuerung von Kurzbefehlen erfragt — auch der Prüfung, die auf
      Englisch arbeitet. Unklare Zweckangaben sind ein bekannter Ablehnungsgrund
      (Guideline 5.1.1).
      Vorschlag: den Schlüssel auf Englisch umstellen und `CFBundleDevelopmentRegion` auf
      `en` setzen; eine deutsche Fassung kann später über `de.lproj/InfoPlist.strings`
      dazukommen — das ist der vorgesehene Weg, nicht der Haupteintrag.

- [ ] **Die Restore-Zone im Popover.** `PopoverGridView` zeigt alle elf Zonen; in der
      Store-Fassung meldet die elfte „Nothing to restore", weil Kurzbefehle keine
      Fensterrahmen zurückgibt. Das ist ehrlich beschriftet und kein Fehler — aber ein
      Screenshot des Popovers zeigt elf Zonen, während die Beschreibung von zehn Aktionen
      spricht. Entweder die Zone in der Store-Fassung ausgrauen (`WindowSnapping` um die
      unterstützten Aktionen erweitern), oder es so lassen und in Kauf nehmen, dass Bild
      und Text auf den zweiten Blick auseinandergehen.
      Die ausgelieferten Screenshots hier heben die Zone nicht hervor.

## Im Apple Developer Account

- [x] **Store-Zertifikat erzeugen** — *3rd Party Mac Developer Application* oder
      *Apple Distribution*. Ein *Developer ID*-Zertifikat genügt **nicht**; es signiert
      den Direktvertrieb, nicht den Store.
      Prüfen mit `security find-identity -v -p codesigning`.
      Am 2026-08-26 war nur `Developer ID Application: Michael Rodrigues (CWJM4J4HFN)`
      vorhanden; die Freigabe belegt, dass das Store-Zertifikat seither dazugekommen ist.
- [x] **Provisioning Profile** für `lu.daumedia.mikagrid` (Mac App Store) anlegen und
      laden.
- [x] **App-Datensatz in App Store Connect** anlegen: Name, Bundle-ID, SKU aus
      [APP_STORE_CONNECT.md](APP_STORE_CONNECT.md).
      **Nur eine Kennung**, `lu.daumedia.mikagrid` — beide Fassungen teilen sie
      (OF-04). Ältere Artefakte nennen `lu.daumedia.mikagrid.mas`; die ist hinfällig
      und darf nicht angelegt werden.
      Die Apple-ID des Datensatzes ist **6805495907**.

## Beim Hochladen

- [x] `bash scripts/release.sh --store` — archiviert, prüft die Pflichtschlüssel und
      lädt hoch. *(Ein Bau ist hochgeladen und freigegeben; über welchen Weg, hält das
      Repository nicht fest — siehe „Nicht nachprüfbar".)*

      Ob die Projektstruktur trägt, lässt sich **ohne** Store-Zertifikat prüfen:

      ```bash
      xcodegen generate
      xcodebuild archive -project MikaGrid.xcodeproj -scheme "MikaGrid (App Store)" \
        -destination "generic/platform=macOS" -archivePath /tmp/Probe.xcarchive \
        CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
      /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" /tmp/Probe.xcarchive/Info.plist
      ```

      Kommt dort ein Block mit `ApplicationPath = Applications/Mika+Grid.app`, ist es
      ein App-Archiv. Fehlt `ApplicationProperties` ganz, bietet Xcode beim Verteilen
      nur „Custom" an.
- [x] **Kategorie in App Store Connect auf *Produktivität* setzen.** Sie muss zu
      `LSApplicationCategoryType` in `Resources/Info-MAS.plist` passen
      (`public.app-category.productivity`), sonst weist der Upload mit Fehler 90242 ab.
- [x] Texte aus `metadata/en-US/` einsetzen, Screenshots aus
      `screenshots/en-US/mac-2880x1800/` in Nummernreihenfolge hochladen.
- [x] Datenschutz-Fragebogen: durchgehend **Data Not Collected**.
- [x] Altersfreigabe-Fragebogen: alle 24 Kategorien „Nein"/„Nie", Ergebnis **4+**.
      Antworten und Belege in [ALTERSFREIGABEN.md](ALTERSFREIGABEN.md).
- Prüfungshinweise aus [APP_STORE_CONNECT.md](APP_STORE_CONNECT.md) eintragen.
      **Nicht auslassen:** Ohne den Hinweis auf die einmalige Zustimmung zur Steuerung
      von Kurzbefehlen hält ein Prüfer die App für kaputt — der erste Snap liefert dann
      eine leere Antwort ohne Fehlermeldung. *(Siehe „Nicht nachprüfbar".)*

## Außerhalb des Apple-Kontos

- [x] **`grid.daumedia.lu` veröffentlichen.** Die drei URL-Dateien in `metadata/en-US/`
      zeigen dorthin, und Apple prüft sie. Das Vercel-Projekt baut bereits; es fehlt die
      Subdomain und ein Produktivstand. Weicht die Adresse ab, sind
      `metadata/en-US/*_url.txt` **und** `web/lib/app.ts` (`siteUrl`) nachzuziehen.
- [x] Prüfen, dass `/privacy` unter dieser Adresse erreichbar ist — sie ist die
      Datenschutz-URL des Store-Eintrags. *(2026-09-03: beide antworten mit HTTP 200.)*

## Nicht nachprüfbar

Steht offen, weil das Repository darüber nichts weiß — nicht, weil es nachweislich fehlt.
Eine kurze Bestätigung genügt, dann wandern die Punkte nach oben.

- [ ] **App-Store-Connect-Schlüssel** erzeugen und als `ASC_KEY_ID`, `ASC_ISSUER_ID`
      und `ASC_KEY_PATH` hinterlegen — ohne sie exportiert `release.sh --store` nur,
      statt hochzuladen. Wurde stattdessen aus Xcode oder mit Transporter hochgeladen,
      fehlt der Schlüssel weiterhin und der Weg über `release.sh --store` ist beim
      nächsten Mal wieder von Hand zu gehen.
- [ ] **Prüfungshinweise** aus [APP_STORE_CONNECT.md](APP_STORE_CONNECT.md) eingetragen?
      Die Freigabe belegt es nicht — Hinweise sind freiwillig. Fehlen sie, ist das beim
      nächsten Einreichen nachzuholen: Ohne den Hinweis auf die einmalige Zustimmung zur
      Steuerung von Kurzbefehlen hält ein Prüfer die App für kaputt.

## Nur für den Direktvertrieb (nicht Store-relevant)

- [ ] **Notarisierung einrichten**: einmalig
      `xcrun notarytool store-credentials MikaGrid --apple-id <mail> --team-id CWJM4J4HFN --password <app-spezifisch>`,
      danach erledigt `scripts/release.sh` den Rest.

## Zuletzt

- [x] `swift test` — alle Prüfungen grün, einschließlich `StoreAssetTests`.
      *(2026-09-03: 86 Tests in 12 Suiten, grün.)*
- [x] `bash scripts/release.sh --check` und `node scripts/check-web-sync.mjs`.
      *(2026-09-03 beide grün. **Achtung:** `--check` vergleicht nur Zeichenketten. Die
      in `web/lib/app.ts` hinterlegte DMG-Adresse zeigt auf ein Release `v1.2.0`, das es
      auf GitHub nicht gibt — der Download-Knopf der Website läuft ins Leere.)*
- [x] Version in `Resources/Info.plist`, `Resources/Info-MAS.plist`, `CHANGELOG.md` und
      `web/lib/app.ts` stimmt überein. *(Überall 1.2.0, Build 3.)*
