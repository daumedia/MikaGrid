# B10 · Landingpage — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1

> **Rückerfassung.** ⚠ markiert Verhalten, das zur Klärung vorliegt.

## Zweck

Eine einzelne öffentliche Seite erklärt, was Mika+Grid ist, zeigt das Raster in Aktion
und führt zum Download. Sie ist zugleich die Referenzarbeit, mit der Daumedia auf
Auftragsarbeit aufmerksam macht — der Zweck, den das PRD unter Monetarisierung nennt.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B09 | rekonstruiert | Die Seite verlinkt das DMG aus dem GitHub-Release und nennt dessen Größe |

## User Stories

- **US-01** · Als Interessent möchte ich in dreißig Sekunden verstehen, was die App tut,
  damit ich entscheiden kann, ob sich der Download lohnt.
- **US-02** · Als Interessent möchte ich vor dem Download wissen, worauf ich mich
  einlasse — Berechtigungen, Signaturlage, Kosten.
- **US-03** · Als potenzieller Auftraggeber möchte ich sehen, wer dahintersteht.

## Nicht im Scope

- **Mehrere Seiten.** Es gibt genau eine Route.
- **Download-Zählung, Newsletter, Kontaktformular.** Nichts davon existiert — und ohne
  sie braucht die Seite keine Einwilligung.
- **Mehrsprachigkeit.** Ausschließlich Englisch, obwohl der Anbieter in Luxemburg sitzt.

## Akzeptanzkriterien

- **AK-01** · Angenommen, das Verzeichnis `web/` ist eingerichtet, wenn `npm run build`
  läuft, dann geht der Build ohne Fehler durch und erzeugt ausschließlich statisch
  vorgerenderte Routen.
  *(Nachweis 2026-08-25: bestanden — 6 Routen, alle als „Static" ausgewiesen.)*
- **AK-02** · Angenommen, die Seite wird geladen, wenn sie betrachtet wird, dann zeigt
  sie Kopfleiste, Aufmacher mit Rasterdarstellung, Funktionsliste, Kürzelübersicht,
  Ablauferklärung, Kennzahlen, häufige Fragen und Fußzeile.
- **AK-03** · Angenommen, die Seite ist geladen, wenn die Download-Schaltfläche betrachtet
  wird, dann nennt sie Version, Dateiformat, Größe in MB, Mindestsystem und Lizenz.
- **AK-04** · Angenommen, die Download-Schaltfläche wird angeklickt, dann führt sie zum
  DMG des passenden GitHub-Releases.
  *(Nachweis 2026-08-25: die hinterlegte Adresse liefert HTTP 200.)*
- **AK-05** · Angenommen, die Seite nennt eine Dateigröße, wenn sie mit dem Artefakt
  verglichen wird, dann stimmt sie.
  *(Nachweis: angegeben 2,5 MB, tatsächlich 2 543 170 Bytes = 2,54 MB.)*
- **AK-06** · Angenommen, die Seite nennt eine Version, wenn sie mit `Info.plist`
  verglichen wird, dann stimmt sie. *(Nachweis: beide 1.1.1.)*
- **AK-07** · Angenommen, die Kürzelübersicht wird betrachtet, wenn sie mit dem
  Aktions-Aufzählungstyp der App verglichen wird, dann stimmen Beschriftungen und
  Standardbelegungen aller elf Aktionen überein.
- **AK-08** · Angenommen, die Rasterdarstellung zeigt die zentrierte Zone, wenn ihre
  Maße geprüft werden, dann belegt sie zwei Drittel in Breite und Höhe.
  *(Bemerkenswert: Die **Website** stellt diese Zone korrekt dar; die **App** zeigt im
  Popover rund 80 % × 69 % — siehe B04.)*
- **AK-09** · Angenommen, die Seite wird geladen, wenn der Netzwerkverkehr betrachtet
  wird, dann geht **kein** Aufruf an einen Drittanbieter — auch nicht für Schriften.
  *(Die drei Schriften werden zur Bauzeit heruntergeladen und mitgeliefert; zur Laufzeit
  gibt es keine Verbindung zu Google.)*
- **AK-10** · Angenommen, die Seite wird besucht, wenn Speicher und Verlauf geprüft
  werden, dann setzt sie keine Cookies, schreibt nichts in den lokalen Speicher und
  überträgt keine Nutzungsdaten. *(Nachgewiesen: kein Analysewerkzeug in den
  Abhängigkeiten, keine Fundstelle für Cookies, lokalen Speicher oder Formulare.)*
- **AK-11** · Angenommen, die Seite behauptet „0 Trackers or analytics", wenn das geprüft
  wird, dann trifft die Aussage zu.
- **AK-12** ⚠ · Angenommen, ein Interessent ruft die im Quelltext hinterlegte Adresse
  `https://mikagrid.vercel.app` auf, dann erhält er **eine Fehlerseite**.
  *(So ist der Zustand am 2026-08-25: HTTP 404 mit `x-vercel-error: DEPLOYMENT_NOT_FOUND`.
  Die Adresse zeigt auf Vercel, aber es existiert kein Deployment. Siehe OF-01.)*
- **AK-13** ⚠ · Angenommen, ein Besucher klickt in der Fußzeile auf „MIT Licence", dann
  landet er auf einer **Fehlerseite von GitHub**.
  *(Der Link zeigt auf `…/blob/master/LICENSE`; die Datei existiert weder auf `master`
  noch auf `main` — beide liefern HTTP 404. Siehe OF-02.)*

### Datenschutz und Missbrauchsschutz

Geprüft gegen `~/.claude/sdd/sicherheit.md`.

- **AK-14** · Angenommen, die Seite ist erreichbar, wenn ein Besucher sie aufruft, dann
  verarbeitet der Betreiber mittelbar dessen IP-Adresse — über die Zugriffsprotokolle
  von Vercel. Eigene Verarbeitung findet nicht statt.
- **AK-15** ⚠ · Angenommen, ein Besucher sucht die Datenschutzerklärung oder das
  Impressum, dann findet er **keines von beidem** — weder verlinkt noch unter den
  üblichen Pfaden.
  *(Nachgewiesen: keine Fundstelle im Quelltext; `/privacy`, `/legal`, `/impressum` und
  `/imprint` sind keine Routen. Siehe FB-01 und OF-03.)*
- **Besondere Kategorien, Uploads, Rollen, Rate Limits:** treffen nicht zu — die Seite
  nimmt keine Eingaben entgegen.
- **Geheimnisse:** keine. Die Seite ist vollständig statisch; es gibt keine
  Umgebungsvariablen und keine serverseitige Logik.

## Edge Cases

- **EC-01** · Ein neues Release erscheint, ohne dass `web/lib/app.ts` angepasst wird →
  die Seite bewirbt weiterhin die alte Version und verlinkt ein älteres DMG. Nichts
  verhindert das; `CLAUDE.md` nennt die Pflicht zur Handpflege ausdrücklich.
- **EC-02** · Eine Snap-Aktion wird in der App umbenannt oder ergänzt → die Spiegeldatei
  `web/lib/snapActions.ts` weicht ab, bis jemand sie nachzieht.
- **EC-03** · Das GitHub-Release wird gelöscht → die Download-Schaltfläche führt ins Leere.
- **EC-04** · Besucher mit deaktiviertem JavaScript → die Seite ist statisch
  vorgerendert und bleibt vollständig lesbar; nur die animierte Vorführung steht still.

## Fehlbestand

- **FB-01 · Weder Impressum noch Datenschutzerklärung.** Die Seite besteht aus genau
  einer Route; es gibt keine rechtlichen Angaben. **Folge:** Der Anbieter sitzt in
  Luxemburg und betreibt die Seite ausdrücklich als Werbeträger für Auftragsarbeit — sie
  ist damit kein rein privates Angebot. Für einen gewerblich veranlassten Online-Auftritt
  in der EU sind Anbieterkennzeichnung und eine Information nach Art. 13 DSGVO
  vorgesehen, letztere schon wegen der Zugriffsprotokolle des Hosters. Das ist der
  einzige Befund der gesamten Erfassung, der eine **rechtliche Pflicht** berührt und
  nicht nur eine technische Schwäche. Er wiegt schwerer, sobald die Seite live geht.
- **FB-02 · Die Seite ist nicht erreichbar.** `mikagrid.vercel.app` antwortet mit
  `DEPLOYMENT_NOT_FOUND`. **Folge:** Sämtliche Verweise auf die eigene Adresse laufen ins
  Leere — die kanonische Adresse in den Metadaten, `sitemap.xml`, `robots.txt` und der
  Eintrag `url` in den strukturierten Daten. Ein Feature, das vollständig gebaut, aber
  nicht ausgeliefert ist, ist im Bestand schwer zu bemerken: Im Repository sieht alles
  fertig aus.
- **FB-03 · Der Lizenzlink der Fußzeile ist tot.** Er zeigt auf
  `…/blob/master/LICENSE`; die Datei existiert nicht (HTTP 404 auf beiden Zweigen).
  **Folge:** Die Seite verspricht an drei Stellen MIT — Aufmacher, häufige Fragen und
  maschinenlesbar in den strukturierten Daten (`license: opensource.org/licenses/MIT`) —
  und der einzige Beleg dafür führt auf eine Fehlerseite. Zusammen mit dem fehlenden
  `LICENSE` im Repository ist das keine Nachlässigkeit in der Darstellung, sondern eine
  unbelegte Zusage.
- **FB-04 · Der Zweig `master` steckt fest verdrahtet in der Fußzeile.** Dieselbe Stelle.
  **Folge:** Derselbe Zweig-Zwiespalt wie bei B08/FB-01, hier ein zweites Mal.
- **FB-05 · Kein Abgleich mit dem Bestand.** `web/lib/app.ts` und `web/lib/snapActions.ts`
  spiegeln `Info.plist`, `appcast.xml` und `SnapAction.swift` von Hand. **Folge:** EC-01
  und EC-02. Alle drei Werte sind maschinell vergleichbar — geprüft wird nichts.
- **FB-06 · Keine Angabe zur Signaturlage im Aufmacher.** Die häufigen Fragen erklären
  offen, dass die Builds ad-hoc signiert und nicht notarisiert sind — aber erst weit
  unten. Wer nur den Aufmacher liest und lädt, trifft die Gatekeeper-Warnung unvorbereitet.
- **FB-07 · Kein Test, kein Prüflauf.** Kein `npm test`, keine Fließbandsteuerung. Der
  Build besteht (AK-01), aber niemand führt ihn automatisch vor einer Veröffentlichung aus.

## Offene Fragen

- **OF-01** · Soll die Seite überhaupt live gehen (FB-02)? Solange sie es nicht ist, sind
  FB-01 und FB-03 folgenlos — sobald sie es ist, sind sie es nicht mehr. Diese Frage
  entscheidet die Dringlichkeit der übrigen. — *Betreiber, zuerst.*
- **OF-02** · `LICENSE` ergänzen oder die Lizenzaussagen entfernen (FB-03)? Die Datei
  hinzuzufügen ist die Arbeit von zwei Minuten und deckt zugleich README, Aufmacher,
  häufige Fragen und strukturierte Daten. — *Betreiber, empfohlen.*
- **OF-03** · Impressum und Datenschutzerklärung ergänzen (FB-01)? Bei „Visitenkarte für
  Auftragsarbeit" als erklärtem Zweck spricht wenig dagegen und einiges dafür. —
  *Betreiber, vor dem Livegang.*

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Technischer Unterbau | Next.js 15 mit App Router, Tailwind 4 | Statische Ausgabe ohne Server; die Wahl passt zum Umfang einer einzelnen Seite |
| 2 | Hosting | Vercel, Wurzelverzeichnis `web` | Ohne weitere Einrichtung lauffähig |
| 3 | Schriften | über `next/font` eingebunden | Werden zur Bauzeit heruntergeladen und mitgeliefert — kein Aufruf an Google beim Besucher. Bewusst datenschutzfreundlich |
| 4 | Analyse | keine | Deckungsgleich mit der Zusage „0 Trackers" auf der Seite selbst |
| 5 | Sprache | nur Englisch | Zielgruppe des Produkts; der Anbieter sitzt allerdings in Luxemburg |
| 6 | Produktdaten an einer Stelle | `lib/app.ts` als einzige Quelle | Richtig gedacht — nur wird die Quelle selbst von Hand gepflegt (FB-05) |
| 7 | Farben aus dem Bestand gespiegelt | `@theme` in `globals.css` | Deckungsgleich mit der Palette der App, geprüft |
| 8 | Nur dunkle Darstellung | `color-scheme: dark` | Entspricht dem Erscheinungsbild der Marke |
