# App-Store-Paket — Mika+Grid

Alles, was App Store Connect für die Erstveröffentlichung braucht: Texte, Screenshots
und die Skripte, um beides jederzeit reproduzierbar neu zu erzeugen.

> **Vor der Einreichung:** [CHECKLISTE.md](CHECKLISTE.md) durchgehen — dort stehen die
> Pflichtangaben, die nur im Apple-Konto zu erledigen sind, und zwei Entscheidungen, die
> vorher fallen müssen.

Aufgebaut wie das Paket von Mika+FileScope, damit beide Projekte gleich funktionieren.
Wo etwas abweicht, steht der Grund dabei.

---

## Was wohin gehört

| In App Store Connect | Datei |
|---|---|
| App-Name | `metadata/<locale>/name.txt` |
| Untertitel | `metadata/<locale>/subtitle.txt` |
| Werbetext (jederzeit ohne Review änderbar) | `metadata/<locale>/promotional_text.txt` |
| Beschreibung | `metadata/<locale>/description.txt` |
| Keywords | `metadata/<locale>/keywords.txt` |
| Neue Funktionen | `metadata/<locale>/release_notes.txt` |
| Support-URL / Marketing-URL | `metadata/<locale>/support_url.txt`, `marketing_url.txt` |
| Datenschutz-URL | `metadata/<locale>/privacy_url.txt` |
| Screenshots (2880 × 1800) | `screenshots/<locale>/mac-2880x1800/NN_name.jpg` |

Die Dateinamen folgen der Fastlane-Konvention — ein späterer Wechsel auf
`fastlane deliver` funktioniert ohne Umbau.

Grunddaten, Kategorien, Prüfungshinweise und die Antworten des Datenschutz-Fragebogens
stehen in [APP_STORE_CONNECT.md](APP_STORE_CONNECT.md), die des
Altersfreigabe-Fragebogens in [ALTERSFREIGABEN.md](ALTERSFREIGABEN.md) — dort mit Beleg
aus dem Code, damit sie nach einem Feature-Umbau nachprüfbar bleiben.

## Sprachen

**`en-US` ist die einzige Lokalisierung und die Primärsprache.** Das ist keine
Sparsamkeit, sondern Konsequenz: Die Oberfläche der App ist englisch, und eine deutsche
Headline über einem englischen Fenster liest sich wie ein Fehler.

Die Struktur ist trotzdem mehrsprachig angelegt. Eine weitere Sprache kostet einen Ordner
unter `metadata/`, einen Block in `tools/shots.json`, einen Eintrag in `SPRACHE`
(`tools/compose.swift`) und eine Zeile in `locales` (`Tests/MikaGridTests/StoreAssetTests.swift`)
— plus eigene Rohaufnahmen, sobald die App selbst übersetzt ist.

## Was die Texte über diese Fassung sagen müssen

Zwei Zusagen unterscheiden das Paket von dem des Schwesterprojekts, und beide werden
maschinell geprüft:

- **Der Companion-Kurzbefehl steht in der Beschreibung, nicht im Werbetext.** AK-20
  verlangt den Hinweis *vor* dem Download. Der Werbetext ist ohne Review änderbar und
  taugt deshalb nicht als Träger einer Pflichtangabe. Der Test prüft, dass „Shortcuts" in
  den ersten 700 Zeichen der Beschreibung vorkommt — dort, wo der Store noch nicht
  einklappt.
- **„Zehn Aktionen", nicht elf.** `ShortcutsWindowSnapper` beantwortet `.restore` mit
  `.nothingToRestore`, weil Kurzbefehle keine Fensterrahmen zurückmeldet. README und
  Website zählen elf — das gilt für den Direktvertrieb. Der Test schlägt fehl, sobald
  „eleven" in einem Store-Text auftaucht.

## Screenshots

Fünf Motive in dieser Reihenfolge — die ersten drei sind im Store ohne Scrollen sichtbar:

| # | Motiv | Aussage | Layout | Thema |
|---|---|---|---|---|
| 01 | Zwei Fenster als Hälften, Popover offen | der Hook | `highlight` | hell |
| 02 | Vier Fenster als Quadranten | das stärkste Bild | `hero` | dunkel |
| 03 | Ein Fenster füllt den Bildschirm | die dritte Aktion | `frame-top` | hell |
| 04 | Companion-Kurzbefehl im Onboarding | die Ehrlichkeit (AK-20) | `highlight` | dunkel |
| 05 | Zentriertes Fenster, Popover offen | der Alltag | `text-top` | hell |

**Was hier nicht steht, und warum.** Motiv 03 sollte ursprünglich die Kürzelübersicht aus
dem Einstellungsfenster zeigen. Sie ist von außen nicht zuverlässig erreichbar: Die
Seitenleiste reagiert nicht auf einen synthetischen Klick — sie ist ein SwiftUI-Element —,
und der Weg über die Tastatur holt die Bedienungshilfen-Tastatur ins Bild. Der
Onboarding-Schritt davor schaltet nicht weiter, solange der Kurzbefehl schon installiert
ist; 03 und 04 waren dadurch eine Weile byteweise dasselbe Bild. Wer die Kürzelübersicht
im Store haben will, nimmt sie von Hand auf.

**Warum jede Aufnahme den Bildschirm zeigt und nicht ein Fenster.** Mika+Grid hat kein
Hauptfenster: Das Popover misst 280 Punkte, die Einstellungen 580 × 420, das Onboarding
480 × 560. Keines davon zeigt, was die App tut — was sie tut, ist der Bildschirm. Bei
Mika+FileScope war die Rohaufnahme *ein* Anwendungsfenster; hier ist sie ein
Bildschirmausschnitt mit mehreren gesnappten Fenstern. Der gerundete Rahmen, den
`compose.swift` darum zeichnet, liest sich dadurch wie ein Display statt wie ein Fenster.
Das Popover wird über das `highlight`-Layout herausvergrößert, statt es einzeln
aufzunehmen und hochzuskalieren.

Vier Layouts statt einem: Fünf identisch aufgebaute Kacheln nebeneinander lesen sich in
der Store-Galerie wie ein Bild. `compose.swift` kennt deshalb

- `hero` — Aufnahme fast formatfüllend, Headline im abgedunkelten Fuß,
- `text-top` — Headline oben, Aufnahme darunter, unten angeschnitten,
- `frame-top` — Aufnahme läuft **oben** aus dem Bild, Text steht unten,
- `highlight` — wie `text-top`, davor ein vergrößerter Ausschnitt als schwebende Karte.
  Die Karte liegt in beiden Achsen genau über ihrer eigenen Herkunft und verdeckt sie;
  stünde sie woanders, sähe man denselben Inhalt zweimal.

Welches Motiv welches Layout bekommt — samt Ausschnitt — steht in `tools/shots.json`.

`frame-top` und `text-top` sind nicht beliebig austauschbar: `frame-top` schneidet **oben**
ab und eignet sich für Ansichten, deren Aussage im unteren Bildteil liegt.

Format: **2880 × 1800 px**, JPEG ohne Alphakanal — eine der von Apple für den Mac
akzeptierten Größen. `2560x1600` ist in `FORMATE` bereits hinterlegt; alle Layoutmaße
leiten sich aus der Leinwandgröße ab, ein weiteres Format kostet deshalb nur einen Eintrag
und einen Lauf mit `--format`.

JPEG und nicht PNG: Bei dieser Größe wiegt ein PNG rund 3 MB. App Store Connect nimmt
beides, solange kein Alphakanal drin ist.

---

## Neu erzeugen

```bash
AppStore/tools/capture.sh --build      # Store-Fassung bauen, Kulisse, Rohaufnahmen
swift AppStore/tools/compose.swift     # Layouts + Texte → fertige Screenshots
swift test --filter StoreAssetTests    # Limits, Bildmaße, Vollständigkeit
```

`capture.sh` ohne `--build` überspringt den Bau und nimmt nur neu auf.
`compose.swift en-US` beschränkt die Komposition auf eine Sprache,
`compose.swift --format 2560x1600` schreibt ein zweites Format.

### Wie das funktioniert

**Aufgenommen wird die Store-Fassung**, nicht das Direktziel. Die Fußzeile des Popovers
zeigt die Schaltfläche „Updates" nur, wenn es einen Update-Kanal gibt — in der
Store-Fassung gibt es keinen. Ein Bild der Direktfassung zeigte im Store also eine
Schaltfläche, die dort nicht existiert. `capture.sh` bricht ab, wenn das Store-Bundle
fehlt, statt still auf das Direktziel auszuweichen.

Die Kulisse besteht aus TextEdit-Fenstern mit eigens gesetztem Inhalt. Kein Terminal
(die Eingabeaufforderung trägt Benutzer- und Rechnernamen), kein Browser, kein Finder mit
Seitenleiste — dort stehen Gerätename und iCloud-Konto. Aus demselben Grund wird das
Schreibtischbild für die Dauer der Aufnahme durch einen einfarbigen Grund ersetzt und
danach zurückgestellt.

Zwei Fallen, die das Skript bewusst behandelt:

- **Das Popover schließt sich, sobald eine andere App aktiv wird.** Es läuft im Stil
  `.menuBarExtraStyle(.window)`. Jede Fensteraktivierung nach dem Öffnen zerstört die
  Aufnahme — die Reihenfolge „erst snappen, dann Popover, dann aufnehmen" ist deshalb
  nicht verhandelbar.
- **Der grüne Klickring.** Die Bedienungshilfen zeichnen nach einem Klick über System
  Events einen Ring an die Mausposition. Zwischen letztem Klick und Aufnahme liegt
  deshalb ein Neustart des Dienstes.

Die Store-Fassung braucht für eine Aufnahme mehr als einen Bau: den Companion-Kurzbefehl
in der Mediathek **und** die einmal erteilte Erlaubnis, Kurzbefehle zu steuern. Beides
lässt sich nicht skripten. `capture.sh` prüft es und bricht mit einer Anleitung ab, statt
fünf leere Bilder zu erzeugen.

### Texte ändern

Headlines und Sublines stehen in `tools/shots.json`, nach Sprache getrennt.
`compose.swift` verkleinert die Headline automatisch, bis der Textblock in die vorgesehene
Höhe passt — längere Übersetzungen brechen das Layout also nicht.

Farben stammen aus `Sources/MikaGridCore/MikaPlusColors.swift`, die Schrift ist SF Pro vom
System; Store-Assets und App haben dadurch dieselbe Handschrift. Wer die Markenfarbe
ändert, ändert sie dort und spiegelt sie in `compose.swift` und `web/app/globals.css`.
