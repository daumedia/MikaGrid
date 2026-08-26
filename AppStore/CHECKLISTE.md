# Vor der Einreichung

Was im Repository liegt, ist fertig. Offen ist nur noch, was sich ausschließlich im
Apple-Konto oder auf einem fremden Dienst erledigen lässt.

## Zwei Entscheidungen vorher

Beides sind Produktänderungen, keine Metadaten — deshalb stehen sie hier und wurden nicht
mit dem Store-Paket miterledigt.

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

- [ ] **Store-Zertifikat erzeugen** — *3rd Party Mac Developer Application* oder
      *Apple Distribution*. Ein *Developer ID*-Zertifikat genügt **nicht**; es signiert
      den Direktvertrieb, nicht den Store.
      Prüfen mit `security find-identity -v -p codesigning`.
      Zuletzt geprüft am 2026-08-26: vorhanden ist nur
      `Developer ID Application: Michael Rodrigues (CWJM4J4HFN)` — das Store-Zertifikat
      fehlt also noch.
- [ ] **Provisioning Profile** für `lu.daumedia.mikagrid` (Mac App Store) anlegen und
      laden.
- [ ] **App-Datensatz in App Store Connect** anlegen: Name, Bundle-ID, SKU aus
      [APP_STORE_CONNECT.md](APP_STORE_CONNECT.md).
      **Nur eine Kennung**, `lu.daumedia.mikagrid` — beide Fassungen teilen sie
      (OF-04). Ältere Artefakte nennen `lu.daumedia.mikagrid.mas`; die ist hinfällig
      und darf nicht angelegt werden.
- [ ] **App-Store-Connect-Schlüssel** erzeugen und als `ASC_KEY_ID`, `ASC_ISSUER_ID`
      und `ASC_KEY_PATH` hinterlegen — ohne sie exportiert `release.sh --store` nur,
      statt hochzuladen.

## Beim Hochladen

- [ ] `bash scripts/release.sh --store` — archiviert, prüft die Pflichtschlüssel und
      lädt hoch.

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
- [ ] **Kategorie in App Store Connect auf *Produktivität* setzen.** Sie muss zu
      `LSApplicationCategoryType` in `Resources/Info-MAS.plist` passen
      (`public.app-category.productivity`), sonst weist der Upload mit Fehler 90242 ab.
- [ ] Texte aus `metadata/en-US/` einsetzen, Screenshots aus
      `screenshots/en-US/mac-2880x1800/` in Nummernreihenfolge hochladen.
- [ ] Datenschutz-Fragebogen: durchgehend **Data Not Collected**.
- [ ] Altersfreigabe-Fragebogen: alle 24 Kategorien „Nein"/„Nie", Ergebnis **4+**.
      Antworten und Belege in [ALTERSFREIGABEN.md](ALTERSFREIGABEN.md).
- [ ] Prüfungshinweise aus [APP_STORE_CONNECT.md](APP_STORE_CONNECT.md) eintragen.
      **Nicht auslassen:** Ohne den Hinweis auf die einmalige Zustimmung zur Steuerung
      von Kurzbefehlen hält ein Prüfer die App für kaputt — der erste Snap liefert dann
      eine leere Antwort ohne Fehlermeldung.

## Außerhalb des Apple-Kontos

- [ ] **`grid.daumedia.lu` veröffentlichen.** Die drei URL-Dateien in `metadata/en-US/`
      zeigen dorthin, und Apple prüft sie. Das Vercel-Projekt baut bereits; es fehlt die
      Subdomain und ein Produktivstand. Weicht die Adresse ab, sind
      `metadata/en-US/*_url.txt` **und** `web/lib/app.ts` (`siteUrl`) nachzuziehen.
- [ ] Prüfen, dass `/privacy` unter dieser Adresse erreichbar ist — sie ist die
      Datenschutz-URL des Store-Eintrags.

## Nur für den Direktvertrieb (nicht Store-relevant)

- [ ] **Notarisierung einrichten**: einmalig
      `xcrun notarytool store-credentials MikaGrid --apple-id <mail> --team-id CWJM4J4HFN --password <app-spezifisch>`,
      danach erledigt `scripts/release.sh` den Rest.

## Zuletzt

- [ ] `swift test` — alle Prüfungen grün, einschließlich `StoreAssetTests`.
- [ ] `bash scripts/release.sh --check` und `node scripts/check-web-sync.mjs`.
- [ ] Version in `Resources/Info.plist`, `Resources/Info-MAS.plist`, `CHANGELOG.md` und
      `web/lib/app.ts` stimmt überein.
