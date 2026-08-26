# Altersfreigaben — Antworten für App Store Connect

Der Fragebogen unter *App Store Connect → App-Informationen → Altersfreigaben* fragt
24 Kategorien ab. Hier stehen die Antworten mit dem Beleg aus dem Code, damit sie bei
einer Neueinreichung oder nach einem Feature-Umbau nachvollziehbar bleiben. Ändert sich
eine der belegten Stellen, gehört die Antwort geprüft.

Stand: 2026-08-26, App-Version 1.2.0. Grundlage:
[Age ratings values and definitions](https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions).

**Ergebnis: 4+** — die niedrigste Stufe, und zwar ohne Ausnahme in irgendeiner
Kategorie.

Apple hat das System 2025 umgestellt: Die Stufen heißen jetzt 4+, 9+, 13+, 16+ und 18+
(vorher 4+, 9+, 12+, 17+), und mehrere Kategorien sind dazugekommen. Wer eine ältere
Anleitung im Kopf hat, findet die Fragen nicht wieder.

Mika+Grid hat es hier leichter als die meisten Apps: **Die Oberfläche zeigt Rechtecke.**
Kein Text aus fremder Quelle, keine Bilder, keine Namen — die einzige Anzeige ist ein
Raster aus Zonen und eine Liste von Tastenkürzeln.

---

## Schritt 1: Funktionen

| Frage (deutsch / englisch) | Antwort | Beleg |
|---|---|---|
| Kindersicherung · *Parental Controls* | Nein | Die App kennt drei technische Einstellungen: Onboarding gelaufen, Berechtigung übersprungen, Tastenkürzel (`Sources/MikaGridCore/AppPreferences.swift`). Keine Sperren, keine Profile. |
| Altersnachweis · *Age Assurance* | Nein | Keine Konten, keine Registrierung, keine Altersabfrage. Die App fragt nichts ab. |
| Uneingeschränkter Internetzugriff · *Unrestricted Web Access* | Nein | Kein Browser, keine Adresszeile. `grep -rn "URLSession\|WKWebView" Sources/MikaGridCore Sources/MikaGridMAS` liefert **nichts**. Die einzigen Sprünge nach außen sind `x-apple.systempreferences:`-Adressen in die Systemeinstellungen (`ShortcutsWindowSnapper.swift:150-158`) und das Öffnen des mitgelieferten Kurzbefehls (`CompanionShortcutManager.swift:111`) — beides führt in System-Apps, nicht ins Netz. |
| Benutzergenerierte Inhalte · *User-Generated Content* | Nein | Siehe die Abgrenzung unten. |
| Soziale Medien · *Social Media* | Nein | Keine Feeds, keine Profile, keine Interaktion mit anderen Nutzern. |
| Soziale Medien für unter 13-Jährige deaktiviert · *Social Media Disabled for Users Under 13* | Nein | Gegenstandslos, da „Soziale Medien" bereits Nein ist. |
| Nachrichten und Chat · *Messaging and Chat* | Nein | Keine Kommunikationsfunktion. |
| Werbung · *Advertising* | Nein | Die Store-Fassung wird ohne jede Fremdabhängigkeit gebaut: Sparkle hängt am Direktziel (`Package.swift`, Ziel `MikaGrid`) und ist im Store-Ziel nicht eingebunden. `scripts/release.sh --store` bricht ab, wenn doch ein `Sparkle.framework` im Archiv liegt. Kein Werbe-SDK, keine Analytics. |

### Warum „Benutzergenerierte Inhalte = Nein"

Bei einer App, die fremde Fenster bewegt, liegt die Frage nahe, ob dabei Inhalte anderer
Anwendungen sichtbar werden. Sie werden es nicht:

- Die App **liest keine Fensterinhalte**. Sie kennt von einem Fenster ausschließlich
  seinen Rahmen — vier Zahlen.
- Sie zeigt **keine Fenstertitel und keine Anwendungsnamen** an. Das Popover zeigt
  Zonen, das Einstellungsfenster Tastenkürzel.
- Was an Apples Kurzbefehle geht, ist ein Rechteck: fünf Zahlen und ein Zufallswert zur
  Zuordnung der Antwort (`SnapPayload.swift`, spec.md OF-13). Kein Titel, kein Name.

Damit entfallen auch die Folgepflichten aus Guideline 1.2 (Meldefunktion, Blockieren,
veröffentlichte Kontaktadresse).

Auf einem Screenshot der App **sind** natürlich fremde Fenster zu sehen — das ist der
Zweck. Die Aufnahmen unter `screenshots/` zeigen deshalb nur TextEdit mit eigens
gesetztem Inhalt, nie einen privaten Bildschirm.

## Schritt 2: Erwachsenenthemen

| Frage | Antwort | Beleg |
|---|---|---|
| Obszöner oder vulgärer Humor · *Profanity or Crude Humor* | Nie | Die App zeigt ein Raster und eine Kürzelliste. Alle Texte stehen in `Sources/`. |
| Horror-/Gruselszenen · *Horror/Fear Themes* | Nie | Keine Illustrationen außer dem App-Symbol und SF Symbols. |
| Alkohol, Tabak oder Drogen bzw. Verweise · *Alcohol, Tobacco, or Drug Use or References* | Nie | Kommt inhaltlich nicht vor. |

## Schritt 3: Gesundheit

| Frage | Antwort | Beleg |
|---|---|---|
| Medizinische oder Behandlungsinformationen · *Medical or Treatment Information* | Nie | Die App gibt keinerlei Ratschläge. |
| Gesundheits- oder Wellness-Themen · *Health or Wellness Topics* | Nein | Dito. |

## Schritt 4: Sexuelle Inhalte

| Frage | Antwort |
|---|---|
| Anzügliche Themen · *Mature or Suggestive Themes* | Nie |
| Sexuelle Inhalte oder Nacktheit · *Sexual Content or Nudity* | Nie |
| Explizite sexuelle Inhalte und Nacktheit · *Graphic Sexual Content and Nudity* | Nie |

Die App erzeugt keine eigenen Bildinhalte und zeigt keine fremden an.

## Schritt 5: Gewalt

| Frage | Antwort |
|---|---|
| Comic- oder Fantasy-Gewalt · *Cartoon or Fantasy Violence* | Nie |
| Realistische Gewalt · *Realistic Violence* | Nie |
| Anhaltende explizite oder sadistische realistische Gewalt · *Prolonged Graphic or Sadistic Realistic Violence* | Nie |
| Schusswaffen oder andere Waffen · *Guns or Other Weapons* | Nie |

## Schritt 6: Glücksspiel und Wettbewerbe

| Frage | Antwort |
|---|---|
| Glücksspiel · *Gambling* | Nein |
| Simuliertes Glücksspiel · *Simulated Gambling* | Nie |
| Wettbewerbe · *Contests* | Nie |
| Beutekisten · *Loot Boxes* | Nein |

Keine Käufe, keine Währung, keine Zufallsmechanik. Die App ist kostenlos und kennt
keine In-App-Käufe.

---

## Wenn sich etwas ändert

Diese fünf Antworten sind die einzigen, die ein neues Feature kippen könnte:

| Antwort | Was sie kippen würde |
|---|---|
| Uneingeschränkter Internetzugriff | Eine eingebettete Web-Ansicht oder ein Link, der frei navigierbare Seiten öffnet. Ein `WKWebView` in `Sources/MikaGridCore` oder `Sources/MikaGridMAS` ist das Alarmsignal. |
| Benutzergenerierte Inhalte | Jede Funktion, die Fenstertitel, Anwendungsnamen oder Fensterinhalte anzeigt, speichert oder weitergibt. `SnapPayload` ist die Stelle, an der das zuerst auffiele. |
| Werbung | Jede Fremdabhängigkeit, die in der Store-Fassung mitgebaut wird — das Store-Ziel in `project.yml` prüfen. |
| Nachrichten und Chat | Jede Form der Kommunikation zwischen Nutzern. |
| *(alle)* | Jede Änderung an `Resources/MikaGridMAS.entitlements`. Wer dort etwas hinzufügt, erweitert das, was die App darf — und damit die Grundlage aller Antworten oben. |

Die ersten drei lassen sich mechanisch prüfen:

```bash
grep -rn "URLSession\|WKWebView" Sources/MikaGridCore Sources/MikaGridMAS   # muss leer bleiben
grep -rn "kAXTitleAttribute\|windowTitle" Sources/MikaGridMAS               # muss leer bleiben
plutil -p Resources/MikaGridMAS.entitlements                                # genau drei Einträge
```

`Sources/MikaGrid/` ist bewusst **nicht** dabei: Das ist die Direktfassung mit Sparkle,
ein anderes Binary, das nie im Store landet.

`swift test --filter StoreAssetTests` prüft die erste Zusage bei jedem Lauf mit.
