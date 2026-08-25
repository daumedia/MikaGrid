# Mika+Grid — Datenschutz

Stand: 2026-08-25 · Stufe A · Artefaktpfad: `docs/`

## Kurzfassung

Mika+Grid verarbeitet **keine personenbezogenen Daten**. Es gibt kein Konto, keinen
Server, keine Datenbank und keine Telemetrie. Die App speichert eine Handvoll technischer
Einstellungen auf dem Gerät des Nutzers und spricht genau einmal am Tag mit GitHub, um
nach einer neuen Version zu sehen.

Diese Stufe ist aus dem Datenmodell abgeleitet, nicht behauptet — die Belege stehen in
`docs/datenmodell.md`.

## Was die App speichert

Alles liegt lokal in `~/Library/Preferences/lu.daumedia.mikagrid.plist`.

| Was | Inhalt | Personenbezug |
|---|---|---|
| `hasCompletedOnboarding` | Wahrheitswert | nein |
| `permissionSkipped` | Wahrheitswert | nein |
| `hotkeyBindings` | Tastencodes und Umschaltmasken | nein |
| `hotkeyBindingsSchemaVersion` | Zahl | nein |
| Sparkle-Schlüssel | Prüfintervall, Zeitpunkt der letzten Prüfung | nein |

Es gibt keine weiteren Dateien: kein Verzeichnis in „Application Support", kein
Schlüsselbund-Eintrag, keine Protokolldatei.

## Was die App liest, aber nicht speichert

Über die Bedienungshilfen-Berechtigung liest Mika+Grid **Position, Größe und Nummer**
des jeweils aktiven Fensters und setzt Position und Größe. Mehr nicht — keine
Fensterinhalte, keine Texteingaben, keine Tastatureingaben anderer Programme.

**Der Fenstertitel wird seit Version 1.2.0 nicht mehr gelesen.** Bis dahin bildete er
zusammen mit der Prozesskennung den Schlüssel der Positionshistorie; er lag damit im
Arbeitsspeicher, weil ein Fenstertitel einen Dokumentnamen oder eine besuchte Website
enthalten kann. Der Schlüssel ist inzwischen die Fensternummer des Systems — eine reine
Zahl ohne jeden Aussagewert.

Die Positionshistorie selbst lebt ausschließlich im Arbeitsspeicher, ist auf 100 Einträge
begrenzt und beim Beenden der App verschwunden.

## Berechtigungen

| Berechtigung | Wofür | Wenn verweigert | Nachträglich erteilen |
|---|---|---|---|
| **Bedienungshilfen** (Accessibility) | Fenster anderer Programme bewegen und in der Größe ändern — die einzige Schnittstelle von macOS, die das erlaubt | Die App startet und ist bedienbar, kann aber keine Fenster anordnen. Sie weist beim Versuch darauf hin | Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen |

Mika+Grid verlangt **keine** Eingabeüberwachung. Die systemweiten Tastenkürzel laufen
über die Carbon-Schnittstelle `RegisterEventHotKey`, die dem Programm ausschließlich die
elf angemeldeten Kombinationen meldet. Ein Mitschnitt der Tastatur ist damit technisch
ausgeschlossen — nicht nur unterlassen.

Die App läuft **ohne** App-Sandbox, weil die Bedienungshilfen-Schnittstelle darin nicht
funktioniert. Das ist der Grund, warum sie nicht über den App Store vertrieben wird.

## Übermittlung an Dritte

| Empfänger | Anlass | Übertragene Daten | Rechtsgrundlage |
|---|---|---|---|
| GitHub, Inc. (USA) | Suche nach Updates, standardmäßig einmal täglich | IP-Adresse, Zeitpunkt, Programmkennung von Sparkle — also das, was jeder Abruf einer öffentlichen Datei erzeugt | Art. 6 Abs. 1 lit. f DSGVO: berechtigtes Interesse an der Auslieferung von Sicherheits- und Fehlerbehebungen |

**Sparkles Systemprofilierung ist abgeschaltet** (`SUSendProfileInfo = 0`). Es werden
weder Hardware- noch Systemangaben übermittelt.

Die automatische Suche lässt sich in den Einstellungen unter „Allgemein" abschalten.
Danach findet **kein** Netzverkehr mehr statt, bis der Nutzer selbst auf „Check Now"
drückt.

Weitere Empfänger gibt es nicht. Es sind keine Analysewerkzeuge, keine Absturzberichte
und keine Werbekennungen eingebunden.

## Website

Die Projektseite wird bei Vercel Inc. gehostet und ist statisch. Sie setzt keine Cookies,
schreibt nichts in den lokalen Speicher des Browsers und enthält kein Analysewerkzeug.
Die verwendeten Schriften werden beim Erstellen der Seite mitgeliefert, es besteht also
**keine** Verbindung zu Google Fonts beim Aufruf.

Beim Abruf verarbeitet Vercel serverseitige Zugriffsprotokolle mit IP-Adresse, Zeitpunkt
und Programmkennung des Browsers. Rechtsgrundlage ist Art. 6 Abs. 1 lit. f DSGVO
(technisch fehlerfreie Bereitstellung). Einzelheiten stehen in der Datenschutzerklärung
der Seite selbst.

## Rechte der Nutzer

Auskunft, Berichtigung, Löschung, Einschränkung, Widerspruch und Datenübertragbarkeit
laufen ins Leere, weil keine personenbezogenen Daten verarbeitet werden — es gibt nichts,
worüber Auskunft zu erteilen wäre.

**Vollständiges Entfernen aller Spuren der App:**

```bash
rm -rf /Applications/Mika+Grid.app
defaults delete lu.daumedia.mikagrid
```

Dazu der Eintrag unter Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen
und, falls eingerichtet, unter Allgemein → Anmeldeobjekte. Beides muss von Hand entfernt
werden; kein Programm darf fremde Einträge dort löschen.

## Verantwortlich

Daumedia · Luxemburg · <https://daumedia.lu>

## Änderungen an diesem Dokument

Wird eine Funktion ergänzt, die Daten speichert oder überträgt, ist die Stufe im PRD neu
zu bewerten, **bevor** gebaut wird. Der naheliegendste Fall steht in
`features/B02-position-wiederherstellen/spec.md` unter FB-05: Eine Positionshistorie, die
einen Neustart überdauert, würde aus flüchtigem Speicher eine dauerhafte Datei machen.
