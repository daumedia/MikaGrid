# Mika+Grid — App-Shell

Stand: 2026-08-25 · Artefaktpfad: `docs/`

> **Rekonstruktion aus dem Bestand (Version 1.1.1).**

## Was hier die Shell ist

Mika+Grid hat **kein Hauptfenster, keine Navigation und keine Menüleiste**. `LSUIElement`
steht auf `true`: kein Dock-Symbol, kein App-Menü, kein ⌘, für Einstellungen, kein ⌘Q.
Was andere Apps als Rahmen haben, ist hier ein einziger `Scene`-Eintrag:

```swift
MenuBarExtra {
    PopoverGridView(appState: appDelegate.appState)
} label: {
    Image(systemName: "square.grid.3x3")
}
.menuBarExtraStyle(.window)
```

Alles Weitere sind **freistehende `NSWindow`-Instanzen**, die ein `AppDelegate` auf Zuruf
öffnet. Es gibt keinen Navigationsstapel, keine Tab-Leiste und keinen gemeinsamen
Seitenrahmen — die „Shell" besteht aus vier Einstiegspunkten und drei Fenstern.

## Einstiegspunkte

| Weg | Führt wohin | Erreichbar wann |
|---|---|---|
| **Globale Tastenkürzel** (⌃⌥ + Taste) | direkt zur Aktion, **ohne jede Oberfläche** | immer, sobald die Accessibility-Berechtigung erteilt ist |
| **Menüleistensymbol** (`square.grid.3x3`) | Popover mit Raster und Fußzeile | immer |
| **Erststart** | Onboarding-Fenster | wenn `hasCompletedOnboarding == false` |
| **Fußzeile des Popovers** | Einstellungsfenster · Update-Prüfung · Beenden | immer |

Der Hauptweg ist der erste: Die App ist so gebaut, dass man sie im Normalbetrieb nie
sieht. Das Popover ist die Lernhilfe, nicht die Bedienoberfläche — es zeigt zu jeder
Zone das zugehörige Kürzel an.

## Das Popover — die einzige „Seite"

`PopoverGridView`, feste Breite 280 pt, Höhe aus dem Inhalt. Aufbau von oben nach unten:

1. **Kopfzeile** — Symbol in `tealPrimary`, Wortmarke „Mika+Grid", rechts ein 8-pt-Punkt
   als Berechtigungsampel (grün erteilt / orange fehlt)
2. **Warnbanner**, *nur* wenn die Berechtigung fehlt — anklickbar, öffnet direkt die
   Systemeinstellungen
3. `Divider`
4. **Snap-Raster** — fünf Zeilen: zwei Hälften, zwei Hälften, vier Viertel in zwei
   Zeilen, dann Maximieren / Zentrieren / Zurücksetzen
5. `Divider`
6. **Fußzeile** — „Preferences" · „Updates" · „Quit", alle als schlichter 11-pt-Text

Bei `.onAppear` wird der Berechtigungsstatus neu geprüft, damit die Ampel stimmt, wenn
der Nutzer die Zustimmung außerhalb der App erteilt hat.

## Die drei Fenster

Alle drei folgen demselben Muster (siehe `design-system.md`, Abschnitt 5): ein
`NSObject`-Controller mit `NSWindowDelegate`, `NSHostingView` als Inhalt, `center()`,
`NSApp.activate()`, Freigabe in `windowWillClose`.

| Fenster | Maß | Struktur | Geöffnet von |
|---|---|---|---|
| **Einstellungen** | 580 × 420, `.titled, .closable` | `NavigationSplitView` mit Seitenleiste (140–180 pt) und scrollendem Detailbereich; drei Einträge: General · Shortcuts · About | Fußzeile des Popovers |
| **Onboarding** | 480 × 560, `.titled, .closable, .fullSizeContentView`, transparente Titelleiste, per Hintergrund verschiebbar | `TabView` mit Punktanzeige; **zwei oder drei** Schritte, je nach Berechtigungslage | Erststart · Einstellungen → About → „Show Onboarding Again" |
| **Über** | 320 × 400, `.titled, .closable` | einspaltiger Stapel auf dunklem Verlauf | **niemand** — siehe *Fehlbestand* |

### Verzweigung im Onboarding

`OnboardingView` entscheidet beim Aufbau, wie viele Schritte es gibt:

```swift
private var needsPermission: Bool { !appState.accessibilityManager.isGranted }
private var pageCount: Int { needsPermission ? 3 : 2 }
```

- **Berechtigung fehlt:** Willkommen → Berechtigung → Kürzel (3 Punkte)
- **Berechtigung liegt vor:** Willkommen → Kürzel (2 Punkte)

Der Berechtigungsschritt schaltet selbsttätig weiter: Ein Timer prüft im Sekundentakt,
und sobald die Zustimmung erteilt ist, wechselt die Ansicht nach einer Sekunde zum
nächsten Schritt.

Das Fenster lässt sich auf drei Wegen schließen — „Done", die Fenstertaste und ESC. **In
allen drei Fällen** setzt `windowWillClose` den Wert `hasCompletedOnboarding = true`; das
Onboarding erscheint danach nicht erneut.

## Verdrahtung zwischen Popover und Fenstern

Das Popover ist eine SwiftUI-`Scene` und hat keinen Zugriff auf den `AppDelegate`.
Überbrückt wird das mit `NotificationCenter`:

```
PopoverGridView  ──post(.showPreferences)──▶  AppDelegate  ──▶  PreferencesWindowController
PopoverGridView  ──post(.showAbout)───────▶  AppDelegate  ──▶  AboutWindowController
```

Der zweite Pfeil ist im ausgelieferten Produkt **tot** (siehe unten). Die dritte
Verbindung — Einstellungen → Onboarding — läuft nicht über Notifications, sondern über
einen Closure, den der `AppDelegate` beim Erzeugen des Einstellungs-Controllers
durchreicht.

Zustand hält `AppState` (`@Observable`, `@MainActor`) und gibt ihn per Konstruktor an
jede Ansicht weiter. Es gibt keinen `@EnvironmentObject`, keine Singletons außer der
`nonisolated(unsafe) static var instance` des `HotkeyManager`, die ausschließlich die
Carbon-Rückrufbrücke bedient.

## Lebenszyklus

| Moment | Was passiert |
|---|---|
| `applicationDidFinishLaunching` | `AppState.setup()` erzeugt `WindowManager` und `HotkeyManager`; die elf Kürzel werden sofort registriert |
| danach | Onboarding, **oder** — falls schon abgeschlossen und nicht übersprungen — stille Prüfung der Berechtigung samt Systemabfrage, falls sie fehlt |
| laufend | `NSWorkspace.didActivateApplicationNotification` merkt sich die zuletzt aktive fremde App als Snap-Ziel |
| Beenden | ausschließlich über „Quit" im Popover (`NSApp.terminate`) |

## Fehlbestand

Lücken, keine Kriterien.

- **Das Über-Fenster ist nicht erreichbar.** `AboutWindowController` und `AboutView`
  (85 Zeilen) existieren, der `AppDelegate` hört auf `.showAbout` — aber **keine Stelle
  im Quelltext postet diese Notification**. In 1.0.0 lag der Auslöser in der Fußzeile des
  Popovers; das CHANGELOG zu 1.1.0 vermerkt „Popover footer: 'About' replaced with
  'Updates' button". Dabei ist der einzige Weg zum Fenster verschwunden, der Code blieb
  stehen. Ersatz gibt es nur teilweise: Der Einstellungsbereich „About" zeigt dieselbe
  Version, aber nicht das gestaltete Fenster.
- **Kein Tastaturweg in die App.** Ohne App-Menü gibt es kein ⌘, für die Einstellungen
  und kein ⌘Q. Es ist zudem kein Kürzel vorgesehen, das das Popover öffnet — wer die
  Einstellungen erreichen will, muss zwingend zur Maus greifen. Für eine ansonsten
  vollständig tastaturbediente App ist das der auffälligste Bruch.
- **`permissionSkipped` wird nie zurückgenommen.** Wer im Onboarding „Skip for now"
  wählt, unterdrückt die Berechtigungsabfrage beim Start dauerhaft — auch dann noch, wenn
  die Zustimmung später erteilt und wieder entzogen wird. Zurücksetzen lässt sich das nur
  über „Reset All Settings".
- **Das Onboarding gilt auch bei Abbruch als abgeschlossen.** ESC oder die Fenstertaste
  im ersten Schritt führen zum selben Ergebnis wie „Done": Die Einrichtung erscheint nie
  wieder von selbst, obwohl der Nutzer weder die Berechtigung erteilt noch die Kürzel
  gesehen hat. Der Wiederaufruf ist zwei Ebenen tief vergraben (Einstellungen → About →
  „Show Onboarding Again").
- **Kein URL-Schema, keine `.commands`, keine Deep Links.** Weder Automatisierung noch
  ein Sprung von der Landingpage in eine bestimmte Ansicht sind möglich. Für den heutigen
  Umfang vertretbar, aber es ist eine Entscheidung, die nirgends festgehalten war.
- **Der Berechtigungsschritt kann mehrfach weiterschalten.** `onReceive(timer)` legt bei
  *jedem* Tick eine neue Verzögerungs-`Task` an, ohne die vorherige abzubrechen. Bleibt
  die Ansicht nach erteilter Zustimmung eine Sekunde länger stehen, laufen mehrere Tasks
  parallel und rufen `onNext()` mehrfach auf. Sichtbare Folge ist heute gering, weil das
  Ziel ohnehin der letzte Schritt ist — die Ursache bleibt trotzdem ein Fehler.
