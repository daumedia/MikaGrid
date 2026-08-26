// check-web-sync.mjs — verifies that web/lib mirrors the Swift sources.
//
// web/lib/app.ts and web/lib/snapActions.ts duplicate values from Info.plist, appcast.xml
// and SnapAction.swift by hand. CLAUDE.md says to keep them in sync on every release; a
// reminder is not a safeguard, so this script checks it.

import { readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

const root = join(dirname(fileURLToPath(import.meta.url)), "..")
const read = (p) => readFileSync(join(root, p), "utf8")

let failures = 0
const check = (label, actual, expected) => {
  if (actual === expected) {
    console.log(`  ✓ ${label}`)
  } else {
    console.error(`  ✗ ${label}: web says "${actual}", source says "${expected}"`)
    failures++
  }
}

const plist = read("Resources/Info.plist")
const plistMAS = read("Resources/Info-MAS.plist")
const appTs = read("web/lib/app.ts")
const actionsSwift = read("Sources/MikaGridCore/SnapAction.swift")
const actionsTs = read("web/lib/snapActions.ts")

const plistValue = (key) =>
  plist.match(new RegExp(`<key>${key}</key>\\s*<string>([^<]+)</string>`))?.[1]
const plistMASValue = (key) =>
  plistMAS.match(new RegExp(`<key>${key}</key>\\s*<string>([^<]+)</string>`))?.[1]
const tsValue = (key) => appTs.match(new RegExp(`${key}:\\s*"([^"]+)"`))?.[1]

console.log("Checking web/lib against the Swift sources...")
check("version", tsValue("version"), plistValue("CFBundleShortVersionString"))
check("minMacOS", tsValue("minMacOS"), plistValue("LSMinimumSystemVersion"))

// Seit Feature 01 gibt es zwei Fassungen mit verschiedenen Mindestsystemen. Ohne diese
// Prüfung nennt die Website weiter macOS 14, während der Store 15 verlangt.
check("minMacOSStore", tsValue("minMacOSStore"), plistMASValue("LSMinimumSystemVersion"))
check("beide Fassungen tragen dieselbe Version",
      plistMASValue("CFBundleShortVersionString"), plistValue("CFBundleShortVersionString"))

const dmgUrl = appTs.match(/dmgUrl:\s*\n?\s*"([^"]+)"/)?.[1] ?? ""
const version = plistValue("CFBundleShortVersionString")
check("dmgUrl points at the current version", dmgUrl.includes(`/v${version}/`), true)

// DMG size against the length declared in the appcast
const length = Number(read("appcast.xml").match(/length="(\d+)"/)?.[1] ?? 0)
const sizeMB = Number(appTs.match(/dmgSizeMB:\s*([\d.]+)/)?.[1] ?? 0)
const expectedMB = Math.round((length / 1_000_000) * 10) / 10
if (Math.abs(sizeMB - expectedMB) <= 0.1) {
  console.log(`  ✓ dmgSizeMB (${sizeMB} MB ≈ ${length} bytes)`)
} else {
  console.error(`  ✗ dmgSizeMB: web says ${sizeMB}, appcast length implies ${expectedMB}`)
  failures++
}

// Every SnapAction case must appear in the mirror, with the same label
const swiftCases = [...actionsSwift.matchAll(/^\s{4}case (\w+)$/gm)].map((m) => m[1])
const tsIds = [...actionsTs.matchAll(/id:\s*"(\w+)"/g)].map((m) => m[1])
check("snap action count", tsIds.length, swiftCases.length)
for (const name of swiftCases) {
  if (!tsIds.includes(name)) {
    console.error(`  ✗ snapActions.ts is missing "${name}"`)
    failures++
  }
}
// Nur den `var label`-Block auswerten: `systemImage` hat dieselbe Form und würde die
// Beschriftungen sonst überschreiben.
const labelBlock = actionsSwift.match(/var label: String \{[\s\S]*?\n    \}/)?.[0] ?? ""
const swiftLabels = Object.fromEntries(
  [...labelBlock.matchAll(/case \.(\w+):\s*return "([^"]+)"/g)].map((m) => [m[1], m[2]])
)
if (Object.keys(swiftLabels).length === 0) {
  console.error("  ✗ could not read the label block from SnapAction.swift")
  failures++
}
for (const [id, label] of [...actionsTs.matchAll(/id:\s*"(\w+)",\s*label:\s*"([^"]+)"/g)].map(
  (m) => [m[1], m[2]]
)) {
  if (swiftLabels[id] && swiftLabels[id] !== label) {
    console.error(`  ✗ label for "${id}": web says "${label}", Swift says "${swiftLabels[id]}"`)
    failures++
  }
}
if (swiftCases.length && !failures) console.log("  ✓ snap action labels match")

// --- AppStore/metadata gegen web/lib und die Swift-Quellen -----------------------------
//
// Die Store-Texte wiederholen Werte, die anderswo schon stehen: die Adresse der Website,
// den App-Namen, die Zahl der Aktionen, den Namen des Companion-Kurzbefehls. Ohne diese
// Prüfung wird „ten of the eleven actions" still falsch, sobald jemand eine zwölfte
// Aktion baut — und ein falscher Store-Eintrag lässt sich nicht ohne Review korrigieren.
const meta = (f) => read(`AppStore/metadata/en-US/${f}.txt`).trim()

console.log("\nChecking AppStore/metadata against web/lib and the Swift sources...")

const siteUrl = tsValue("siteUrl")
check("marketing_url == siteUrl", meta("marketing_url"), siteUrl)
check("support_url == siteUrl", meta("support_url"), siteUrl)
check("privacy_url == siteUrl + /privacy", meta("privacy_url"), `${siteUrl}/privacy`)
check("name.txt == APP.name", meta("name"), tsValue("name"))
check(
  "name.txt == CFBundleName (App Store)",
  meta("name"),
  plistMASValue("CFBundleName")
)

// Zehn statt elf: Restore braucht den vorherigen Fensterrahmen, und den meldet
// Kurzbefehle nicht zurück (ShortcutsWindowSnapper beantwortet .restore mit
// .nothingToRestore). Gerechnet statt abgeschrieben.
check(
  "APP.storeSnapActions == Aktionen − 1",
  appTs.match(/storeSnapActions:\s*(\d+)/)?.[1],
  String(swiftCases.length - 1)
)

check(
  "APP.companionShortcutName == CompanionShortcutManager.shortcutName",
  appTs.match(/companionShortcutName:\s*"([^"]+)"/)?.[1],
  read("Sources/MikaGridMAS/CompanionShortcutManager.swift").match(
    /shortcutName\s*=\s*"([^"]+)"/
  )?.[1]
)

if (failures) {
  console.error(`\n${failures} mismatch(es) — update web/lib before releasing.`)
  process.exit(1)
}
console.log("\nweb/lib is in sync with the Swift sources.")
