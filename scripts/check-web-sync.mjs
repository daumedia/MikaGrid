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
const appTs = read("web/lib/app.ts")
const actionsSwift = read("Sources/SnapAction.swift")
const actionsTs = read("web/lib/snapActions.ts")

const plistValue = (key) =>
  plist.match(new RegExp(`<key>${key}</key>\\s*<string>([^<]+)</string>`))?.[1]
const tsValue = (key) => appTs.match(new RegExp(`${key}:\\s*"([^"]+)"`))?.[1]

console.log("Checking web/lib against the Swift sources...")
check("version", tsValue("version"), plistValue("CFBundleShortVersionString"))
check("minMacOS", tsValue("minMacOS"), plistValue("LSMinimumSystemVersion"))

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

if (failures) {
  console.error(`\n${failures} mismatch(es) — update web/lib before releasing.`)
  process.exit(1)
}
console.log("\nweb/lib is in sync with the Swift sources.")
