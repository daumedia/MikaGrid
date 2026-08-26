# App Store Connect — Feld für Feld

Version 1.2.0 · Bundle-ID `lu.daumedia.mikagrid` · Stand 2026-08-26

Die Texte stehen in `metadata/en-US/` und sind zum Kopieren gedacht. Hier steht alles,
was **nicht** in einer Textdatei liegt: Grunddaten, Kategorien und die Antworten der
Fragebögen.

## Grunddaten

| Feld | Wert |
|---|---|
| Name | Mika+Grid |
| Bundle-ID | `lu.daumedia.mikagrid` |
| SKU | `mikagrid-mac` |
| Primäre Kategorie | Produktivität / Productivity |
| Sekundäre Kategorie | *(leer lassen)* |
| Preis | Kostenlos |
| Altersfreigabe | 4+ (siehe [ALTERSFREIGABEN.md](ALTERSFREIGABEN.md)) |
| Copyright | © 2026 Michael Ferreira · daumedia.lu · MIT-Lizenz |
| Plattform | macOS 15 Sequoia oder neuer |

**Die Kategorie muss zu `LSApplicationCategoryType` in `Resources/Info-MAS.plist`
passen** — dort steht `public.app-category.productivity`. Weichen beide voneinander ab,
weist der Upload mit Fehler 90242 ab. `scripts/release.sh --store` prüft, dass der
Schlüssel überhaupt gesetzt ist; ob der Wert zur Auswahl in App Store Connect passt, kann
nur ein Mensch beurteilen.

Ein Fensterverwalter wäre auch unter *Dienstprogramme* denkbar. Die Wahl fiel auf
*Produktivität*, weil die App keine Systemwartung betreibt, sondern Arbeitsabläufe
beschleunigt. Änderbar ist das jederzeit — nur eben an beiden Stellen zugleich.

## Zwei Fassungen, eine Kennung

Mika+Grid erscheint in zwei Fassungen, die sich an genau einer Stelle unterscheiden: wie
ein Fenster bewegt wird. Beide tragen **dieselbe** Bundle-Kennung (Betreiberentscheidung
OF-04, `features/01-app-store-vertrieb/spec.md`). In App Store Connect gibt es deshalb nur
diesen einen Datensatz; eine Kennung `lu.daumedia.mikagrid.mas`, wie sie in älteren
Artefakten steht, existiert nicht und ist nicht anzulegen.

Für den Store zählt allein: Das hochgeladene Archiv enthält **kein** Sparkle und keinen
Update-Feed. `scripts/release.sh --store` bricht ab, wenn es im Archiv doch ein
`Sparkle.framework` findet.

## App Privacy — das „Nutrition Label"

Die Antwort ist durchgehend dieselbe, und das ist ein Verkaufsargument:

> **Data Not Collected** — für jede einzelne Kategorie.

Begründung, falls die Prüfung nachfragt: Die App führt keine Konten, sendet nichts und
speichert nur ein paar technische Einstellungen (Tastenkürzel, Start bei der Anmeldung,
ob das Onboarding gelaufen ist) in den lokalen `UserDefaults`. Nichts davon ist
personenbezogen, nichts verlässt das Gerät.

Die Store-Fassung macht **überhaupt keinen** Netzverkehr — sie enthält nicht einmal einen
Update-Kanal, der einen aufbauen könnte. Belegbar über den öffentlichen Quelltext:

```bash
grep -rn "URLSession\|WKWebView" Sources/MikaGridCore Sources/MikaGridMAS   # leer
```

`swift test --filter StoreAssetTests` prüft genau das bei jedem Lauf mit.

**Was an Apples Kurzbefehle geht, ist ein Rechteck.** Fünf Zahlen und ein Zufallswert zur
Zuordnung der Antwort — kein Fenstertitel, kein Anwendungsname (spec.md, OF-13). Auch die
Store-Fassung verarbeitet damit nichts Personenbeziehbares.

## Altersfreigaben

Der Fragebogen hat 24 Kategorien; jede einzelne wird mit „Nein" bzw. „Nie" beantwortet.
Das Ergebnis ist **4+**. Die Antworten stehen samt Beleg in
[ALTERSFREIGABEN.md](ALTERSFREIGABEN.md).

## Prüfungshinweise für Apple (App Review Information)

Diese sind hier wichtiger als bei einer gewöhnlichen App: Ein Prüfer sieht eine sandboxed
App, die Apple Events verschickt, und muss verstehen, warum — und wie er sie überhaupt zum
Laufen bringt.

```
The app requires no sign-in of any kind.

Mika+Grid is sandboxed and does not use the Accessibility API. It moves windows by asking
Apple's Shortcuts app, addressed through "Shortcuts Events", which runs shortcuts without
opening a window. The entitlement is the published access group com.apple.shortcuts.run,
not a temporary exception.

To review: on first launch the onboarding offers to add the companion shortcut
"Mika+Grid Snap" — one click. macOS then asks once for permission to control Shortcuts.
That consent cannot be granted in advance, and until it is given the first snap returns an
empty reply. After that, press Control-Option-Left with any window in front, or click a
zone in the menu bar popover.

The app has no Dock icon and no window of its own; it lives in the menu bar.

What the app sends to the shortcut is a rectangle: five numbers and a random value. It
never passes a window title or an application name. The app makes no network connections.
```

Der Absatz über die einmalige Zustimmung ist keine Höflichkeit. Der erste Zugriff auf eine
neue Fähigkeit liefert eine leere Antwort ohne Fehlermeldung — dahinter steckt genau diese
Rückfrage, die macOS bei einem unsichtbaren Aufruf nicht stellen kann. Ein Prüfer, der das
nicht weiß, hält die App für kaputt.

## Berechtigungen

Die Store-Fassung läuft in der Sandbox (`Resources/MikaGridMAS.entitlements`):

| Entitlement | Wofür |
|---|---|
| `com.apple.security.app-sandbox` | Pflicht im Store |
| `com.apple.security.automation.apple-events` | überhaupt Apple Events senden dürfen |
| `com.apple.security.scripting-targets` → `com.apple.shortcuts.events` : `com.apple.shortcuts.run` | Kurzbefehle **ausführen**, nicht verwalten |

Kein `com.apple.security.network.client` — die App stellt keine Verbindungen her.

**Warum `scripting-targets` und nicht `temporary-exception.apple-events`:** Das
Skripting-Wörterbuch von „Shortcuts Events" veröffentlicht die Zugriffsgruppen
`com.apple.shortcuts.run` (lesend) und `com.apple.shortcuts.organize` (schreibend). Die
App braucht nur die erste. Apple bezeichnet die temporäre Ausnahme selbst als
vorübergehend und rät ab, sobald die Ziel-App Zugriffsgruppen anbietet (QA1888). Sie zu
vermeiden senkt das größte Risiko dieses Features — die Ablehnung durch die Prüfung.

Ziel ist `com.apple.shortcuts.events`, **nicht** `com.apple.shortcuts`: Nur der UI-lose
Ereignisdienst führt Kurzbefehle aus, ohne ein Fenster zu öffnen.

## Was die Store-Fassung nicht kann

Gehört in die Beschreibung, nicht ins Kleingedruckte — und steht dort auch:

| Einschränkung | Grund |
|---|---|
| Kein „Restore previous position" | Kurzbefehle meldet keine Fensterrahmen zurück; es gibt nichts zu merken. **Zehn** der elf Aktionen bleiben |
| Bildschirme oberhalb oder links des Hauptbildschirms | `Move Window` nimmt keine negativen Koordinaten an |
| Keine Rückmessung des Ergebnisses | Klemmt die Zielanwendung den Rahmen (TextEdit rundet auf Zeilenhöhen), merkt die Store-Fassung es nicht |

Die Store-Texte sagen „ten snap actions" und nennen die fehlende Wiederherstellung
ausdrücklich. `swift test --filter StoreAssetTests` schlägt fehl, wenn dort je „eleven"
auftaucht.

## Screenshots

Fünf Bilder aus `screenshots/en-US/mac-2880x1800/`, in der Nummernreihenfolge hochladen.
Die ersten drei sind ohne Scrollen sichtbar; die Reihenfolge ist bewusst gewählt und
sollte so bleiben. Aufbau und Begründung stehen in [README.md](README.md).
