# 01 · App-Store-Vertrieb — Spezifikation

Status: `deployed` · Stand: 2026-09-03

> **Erstes Feature im Vorwärts-Namensraum.** Anders als B01–B10 entsteht dieses gegen eine
> Anforderung, nicht rückwirkend aus dem Bestand. Es erweitert die Bestandsfeatures
> B01, B03, B04, B06 und B09, ohne sie zu ersetzen.

## Zweck

Mika+Grid erscheint im Mac App Store und ist damit für Menschen auffindbar, die niemals
auf GitHub nach einem Fensterverwalter suchen. Weil der Store die Accessibility-API
verbietet, bewegt die Store-Fassung Fenster über Apples Shortcuts-App statt selbst — der
Direktvertrieb bleibt unverändert.

## Ausgangslage

Der Store lässt neuen Apps keinen anderen Weg. Belegt, nicht vermutet:

- **Sandboxing ist Pflicht** für jede Neueinreichung.
- **Die Sandbox verbietet die Accessibility-API ausdrücklich.** Apples eigene
  Dokumentation führt „Use of accessibility APIs in assistive apps" auf der Liste der in
  der Sandbox unzulässigen Tätigkeiten. Apple DTS im Entwicklerforum: *„AFAICT your only
  path forward here is to directly distribute your app using Developer ID signing."*
- **Magnet, Moom und BetterSnapTool sind kein Gegenbeweis.** Sie waren vor der
  Sandbox-Pflicht im Store und genießen Bestandsschutz.
- **Der gangbare Weg ist Shortcuts.** Die App berechnet Zielrahmen und lässt Apples
  Shortcuts-App die Fenster bewegen, angesprochen über Apple Events. Mindestens drei Apps
  sind so im Store: snApp (2023), Align (2024) und 941 Tiles (2026, nach einer Ablehnung
  und erneuter Prüfung genehmigt).

Damit korrigiert dieses Feature eine Aussage im PRD: „Die Sandbox schließt den App Store
aus" gilt für den **heutigen Bauweg**, nicht für das Produkt.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 Fenster snappen | rekonstruiert | Die Zielgeometrie wird geteilt — `SnapAction.targetFrame` bleibt die Wahrheit für beide Ziele |
| B03 Globale Tastenkürzel | rekonstruiert | Carbon-Kürzel funktionieren auch in der Sandbox; sie lösen künftig beide Wege aus |
| B04 Menüleisten-Popover | rekonstruiert | Die Oberfläche ist dieselbe, mit einem zusätzlichen Zustand für „Shortcut fehlt" |
| B06 Erststart-Onboarding | rekonstruiert | Bekommt einen Schritt für die Einrichtung des Shortcuts |
| B09 Build-, Signatur- und DMG-Kette | rekonstruiert | Wird um ein zweites Ziel und einen zweiten Signaturweg erweitert, nicht ersetzt |

## User Stories

- **US-01** · Als Mac-Nutzer möchte ich Mika+Grid im App Store finden und mit einem Klick
  installieren, damit ich mich nicht mit DMG, Gatekeeper und Rechtsklick befassen muss.
- **US-02** · Als Betreiber möchte ich beide Fassungen aus einem Quelltext bauen, damit
  eine Fehlerbehebung nicht zweimal geschrieben werden muss.
- **US-03** · Als Nutzer der Store-Fassung möchte ich beim ersten Start durch die
  Einrichtung geführt werden, damit ich nicht selbst herausfinde, was ein „Companion
  Shortcut" ist.
- **US-04** · Als Nutzer der DMG-Fassung möchte ich, dass sich für mich nichts ändert.

## Nicht im Scope

- **Die Notarisierung des Direktvertriebs.** Das ist B09/FB-01 und bleibt dort.
- **Der Umbau der Direktfassung auf Shortcuts.** Sie behält die Accessibility-API und
  damit ihre heutige Zuverlässigkeit und ihr Mindestsystem macOS 14.
- **Neue Snap-Aktionen.** Der Umfang bleibt bei elf; „auf nächsten Bildschirm" und „eigene
  Raster" sind weiterhin eigene, ungebaute Features.
- **Eine iOS- oder iPadOS-Fassung.**
- **Bezahlmodell und In-App-Käufe.** Die App bleibt kostenlos (PRD, Monetarisierung).

## Akzeptanzkriterien

### A · Bauwege

- **AK-01** · Angenommen, ein frischer Klon des Repositories, wenn das Xcode-Projekt
  geöffnet und das Schema „MikaGrid (Direct)" gebaut wird, dann entsteht eine App, die
  sich verhält wie die heutige Fassung 1.2.0.
- **AK-02** · Angenommen dasselbe, wenn das Schema „MikaGrid (App Store)" gebaut wird,
  dann entsteht eine App mit aktivierter Sandbox
  (`com.apple.security.app-sandbox = true`) und **ohne** eingebettete Sparkle.framework.
- **AK-03** · Angenommen, das Store-Ziel wird gebaut, wenn seine Entitlements gelesen
  werden, dann enthalten sie `com.apple.security.automation.apple-events` und die
  Ausnahme für Shortcuts — und **keine** Entitlement, die es im Direktziel nicht gibt.
- **AK-04** · Angenommen, `swift test` läuft, dann laufen dieselben Tests wie heute
  weiterhin durch — die Umstellung auf ein Xcode-Projekt darf sie nicht verlieren.
- **AK-05** · Angenommen, `bash scripts/build.sh` wird aufgerufen, dann baut es weiterhin
  das Direktziel als DMG-fähiges Bundle. Der bestehende Weg bleibt bedienbar.
- **AK-06** · Angenommen, das Store-Ziel wird archiviert, wenn die Archivierung
  durchläuft, dann lässt sich das Ergebnis ohne Fehler an App Store Connect übergeben.

### B · Fenster bewegen über Shortcuts

- **AK-07** · Angenommen, die Store-Fassung läuft, der Companion-Shortcut ist eingerichtet
  und ein veränderbares Fenster ist aktiv, wenn ⌃⌥← gedrückt wird, dann füllt das Fenster
  binnen einer Sekunde die linke Hälfte des nutzbaren Bereichs.
- **AK-08** · Angenommen dasselbe, wenn eine beliebige der elf Aktionen ausgelöst wird,
  dann sitzt das Fenster anschließend an derselben Stelle, an der die Direktfassung es
  ablegen würde — geprüft durch Vergleich beider Fassungen auf demselben Bildschirm.
- **AK-09** · Angenommen, „Zentriert" wird ausgelöst, dann belegt das Fenster zwei Drittel
  der Breite und zwei Drittel der Höhe. *(Der Store-Weg muss dafür freie Pixelmaße
  benutzen; die eingebauten Vorgaben von Shortcuts kennen diese Aufteilung nicht.)*
- **AK-10** · Angenommen, mehrere Bildschirme sind angeschlossen, wenn ein Fenster
  gesnappt wird, dann geschieht das auf dem Bildschirm, auf dem es steht.
- **AK-11** · Angenommen, ein Snap wird ausgelöst, wenn er abgeschlossen ist, dann ist
  **kein** Fenster der Shortcuts-App sichtbar geworden und der Vordergrund hat nicht
  gewechselt.
- **AK-12** · Angenommen, das Zielfenster liegt nah am rechten oder unteren Bildschirmrand,
  wenn ein Snap ausgelöst wird, dann sitzt es danach trotzdem korrekt. *(Für Shortcuts ist
  ein Fehler dokumentiert, bei dem randnahe Fenster nicht richtig skaliert werden; der
  Bauweg muss ihn umgehen.)*

### C · Einrichtung

- **AK-13** · Angenommen, die Store-Fassung wird zum ersten Mal gestartet, dann führt das
  Onboarding einen zusätzlichen Schritt, der den Companion-Shortcut erzeugt und zur
  Installation öffnet.
- **AK-14** · Angenommen, dieser Schritt ist sichtbar und der Nutzer installiert den
  Shortcut, dann erkennt die App das binnen etwa einer Sekunde selbsttätig und blättert
  weiter — wie heute schon bei der Berechtigung.
- **AK-15** · Angenommen, der Shortcut ist eingerichtet, wenn zum ersten Mal ein Snap
  ausgelöst wird, dann fragt macOS **einmalig** um Erlaubnis, Shortcuts zu steuern.
- **AK-16** · Angenommen, der Nutzer verweigert diese Erlaubnis, wenn er einen Snap
  auslöst, dann erklärt die App, was fehlt, und führt in die Systemeinstellungen —
  statt wortlos nichts zu tun.
- **AK-17** · Angenommen, der Companion-Shortcut wurde gelöscht, wenn ein Snap ausgelöst
  wird, dann erscheint ein Hinweis mit der Möglichkeit, ihn neu einzurichten.
- **AK-18** · Angenommen, der Companion-Shortcut wurde verändert, wenn ein Snap ausgelöst
  wird, dann verweigert die App den Aufruf, nennt den Grund und bietet die
  Neueinrichtung an.

### D · Store-Auftritt

- **AK-19** · Angenommen, ein Besucher findet die App im Store, dann heißt sie
  „Mika+Grid", kostet nichts und nennt als Mindestsystem macOS 15.
- **AK-20** · Angenommen, die Store-Seite wird gelesen, dann steht dort vor dem Download,
  dass ein Shortcut eingerichtet werden muss — nicht erst nach der Installation.
- **AK-21** · Angenommen, die Datenschutzangaben des Stores werden geprüft, dann geben sie
  an, dass keine Daten erhoben werden.
- **AK-22** ⚠ · ~~Angenommen, eine neue Fassung erscheint im Store, wenn ein Nutzer der
  DMG-Fassung nach Updates sucht, dann bekommt er weiterhin die DMG-Fassung über Sparkle
  angeboten — die beiden Vertriebswege stören einander nicht.~~
  **Hinfällig seit der Entscheidung zu OF-04 (2026-08-26).** Beide Fassungen tragen
  dieselbe Bundle-Kennung und sind deshalb nicht nebeneinander installierbar. Was bleibt
  und weiter gilt: Die Store-Fassung liefert **kein** Sparkle mit und trägt keinen
  Update-Feed (das deckt AK-02 ab). Wer beide Wege gleichzeitig ausspielen will, muss
  OF-04 zurücknehmen.

### E · Datenschutz und Missbrauchsschutz

Geprüft gegen `~/.claude/sdd/sicherheit.md`.

- **AK-23** ⚠ · Angenommen, ein Snap läuft über Shortcuts, wenn geprüft wird, welche
  Angaben die App übergibt, dann können darunter **Fenstertitel** sein.
  *(Bewusst entschieden — siehe Decision Log 6. Die Titel bleiben auf dem Gerät und gehen
  ausschließlich an eine System-App, aber es ist eine Verarbeitung, die PRD und
  Datenschutzseite heute ausschließen. Beide sind vor der Auslieferung anzupassen; siehe
  Folgeaufträge.)*
- **AK-24** · Angenommen, ein Snap läuft über Shortcuts, wenn der Netzwerkverkehr
  beobachtet wird, dann entsteht keiner. Fenstertitel verlassen das Gerät nicht.
- **AK-25** · Angenommen, die Store-Fassung läuft, wenn geprüft wird, welche
  Systemberechtigungen sie verlangt, dann ist es genau eine: Automatisierung von
  Shortcuts. **Keine** Bedienungshilfen, **keine** Eingabeüberwachung.
- **AK-26** · Angenommen, der Companion-Shortcut wird geprüft, wenn sein Inhalt vom
  erwarteten Aufbau abweicht, dann ruft die App ihn nicht auf. *(Verhindert, dass ein
  ersetzter Shortcut fremde Aktionen unter dem Namen von Mika+Grid ausführt.)*
- **AK-27** · Angenommen, die Store-Fassung wird gebaut, wenn ihre Ablagen geprüft werden,
  dann speichert sie nichts außerhalb ihres Sandbox-Containers.
- **AK-28** · Angenommen, das Repository wird durchsucht, dann enthält es **keine**
  App-Store-Connect-Zugangsdaten, kein Signaturzertifikat und keinen API-Schlüssel.
- **Rate Limits:** treffen nicht zu — kein Endpunkt, keine Kosten je Aufruf. Die
  Aufruffrequenz begrenzt der Nutzer selbst durch Tastendrücke.
- **Rollen und Zugriffsregeln:** treffen nicht zu — keine Konten, keine fremden Datensätze.
- **Löschen und Auskunft:** treffen nicht zu — es entstehen keine personenbezogenen
  Datensätze. Beim Entfernen der App verschwindet der Sandbox-Container; der
  Companion-Shortcut bleibt in der Mediathek des Nutzers und ist dort von Hand zu löschen.
  Das gehört auf die Store-Seite und in die Datenschutzangaben.

## Edge Cases

- **EC-01** · Shortcuts-App vom Nutzer entfernt oder deaktiviert → Hinweis wie bei AK-17.
- **EC-02** · Der Nutzer hat einen eigenen Shortcut gleichen Namens → die Prüfung aus
  AK-18 greift; die App bietet einen abweichenden Namen an, statt fremde Arbeit zu
  überschreiben.
- **EC-03** · Zwei Fenster derselben App mit identischem Titel → die Zuordnung kann das
  falsche treffen. Bekannte Einschränkung, gehört auf die Store-Seite.
- **EC-04** · Shortcuts antwortet nicht innerhalb einer Sekunde → der Snap gilt als
  fehlgeschlagen und meldet das, statt die Oberfläche zu blockieren.
- **EC-05** · Der Nutzer löst zwei Snaps kurz hintereinander aus → sie laufen nacheinander,
  nicht überlappend.
- **EC-06** · macOS 14 lädt die Store-Fassung nicht → der Store verhindert das über das
  Mindestsystem; keine eigene Vorkehrung nötig.
- **EC-07** · Apple lehnt die Einreichung ab → siehe OF-01.

## Offene Fragen

- **OF-01** ✅ *Beantwortet durch die Freigabe (2026-09-03).* Apple hat die App
  angenommen; sie steht als `id6805495907` im Store. Der erwogene Vorabversuch mit einer
  minimalen Fassung wurde nicht gegangen — eingereicht wurde der vollständige Stand
  einschließlich des Onboarding-Schritts für den Companion-Kurzbefehl. Die damalige Sorge
  bleibt für künftige Fassungen gültig: Eine bestandene Prüfung ist keine Zusicherung für
  die nächste.
- **OF-02** ❌ *In T01 am Versuch geklärt: **nein**.* `Find Windows` liefert ein
  Fenster-Objekt, dessen Textdarstellung nur den Namen der Anwendung enthält; eine
  „Get Details of Windows"-Aktion existiert nicht. Damit ist „Position wiederherstellen"
  im Store-Ziel **nicht baubar** und Decision Log 4 nicht haltbar. Nachweis in
  `machbarkeit.md`.
- **OF-03** ✅ *Im Entwurf entschieden:* XcodeGen mit `project.yml` als Wahrheit, wie im
  `swiftui-ios`-Profil des Ökosystems. Die Tests hängen künftig an der Bibliothek
  `MikaGridCore` und bleiben damit erhalten.
- **OF-04** ✅ *Vom Betreiber am 2026-08-26 anders entschieden:* **eine Kennung für beide
  Fassungen — `lu.daumedia.mikagrid`.** In App Store Connect gibt es nur diese eine.
  Der Entwurf hatte `.mas` vorgesehen, damit beide Installationen nebeneinander bestehen
  können; das entfällt bewusst.

  **Preis, benannt statt verschwiegen:** Zwei Apps mit derselben Kennung sind nicht
  nebeneinander installierbar. Sie teilen die Einstellungen, LaunchServices kann sie nicht
  auseinanderhalten, und das Anmeldeobjekt (`SMAppService`) gilt für beide. **AK-22 ist
  damit nicht mehr erfüllbar**, solange beide Wege gleichzeitig laufen — siehe dort.
  Folgenlos, solange nur ein Vertriebsweg ausgespielt wird.
- **OF-05** · Wie erfährt ein Nutzer der DMG-Fassung, dass es die Store-Fassung gibt — und
  soll er das überhaupt? Ein Hinweis in der App wäre Werbung in eigener Sache.
  — *Betreiber, ohne Frist.*
- **OF-06** · AK-25 verlangt „genau eine Berechtigung: Automatisierung von Shortcuts".
  Der Entwurf hat einen zweiten Aufrufweg gefunden, der über das URL-Schema von Shortcuts
  läuft und **gar keine** Berechtigung bräuchte. Das wäre strenger als gefordert, verletzt
  aber den Wortlaut des Kriteriums. Zeigt der erste Bauschritt, dass dieser Weg taugt, ist
  AK-25 umzuformulieren auf „höchstens eine". — *Betreiber, nach dem ersten Bauschritt.*
  *(Aufgeworfen von `/sdd-architektur` am 2026-08-25.)*
  **T01-Ergebnis:** Der URL-Weg **taugt nicht** — er öffnet nachweislich ein Fenster der
  Shortcuts-App und verletzt AK-11. Umzuformulieren ist AK-25 trotzdem, aber aus einem
  anderen Grund: Der tragfähige Weg braucht `automation.apple-events` **und**
  `scripting-targets` — zwei Entitlement-Einträge für eine Berechtigung. *Jetzt
  entscheidbar.*

- **OF-07** ⚠ *Teilweise geklärt.* **AK-08 selbst ist erfüllt** — am ausgelieferten
  Kurzbefehl gemessen sitzt das Fenster exakt auf `SnapAction.targetFrame`
  (`x=0 y=33 756×949`, alle vier Werte getroffen), und das ist dieselbe Rechnung wie in
  der Direktfassung. **Was fehlt, ist die Selbstkontrolle:** Der Entwurf sah vor, dass die
  App den gesetzten Rahmen nachmisst (`actualX/Y/…`) — das kann Kurzbefehle nicht liefern
  (OF-02). Die Store-Fassung merkt also nicht, wenn eine Zielanwendung den Rahmen
  beschneidet (TextEdit rastert etwa auf Zeilenhöhen). Zu entscheiden ist nur noch, ob der
  Entwurf diese Rückmessung streichen soll. — *Betreiber.*

- **OF-08** ✅ (aus T01) · *Geklärt: `Move Window` setzt die Position exakt.* Der frühere
  Verdacht, `WFYCoordinate` werde ignoriert, war ein Messartefakt einer Dreierkette
  Move → Resize → Move. Mit reinem Verschieben trifft die Aktion den Sollwert bei jeder
  Fenstergröße, im selben Koordinatensystem wie `CGWindowListCopyWindowInfo`.
  **Auflage für T12:** Die Abfolge Position → Größe → Position ist einzeln nachzumessen —
  `Resize Window` verschiebt das Fenster, und der abschließende Move korrigierte das im
  Versuch nicht zuverlässig.

- **OF-12** ✅ *Gelöst.* Der gerechnete Zielrahmen erreicht den Kurzbefehl — nach vier
  Hürden, die alle nur am laufenden System zu finden waren: Zahlenfelder nehmen keinen
  Text an (Abhilfe: Aktion „Zahl"), der Filter greift nur mit festem Namen (Abhilfe: kein
  Filter, vorderstes Fenster), das Fensterobjekt veraltet (Abhilfe: vor jeder Aktion neu
  suchen), die Aktionen überholen sich (Abhilfe: zwei Pausen à 0,15 s). **AK-07 ist
  erfüllt**, Entwurfsentscheidung 9 trägt. Nachweise in `machbarkeit.md`.

- **OF-14** (neu, aus der QA) · **Entwurfsentscheidung 10 ist falsch begründet.** Sie
  schreibt für den Companion-Kurzbefehl „erst die Position, dann die Größe, dann die
  Position erneut" und nennt als Grund den dokumentierten Shortcuts-Fehler bei randnahen
  Fenstern. Übersehen wurde die Regel, die das Projekt seit 1.1.1 kennt und in `CLAUDE.md`
  festhält: macOS begrenzt einen Positionswechsel gegen die **aktuelle** Fenstergröße,
  weshalb die Direktfassung `size → position → size` schreibt. Mit der Reihenfolge aus dem
  Entwurf traf der Kurzbefehl in 0 von 5 Läufen; umgestellt in 10 von 10 (BF-01).
  `design.md` gehört an dieser Stelle korrigiert. — *Architektur.*

- **OF-13** (neu, aus T12) · **AK-23 ist gegenstandslos geworden — im guten Sinn.** Weil
  der Kurzbefehl ohne Filter arbeitet, braucht die Nutzlast weder Anwendungsnamen noch
  Fenstertitel; sie trägt fünf Zahlen und einen Zufallswert. Damit verarbeitet auch die
  Store-Fassung **nichts Personenbeziehbares**, und Decision Log 6 („Fenstertitel erlaubt,
  wenn nötig") ist hinfällig. PRD, `docs/datenschutz.md` und die Datenschutzseite wurden
  bereits auf die Fenstertitel-Regel umgeschrieben und sind nun **strenger als nötig** —
  sie gehören zurückgenommen. — *Betreiber.*

- **OF-11** (neu, aus T11) · **AK-26 ist nur teilweise erfüllbar.** Das Kriterium verlangt,
  den Aufruf zu unterlassen, „wenn sein **Inhalt** vom erwarteten Aufbau abweicht". Über
  die Skripting-Schnittstelle sind je Kurzbefehl aber nur `name`, `action count`,
  `accepts input`, `subtitle`, `folder`, `color` und `icon` lesbar — **was die Aktionen
  tun, ist nicht lesbar** (am System geprüft). Gebaut ist die stärkste mögliche Prüfung:
  Name, Aktionsanzahl und Eingabeverhalten. Sie erkennt einen versehentlich ersetzten oder
  umgebauten Kurzbefehl, aber keinen absichtlich mit gleicher Aktionszahl nachgebauten.
  Das Kriterium ist entsprechend abzuschwächen oder als teilweise erfüllt zu führen.
  — *Betreiber.*

- **OF-10** (neu, aus T01) · **AK-10 ist eingeschränkt.** `Move Window` nimmt **keine
  negativen Koordinaten** an: Ein Ziel auf einem Bildschirm oberhalb des Hauptbildschirms
  bleibt wirkungslos, obwohl der Shortcut fehlerfrei durchläuft. Bildschirme rechts oder
  unterhalb (positive Werte) sind ungetestet. Der vorgesehene Weg ist vermutlich der
  `Display`-Parameter der Aktion, dessen Werteformat unbekannt ist. Zu klären, bevor T12
  gebaut wird. — *Architektur, am Versuch zu klären.*

- **OF-09** (neu, aus T01) · **`design.md` liegt bei den Entitlements falsch.** Es
  behauptet, Shortcuts biete keine Zugriffsgruppen, und wählt deshalb die von Apple
  missbilligte `temporary-exception.apple-events`. Tatsächlich bietet `Shortcuts Events`
  die Gruppe `com.apple.shortcuts.run`; die Messung lief erfolgreich mit dem engeren
  `scripting-targets`. Das senkt das Prüfungsrisiko und gehört in den Entwurf, bevor T05
  gebaut wird. — *Architektur.*

## Folgeaufträge in anderen Artefakten

Nach Regel 3 nicht hier mitspezifiziert, sondern dort einzutragen:

| Wo | Was |
|---|---|
| `docs/prd.md` | Die Aussage „Sandbox schließt den App Store aus" korrigieren; Mindestsystem und Vertriebswege je Fassung trennen; die Fenstertitel-Regel aus AK-23 aufnehmen |
| `docs/datenschutz.md` | „Fenstertitel werden gar nicht mehr gelesen" gilt künftig nur für die Direktfassung |
| `web/app/privacy/page.tsx` | Dieselbe Präzisierung öffentlich |
| `features/B02` | Die Einschränkung aus EC-03 betrifft das Wiederherstellen; als Abhängigkeit vermerken |
| `features/index.md` | Dieses Feature aufnehmen (erledigt) |

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Überhaupt in den Store? | ja | Reichweite: Nutzer, die GitHub nie finden. Das Motiv ist Sichtbarkeit, nicht Geld |
| 2 | Wie, trotz Sandbox-Verbot? | über Shortcuts und Apple Events | Der einzige belegte Weg. Von drei Apps im Store bestätigt |
| 3 | Eine Fassung oder zwei? | **zwei Ziele, ein Quelltext** | Zuerst war „ganz umbauen" gewählt, dann „beide Wege parallel" — die zweite Antwort präzisiert die erste. Die Direktfassung behält AXUIElement, macOS 14 und Sparkle; nur das Store-Ziel arbeitet über Shortcuts |
| 4 | Was wird mit „Wiederherstellen"? | mitnehmen, mit dokumentierter Einschränkung | Zehn von elf Aktionen wären eine andere App. Die Ungenauigkeit bei gleichnamigen Fenstern wird benannt statt versteckt |
| 5 | Einrichtung des Shortcuts | geführt im Onboarding | Der Schritt ist die größte Absprunghürde; er gehört dorthin, wo der Nutzer ohnehin geführt wird |
| 6 | Fenstertitel über Apple Events | erlaubt, wenn nötig | Genauere Fensterzuordnung wiegt schwerer als die strengere Regel. **Preis:** PRD, `docs/datenschutz.md` und die Datenschutzseite müssen vor der Auslieferung angepasst werden — die heutige Zusage wäre sonst unwahr |
| 7 | Integrität des Shortcuts | vor jedem Aufruf prüfen | Die App löst sonst unter ihrem Namen aus, was in einem ersetzten Shortcut steht |
| 8 | Name und Preis im Store | „Mika+Grid", kostenlos | Wie im PRD. Ein abweichender Name kostet Wiedererkennung; ein Preis widerspräche MIT, weil jeder die App selbst bauen darf |
| 9 | Mindestsystem der Store-Fassung | macOS 15 | Die Fensteraktionen von Shortcuts setzen das voraus. Die Direktfassung bleibt bei 14 |

## Quellen

- Apple DTS zur Unvereinbarkeit von Sandbox und Accessibility-API:
  <https://developer.apple.com/forums/thread/805556>
- Erfahrungsbericht zum Shortcuts-Weg, einschließlich Prüfverlauf:
  <https://blakecrosley.com/blog/window-manager-mac-app-store-sandbox>
- Fensteraktionen in Shortcuts (`Find Windows`, `Move Window`, `Resize Window` mit freien
  Maßen): <https://www.mattmcadams.com/posts/2022/resizing-a-window-with-shortcuts/>
- Fensterkacheln in macOS 15: <https://support.apple.com/en-in/guide/mac-help/mchl9674d0b0>
