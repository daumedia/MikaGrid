#!/bin/bash
# capture.sh — nimmt die fünf Rohaufnahmen für die App-Store-Bilder auf.
#
#     AppStore/tools/capture.sh            # nur aufnehmen
#     AppStore/tools/capture.sh --build    # vorher die Store-Fassung bauen
#
# Ergebnis: AppStore/screenshots/raw/en/01_halves.png … 05_center.png.
# Danach `swift AppStore/tools/compose.swift` für die fertigen Bilder.
#
# UNTERSCHIED ZU Mika+FileScope: Dort wird EIN Anwendungsfenster an fester Position
# aufgenommen. Mika+Grid hat kein Hauptfenster — das Popover misst 280 Punkte, die
# Einstellungen 580×420. Fensterverwaltung ist an einem einzelnen Fenster nicht zu zeigen;
# jede Aufnahme hier ist deshalb der ganze Bildschirm mit gesnappten Fenstern darauf. Das
# Popover wird später über das `highlight`-Layout herausvergrößert.
#
# AUFGENOMMEN WIRD DIE STORE-FASSUNG, nicht das Direktziel: Die Fußzeile des Popovers
# zeigt „Updates" nur, wenn es einen Update-Kanal gibt. Ein Bild der Direktfassung zeigte
# im Store eine Schaltfläche, die es dort nicht gibt.
#
# Drei Fallen, die hier bewusst behandelt werden:
#
#   - Das Popover läuft im Stil `.menuBarExtraStyle(.window)` und schließt, sobald eine
#     andere App aktiv wird. Die Reihenfolge „erst snappen, dann Popover, dann aufnehmen"
#     ist deshalb nicht verhandelbar.
#   - Die Bedienungshilfen zeichnen nach einem Klick über System Events einen grünen Ring
#     an die Mausposition. Zwischen letztem Klick und Aufnahme liegt ein Neustart des
#     Dienstes.
#   - Das private Schreibtischbild darf nicht in den Store. Es wird für die Dauer der
#     Aufnahme ersetzt und über `trap` zurückgestellt — ebenso die Dock-Automatik.
set -euo pipefail

PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ZIEL="$PROJEKT/AppStore/screenshots/raw/en"
APP="$PROJEKT/build/xcode-mas/Build/Products/Release/Mika+Grid.app"
KULISSE="$HOME/Downloads/Grid Demo"
GRUND="$PROJEKT/AppStore/screenshots/raw/wallpaper.png"

if [[ "${1:-}" == "--build" ]]; then
    echo "==> Store-Fassung bauen"
    (cd "$PROJEKT" && xcodegen generate >/dev/null)
    # Durchgängig ad-hoc: Mischt Xcode die Identitäten (Framework so, Binary anders), lädt
    # dyld das Framework nicht — „different Team IDs".
    (cd "$PROJEKT" && xcodebuild -project MikaGrid.xcodeproj \
        -scheme "MikaGrid (App Store)" -configuration Release \
        -derivedDataPath build/xcode-mas \
        CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual \
        DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" build >/dev/null)

    # Ohne Team-Kennung scheitert die Library Validation des Hardened Runtime auch dann,
    # wenn beide Teile ad-hoc signiert sind. `scripts/build.sh` löst das für die
    # Direktfassung genauso: die Ausnahme kommt in eine KOPIE der Entitlements, nie in die
    # Datei im Repository — PlistBuddy schriebe sie neu und verlöre die Begründung darin,
    # warum disable-library-validation dort gerade nicht steht.
    ENT="$PROJEKT/build/xcode-mas/adhoc-mas.entitlements"
    cp "$PROJEKT/Resources/MikaGridMAS.entitlements" "$ENT"
    /usr/libexec/PlistBuddy \
        -c "Add :com.apple.security.cs.disable-library-validation bool true" "$ENT" >/dev/null
    codesign --force --sign - --timestamp=none \
        "$APP/Contents/Frameworks/MikaGridCore.framework/Versions/A" >/dev/null 2>&1
    codesign --force --sign - --timestamp=none --options runtime \
        --entitlements "$ENT" "$APP" >/dev/null 2>&1
    echo "    ad-hoc signiert (nur für die Aufnahme — das Archiv für den Store entsteht"
    echo "    über scripts/release.sh --store und trägt diese Ausnahme nicht)"
fi

# Kein stiller Rückfall auf das Direktziel — siehe Kopf.
[[ -d "$APP" ]] || {
    echo "✘ $APP fehlt."
    echo "  Mit --build starten. Ein Bild der Direktfassung ist KEIN Ersatz:"
    echo "  deren Popover zeigt eine „Updates\"-Schaltfläche, die es im Store nicht gibt."
    exit 1
}

# --- Vorbedingungen, die sich nicht skripten lassen ----------------------------------------
#
# Die Store-Fassung bewegt kein Fenster ohne den Companion-Kurzbefehl in der Mediathek und
# ohne die einmal erteilte Erlaubnis, Kurzbefehle zu steuern. Ohne beides entstünden fünf
# Bilder ungesnappter Fenster — und zwar ohne Fehlermeldung.
echo "==> Vorbedingungen prüfen"
if ! osascript -e 'tell application "Shortcuts Events" to exists shortcut "Mika+Grid Snap"' 2>/dev/null | grep -q true; then
    cat <<'HINWEIS'
✘ Der Companion-Kurzbefehl „Mika+Grid Snap" fehlt, oder die Erlaubnis zur Steuerung
  von Kurzbefehlen wurde nicht erteilt.

  Einmalig von Hand:
    1. Die Store-Fassung starten und das Onboarding bis „Set Up Shortcut" durchklicken.
    2. Den Kurzbefehl hinzufügen lassen.
    3. Einmal ⌃⌥← drücken und den Systemdialog bestätigen.

  Die erste Antwort von Kurzbefehlen ist immer leer — dahinter steckt genau diese
  Rückfrage, die macOS bei einem unsichtbaren Aufruf nicht stellen kann.
HINWEIS
    exit 1
fi

# --- Bildschirmgeometrie ermitteln, nicht verdrahten ---------------------------------------
read -r _ _ BR HO <<<"$(osascript -e 'tell application "Finder" to get bounds of window of desktop' | tr ',' ' ')"
X=0; Y=0
echo "    Bildschirm: ${BR}×${HO} Punkte"

# --- Systemzustand sichern und über trap zurückstellen -------------------------------------
# Der Originalzustand wird in einer Datei gemerkt, nicht nur in einer Variablen — und
# NUR beim ersten Lauf geschrieben.
#
# Ohne diese Datei kaskadiert der Fehler: Bricht ein Lauf ab, bevor `trap` greift, liest
# der nächste Lauf den bereits gesetzten Aufnahmezustand als „Original" und schreibt ihn
# fest. Nach zwei Läufen ist das echte Schreibtischbild des Betreibers dann nicht mehr zu
# ermitteln. Genau so ist es hier einmal passiert.
ZUSTAND="$PROJEKT/build/capture-zustand"
if [[ ! -f "$ZUSTAND" ]]; then
    mkdir -p "$(dirname "$ZUSTAND")"
    {
        osascript -e 'tell application "System Events" to get picture of current desktop' 2>/dev/null || echo ""
        defaults read com.apple.dock autohide 2>/dev/null || echo 0
    } > "$ZUSTAND"
fi
GRUND_ALT="$(sed -n '1p' "$ZUSTAND")"
DOCK_ALT="$(sed -n '2p' "$ZUSTAND")"

# Ein Lauf, der das eigene Aufnahme-Wallpaper als Original vorfindet, würde es festschreiben.
if [[ "$GRUND_ALT" == "$GRUND" ]]; then
    echo "⚠ Der gemerkte Schreibtischgrund ist das Aufnahmebild selbst — build/capture-zustand"
    echo "  stammt aus einem abgebrochenen Lauf. Datei löschen und Grund von Hand setzen."
fi

aufraeumen () {
    [[ -n "$GRUND_ALT" ]] && osascript -e "tell application \"System Events\" to set picture of current desktop to \"$GRUND_ALT\"" >/dev/null 2>&1 || true
    defaults write com.apple.dock autohide -bool "$([[ "$DOCK_ALT" == "1" ]] && echo true || echo false)" 2>/dev/null || true
    killall Dock 2>/dev/null || true
    osascript -e 'tell application "TextEdit" to quit saving no' >/dev/null 2>&1 || true
    rm -f "$ZUSTAND"
}
trap aufraeumen EXIT

# Der Markengrund ist aus make-wallpaper.swift reproduzierbar und liegt deshalb nicht im
# Repository — ein 4-MB-Bild einzuchecken, das ein Skript in zwei Sekunden erzeugt, lohnt
# nicht.
if [[ ! -f "$GRUND" ]]; then
    swift "$PROJEKT/AppStore/tools/make-wallpaper.swift" >/dev/null 2>&1 || true
fi
if [[ -f "$GRUND" ]]; then
    osascript -e "tell application \"System Events\" to set picture of current desktop to \"$GRUND\"" >/dev/null
fi
defaults write com.apple.dock autohide -bool true
killall Dock 2>/dev/null || true
sleep 2

# --- Kulisse: nur Systemprogramme mit eigens gesetztem Inhalt ------------------------------
#
# Kein Terminal (die Eingabeaufforderung trägt Benutzer- und Rechnernamen), kein Browser
# (Favoritenleiste, Verlauf), kein Finder (Seitenleiste mit Gerätename und iCloud-Konto).
echo "==> Kulisse anlegen"
mkdir -p "$KULISSE"
cat > "$KULISSE/Notes.txt" <<'TXT'
Release notes — 1.2.0

Left half, right half, quarters, maximize, centre.
Every layout sits on Control-Option.

The window you are reading sits where a keystroke put it.
TXT
cat > "$KULISSE/Draft.txt" <<'TXT'
Draft

Two windows side by side is the whole point:
one to read from, one to write in.

No dragging, no aiming at a window edge.
TXT
cat > "$KULISSE/Notes 2.txt" <<'TXT'
Reading list

Four windows, four corners.
Nothing overlaps, nothing is hidden behind anything.
TXT
cat > "$KULISSE/Scratch.txt" <<'TXT'
Scratch

The fourth corner. Control-Option-K put it here.
TXT

# Das Onboarding darf beim Start NICHT aufgehen — sein Fenster stünde sonst in jedem
# Motiv. Motiv 04 löscht den Schlüssel gezielt und setzt ihn danach zurück; ohne diese
# Zeile beginnt ein zweiter Lauf mitten im Onboarding. Einmal beobachtet.
defaults write lu.daumedia.mikagrid hasCompletedOnboarding -bool true 2>/dev/null || true

# Alles ausblenden, was nicht zur Kulisse gehört. Ohne das steht hinter dem
# Onboarding-Fenster der echte Arbeitsplatz — beim ersten Lauf waren Terminalverlauf,
# Projektnamen und Git-Branch des Betreibers im Bild. Ein Store-Screenshot zeigt genau
# zwei Programme: TextEdit als Kulisse und Mika+Grid. Der Finder gehört ausdrücklich NICHT
# dazu — seine Fensterleiste trägt den Pfad samt Benutzernamen.
KULISSE_APPS='{"TextEdit", "MikaGrid"}'
fremde_ausblenden () {
    osascript <<AS >/dev/null 2>&1 || true
tell application "System Events"
    repeat with p in (every process whose visible is true and background only is false)
        if name of p is not in $KULISSE_APPS then
            try
                set visible of p to false
            end try
        end if
    end repeat
end tell
AS
    sleep 1
}

ruhe () {
    for _ in 1 2 3; do
        pkill -f "Assistive Control" 2>/dev/null || true
        sleep 1
    done
    sleep 1
}

# $1 = Dateiname, $2 = (optional) Prozess, der beim Auslösen vorn stehen soll.
#
# `fremde_ausblenden` wird hier NICHT aufgerufen: Es verschiebt den Fokus, und das
# Einstellungsfenster rutschte dadurch hinter die Kulisse. Ausgeblendet wird einmal zu
# Beginn und noch einmal nach dem Neustart für Motiv 04.
aufnehmen () {
    ruhe
    if [[ -n "${2:-}" ]]; then
        osascript -e "tell application \"System Events\" to tell process \"$2\" to set frontmost to true" >/dev/null 2>&1 || true
        sleep 0.8
    fi
    screencapture -o -x -R$X,$Y,$BR,$HO "$ZIEL/$1.png"
    echo "    $1.png"
}

# Snappt das vorderste Fenster der genannten App. Erst aktivieren, dann Kürzel — sonst
# trifft es das falsche Fenster.
snap () {   # $1 = App-Name, $2 = key code
    osascript -e "tell application \"$1\" to activate" >/dev/null
    sleep 0.5
    osascript -e "tell application \"System Events\" to key code $2 using {control down, option down}" >/dev/null
    sleep 1.0   # gemessen: 0,21–0,32 s je Snap über Kurzbefehle
}

# LaunchServices verweigert einer ad-hoc signierten App den Start über `open` — der
# direkte Aufruf des Binaries geht trotzdem. Beide Wege, damit das Skript sowohl mit einem
# ad-hoc gebauten Bundle als auch mit einer ordentlich signierten Fassung läuft.
app_starten () {
    open "$APP" >/dev/null 2>&1 || true
    sleep 3
    if ! pgrep -f "$APP/Contents/MacOS/" >/dev/null 2>&1; then
        "$APP/Contents/MacOS/MikaGrid" >/dev/null 2>&1 &
        sleep 3
    fi
    # Bis das Menüleistenelement steht, vergeht ein Moment.
    for _ in 1 2 3 4 5 6 7 8; do
        if osascript -e 'tell application "System Events" to tell process "MikaGrid" to get count of menu bar items of menu bar 2' >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    echo "✘ Die App startet nicht oder zeigt kein Menüleistenelement."
    exit 1
}

popover_auf () {
    osascript -e 'tell application "System Events" to tell process "MikaGrid" to click menu bar item 1 of menu bar 2' >/dev/null
    sleep 1.0
}
popover_zu () {
    osascript -e 'tell application "System Events" to key code 53' >/dev/null
    sleep 0.5
}

# Misst, ob ein Snap wirklich etwas bewegt hat. Ohne die einmal erteilte Erlaubnis,
# Kurzbefehle zu steuern, bleibt jeder Snap wirkungslos — und zwar OHNE Fehler an dieser
# Stelle: Die App zeigt die Warnung nur in ihrem Popover, das Skript nähme fünf Bilder
# ungesnappter Fenster auf. Genau das ist einmal passiert.
snap_wirkt_pruefen () {
    local vorher nachher
    vorher="$(osascript -e 'tell application "System Events" to tell process "TextEdit" to get position of window 1' 2>/dev/null || echo "?")"
    snap TextEdit 124
    nachher="$(osascript -e 'tell application "System Events" to tell process "TextEdit" to get position of window 1' 2>/dev/null || echo "?")"
    if [[ "$vorher" == "$nachher" ]]; then
        cat <<'HINWEIS'

✘ Der Snap hat nichts bewegt. Es fehlt die Erlaubnis, Kurzbefehle zu steuern — die App
  zeigt das in ihrem Popover als „Permission to control Shortcuts is required".

  Diese Erlaubnis erteilt nur ein Systemdialog, und der erscheint erst beim ersten
  Versuch. Einmalig von Hand:

    1. Mika+Grid aus build/xcode-mas/Build/Products/Release/ starten.
    2. Ein beliebiges Fenster nach vorn holen, dann ⌃⌥← drücken.
    3. Im Systemdialog „Erlauben" wählen.

  Danach dieses Skript erneut starten. Die erste Antwort von Kurzbefehlen ist immer leer —
  dahinter steckt genau diese Rückfrage, die macOS bei einem unsichtbaren Aufruf nicht
  stellen kann.

HINWEIS
        exit 1
    fi
}

mkdir -p "$ZIEL"

echo "==> App starten"
pkill -f "Mika+Grid" 2>/dev/null || true
sleep 1
app_starten

echo "==> Aufnehmen"

fenster_nach_vorn () {   # $1 = Dokumentname
    osascript -e "tell application \"TextEdit\" to set index of window \"$1\" to 1" >/dev/null 2>&1 || true
    sleep 0.4
}

# 01 · Zwei Fenster als Hälften, Popover offen
open -a TextEdit "$KULISSE/Notes.txt"; sleep 2
open -a TextEdit "$KULISSE/Draft.txt"; sleep 2
fremde_ausblenden                       # einmal: alles weg, was nicht Kulisse ist
snap_wirkt_pruefen                      # bricht ab, wenn die Erlaubnis fehlt
fenster_nach_vorn "Draft.txt";  snap TextEdit 124    # ⌃⌥→
fenster_nach_vorn "Notes.txt";  snap TextEdit 123    # ⌃⌥←
popover_auf
aufnehmen 01_halves
popover_zu

# 02 · Vier Fenster in den vier Ecken. Ohne Popover: Hier ist das Raster aus echten
# Fenstern die Aussage, ein Bedienelement davor nähme ihr die Wucht.
open -a TextEdit "$KULISSE/Notes 2.txt"; sleep 2
open -a TextEdit "$KULISSE/Scratch.txt"; sleep 2
fenster_nach_vorn "Notes.txt";    snap TextEdit 32   # ⌃⌥U  oben links
fenster_nach_vorn "Draft.txt";    snap TextEdit 34   # ⌃⌥I  oben rechts
fenster_nach_vorn "Notes 2.txt";  snap TextEdit 38   # ⌃⌥J  unten links
fenster_nach_vorn "Scratch.txt";  snap TextEdit 40   # ⌃⌥K  unten rechts
aufnehmen 02_quarters

# 03 · Ein Fenster füllt den Bildschirm, Popover offen
#
# Ursprünglich sollte hier die Kürzelübersicht stehen. Sie ist von außen nicht sicher
# erreichbar: Die Seitenleiste des Einstellungsfensters reagiert nicht auf einen
# synthetischen Klick, und der Weg über die Tastatur holt die Bedienungshilfen-Tastatur
# ins Bild. Der Onboarding-Schritt davor schaltet nicht weiter, solange der Kurzbefehl
# schon installiert ist — 03 und 04 waren dadurch zweimal dasselbe Bild. Maximize zeigt
# stattdessen eine echte Aktion und braucht keine Fensternavigation.
osascript -e 'tell application "TextEdit" to close (every window whose name is not "Notes.txt") saving no' >/dev/null 2>&1 || true
sleep 1.5
fenster_nach_vorn "Notes.txt";  snap TextEdit 36     # ⌃⌥↩
popover_auf
aufnehmen 03_maximize
popover_zu

# 05 · Dasselbe Fenster zentriert
fenster_nach_vorn "Notes.txt";  snap TextEdit 8      # ⌃⌥C
popover_auf
aufnehmen 05_center
popover_zu

# 04 · aus dem Onboarding — zuletzt, weil dafür die App neu startet.
#
# Der Ablauf hat drei Seiten: Begrüßung, Companion-Kurzbefehl, Kürzelübersicht. Die
# Weiter-Schaltfläche ist das einzige Bedienelement der Seite und deshalb sicher als
# `button 1` zu treffen — anders als die Seitenleiste des Einstellungsfensters, die auf
# einen synthetischen Klick nicht reagiert und nur über die Tastatur umschaltet. Genau das
# holte in einem früheren Lauf die Bedienungshilfen-Tastatur ins Bild.
echo "    (04 aus dem Onboarding — dafür startet die App neu)"
pkill -f "Mika+Grid" 2>/dev/null || true
sleep 1
defaults delete lu.daumedia.mikagrid hasCompletedOnboarding 2>/dev/null || true
app_starten
sleep 2
fremde_ausblenden

onboarding_setzen () {
    osascript <<'AS' >/dev/null 2>&1 || true
tell application "System Events" to tell process "MikaGrid"
    set frontmost to true
    if (count of windows) > 0 then tell window 1 to set position to {516, 200}
end tell
AS
    sleep 0.8
}
weiter () {
    osascript -e 'tell application "System Events" to tell process "MikaGrid" to click button 1 of UI element 1 of window 1' >/dev/null 2>&1 || true
    sleep 1.5
}

onboarding_setzen
weiter                                  # Begrüßung → Companion-Kurzbefehl
onboarding_setzen
aufnehmen 04_setup MikaGrid


# Zurückstellen, sonst beginnt der nächste Lauf mitten im Onboarding.
defaults write lu.daumedia.mikagrid hasCompletedOnboarding -bool true 2>/dev/null || true

echo ""
echo "==> $(ls "$ZIEL"/*.png 2>/dev/null | wc -l | tr -d ' ') Rohaufnahmen in AppStore/screenshots/raw/en/"
echo "    Weiter mit: swift AppStore/tools/compose.swift"
