# Changelog

## [1.2.0 · App Store] - 2026-09-03

Released on the Mac App Store as build 3 of 1.2.0 —
[apps.apple.com/app/id6805495907](https://apps.apple.com/app/id6805495907). Same marketing
version as the direct download, a different binary: sandboxed, macOS 15 and up, moving
windows through Shortcuts instead of the Accessibility API.

**The direct download has not been re-cut for 1.2.0.** The newest DMG on the releases page
is still 1.1.1, and `appcast.xml` has no 1.2.0 entry — Sparkle users stay on 1.1.1 until
`scripts/release.sh` runs, which needs the notarisation credentials.

### App Store distribution (feature 01)
- **Two apps from one source tree.** `MikaGridCore` carries everything both versions share
  — snap geometry, hotkeys, popover, preferences, onboarding. What differs is exactly one
  seam: how a window is actually moved (`WindowSnapping`)
- **The App Store version is sandboxed** and does not move windows itself. It asks Apple's
  Shortcuts app, addressed through `Shortcuts Events`, which runs shortcuts without opening
  any window — measured at 0.21–0.32 s per snap with no foreground change
- **Narrower entitlement than planned.** The design called for the deprecated
  `temporary-exception.apple-events`; `Shortcuts Events` turned out to publish the access
  group `com.apple.shortcuts.run`, so the store build uses `scripting-targets` instead
- **One bundle id for both versions** (`lu.daumedia.mikagrid`). An earlier draft gave the
  store build a `.mas` suffix so both could be installed side by side; App Store Connect
  holds a single record, so that was dropped (OF-04). The price is that the two versions
  cannot coexist — they share preferences and the login item, and LaunchServices cannot
  tell them apart. Harmless while only one channel ships
- **Build system moved to XcodeGen.** `project.yml` is the source of truth; `.xcodeproj` is
  generated and git-ignored. Archiving for App Store Connect needs an Xcode project
- **Tests now hang off the library** instead of the executable target — all 45 existing
  tests kept running, 17 new ones added for the payload and the reply

### Privacy
- **Neither version passes window titles anywhere.** The store version was originally going
  to hand the title to Shortcuts when an app has several windows; that turned out to be
  unnecessary — the companion shortcut works on the frontmost window, so the payload is
  five numbers and a random value

### The store listing itself
- **`AppStore/` holds everything App Store Connect asks for** — the texts in Fastlane
  layout (`metadata/en-US/*.txt`), the screenshots, the answers to the privacy and age
  questionnaires with their evidence in the code, and a checklist of what can only be done
  inside the Apple account. Same structure as Mika+FileScope
- **The listing says ten actions, not eleven.** `.restore` returns `.nothingToRestore` in
  the store version, so promising eleven would be inaccurate metadata. `StoreAssetTests`
  fails if "eleven" ever appears in a store text
- **The companion shortcut is named in the description, not the promotional text** — the
  latter is editable without review and is no place for a required disclosure (AK-20)
- **New checks in `swift test`**: character limits, screenshot dimensions and alpha
  channel, that every shot has its own raw capture, that `MikaGridCore` and `MikaGridMAS`
  contain no networking, and that the listing agrees with `Info-MAS.plist` on name,
  category, minimum system and bundle id
- **`scripts/check-web-sync.mjs` now also checks the store texts** against `web/lib/app.ts`
  and the Swift sources — the count of ten actions is recalculated, not copied
- **The site gained a "Versions" section** comparing both editions, and the three feature
  cards that only apply to the direct download are marked as such

### Known limits of the App Store version
- **"Restore previous position" is not available.** Shortcuts does not return a window's
  frame, so there is nothing to remember. Ten of the eleven actions remain
- **No verification after the move.** The direct version measures the frame back after
  writing it; the store version cannot, for the same reason
- **Screen selection is limited.** `Move Window` rejects negative coordinates, so a display
  positioned above or to the left of the main one cannot be targeted
- **No verification that the frame actually landed.** The window is placed exactly on the
  computed target — measured against `SnapAction.targetFrame` all four values match. But
  if the target application clamps the frame (TextEdit rounds to line heights, for
  instance), the store version does not notice, because Shortcuts reports nothing back

## [1.2.0] - 2026-08-25

Hardening release. Every gap recorded during the SDD capture (`docs/`, `features/`) is
addressed here — 73 findings across ten features, plus the first test suite the project
has ever had.

### Security & distribution
- **Releases are signed with a Developer ID** instead of ad-hoc. `scripts/build.sh` picks
  the identity up automatically and falls back to ad-hoc only for local builds
- **`disable-library-validation` is gone.** It was added to make the ad-hoc signed
  Sparkle.framework load; with a Developer ID signature the reason disappears, which was
  verified by building and launching without it. The hardened runtime is no longer weakened
  in normal builds — the entitlement is re-added automatically for ad-hoc builds only
- **`codesign --deep` removed from signing.** It re-signed every nested component with the
  app's entitlements, undoing the careful inside-out signing above it and imprinting
  `disable-library-validation` onto Sparkle's XPC services, which ship with none
- **A missing Sparkle.framework is now a hard error** instead of being skipped silently,
  which used to produce a bundle that could not update and crashed at launch
- **`scripts/release.sh`** builds, signs, notarises (with `NOTARY_PROFILE`), packages,
  generates the appcast signature and verifies that `Info.plist`, `CHANGELOG.md`,
  `appcast.xml` and `web/lib/app.ts` agree — three steps that were manual and unchecked
- **The DMG is signed**; universal builds (`--universal`) cover Apple Silicon and Intel
- **appcast.xml**: `sparkle:version` now carries the build number everywhere, and the
  1.0.0 entry — which had no enclosure and pointed at a release that never existed — is gone

### Fixed
- **Failed snaps no longer fail silently.** All six abort paths returned nothing at all, so
  a missing permission looked exactly like a broken app. Every failure now produces a system
  beep and, in the popover, a reason
- **Restore survives a title change.** The undo history was keyed by process ID and window
  title, so switching a browser tab or saving a file lost the entry — and made all untitled
  windows of one app collide. The key is now the system window number
- **Repeated snapping keeps the original frame.** ⌃⌥← followed by ⌃⌥→ used to overwrite the
  restore point with the left half; the original size was gone
- **The centre zone preview showed ~80 % × 69 % instead of two thirds.** The popover rebuilt
  all eleven zones by hand; they are now derived from the real target geometry
- **A snap action added in a future release would have had no shortcut** on existing
  installs: missing bindings are backfilled with their defaults, and stored bindings now
  carry a schema version
- **Failed hotkey registration is visible.** A combination already held by another app was
  silently dropped while Preferences kept showing it as active
- **Reserved system shortcuts are rejected** — you can no longer bind ⌘Q to "Maximize"
- **Cancelling the onboarding no longer counts as completing it.** Esc or the close button
  marked it done, so a user who wanted to look at it later never saw it again
- **"Reset All Settings" returns to the factory state.** It re-set the onboarding flag to
  "completed" immediately after clearing it, and left every Sparkle preference untouched
- **The About window is reachable again.** 1.1.0 replaced the popover's "About" button with
  "Updates" and took the only trigger with it, leaving 85 lines of unreachable code
- **Login item failures are shown** instead of being written to the console while the toggle
  kept claiming success
- Full-screen windows are detected explicitly rather than assumed to be non-settable
- The last-active foreign app is forgotten when it quits, so its process ID cannot be reused
- Snap history is capped at 100 entries and cleared when displays change
- `NSScreen.primaryHeight` returns `nil` instead of a silent `0` that made every coordinate wrong
- The keyboard monitor of the shortcut recorder is released when the window closes
- The permission step advances exactly once instead of spawning a task per tick
- The onboarding shortcut list shows the actual bindings, not a hardcoded copy
- The launch-at-login toggle reads the real system state instead of defaulting to "on"

### Added
- **`Tests/` — 45 tests**, the first in the project: snap geometry (halves tile without a
  gap on fractional displays, quarters cover exactly, centre is two thirds), shortcut
  persistence including the backfill and schema-version cases, window history including
  eviction, and the failure reasons. One of them caught a real bug in this release's own
  preview fix
- **`.github/workflows/ci.yml`** — build, test, sign, website build and a version
  consistency check on every push
- **`scripts/check-web-sync.mjs`** verifies that `web/lib` still mirrors the Swift sources
- **Second update toggle**: "Install updates automatically" was active on disk but had no
  control in the app
- **Update failures are reported** — Sparkle ran without a delegate, so a permanently dead
  update path was invisible to everyone
- **`LICENSE`** — the README, the site and the structured data all promised MIT while the
  file did not exist
- **Privacy and legal pages** on the website, plus `docs/datenschutz.md`
- **Accessibility**: labels and hints on the snap zones, status shown by icon as well as
  colour, a Back button in the onboarding
- ⌘, and ⌘Q work while the popover is open — a menu bar app has no application menu

### Changed
- Accessibility deep link uses the current System Settings identifier, with the pre-Ventura
  one as fallback
- "Skip for now" is withdrawn automatically once the permission is actually granted
- The popover keeps its permission indicator up to date while it is open
- The onboarding uses its own step switcher instead of a `TabView` that would draw an
  unlabelled tab bar on macOS

## [1.1.1] - 2026-08-08

### Fixed
- **Snap applies position and size in a single trigger** — previously only the size landed on the first hotkey press or popover click and the window had to be triggered a second time. `WindowManager` now temporarily disables `AXEnhancedUserInterface` on the target app (Chromium/Electron/Java apps and anything under VoiceOver animate AX frame changes, which cancelled the position write), writes size → position → size, and verifies the result by reading the frame back with up to two corrective passes (2 pt tolerance)
- **Snap frames are rounded to whole points** — halves and quarters now tile without a seam or overlap on scaled displays and notch Macs
- **Menu bar no longer hangs on unresponsive apps** — `AXUIElementSetMessagingTimeout` (0.25 s per element) plus a 0.6 s deadline for the whole snap
- **Popover snapped the wrong app** — with `.menuBarExtraStyle(.window)` Mika+Grid can become frontmost itself; the last active foreign app is now cached and used as the snap target
- **Duplicate hotkey firing** — `registerHotkeys()` installed an additional Carbon event handler on every shortcut change without removing the old one, so one keypress fired repeatedly and overwrote the Restore history with the already-snapped frame
- Non-resizable, dialog and fullscreen windows are skipped cleanly (`AXUIElementIsAttributeSettable`), missing Accessibility permission is guarded up front, and unchecked AX force-casts were replaced with `CFGetTypeID`-validated casts
- Screen height for the Cocoa↔AX conversion now comes from the display at global origin `(0,0)` instead of `NSScreen.screens.first`, which is not guaranteed to be the menu bar display

### Removed
- **"Enable snap animations" toggle** — the preference was never read by any code; the setting is gone from Preferences > General (the UserDefaults key is still cleared on reset)

## [1.1.0] - 2026-03-19

### Added
- **Sparkle Auto-Update** — integrated Sparkle 2.6+ for automatic update checks via menubar and preferences
- **Check for Updates** — "Updates" button in popover footer and "Check Now" in General preferences
- **Automatic Updates Toggle** — configurable in Preferences > General
- **appcast.xml** — GitHub-hosted update feed with EdDSA signature verification
- **Sparkle Framework Embedding** — build script embeds and signs Sparkle.framework with nested components

### Changed
- Package.swift: added Sparkle dependency
- Info.plist: added `SUFeedURL` and `SUPublicEDKey` for Sparkle
- Build script: embeds Sparkle.framework with inside-out codesigning
- Popover footer: "About" replaced with "Updates" button

## [1.0.0] - 2026-03-19

### Added
- **Menubar App** — native macOS menu bar app with `MenuBarExtra(.window)`, no Dock icon (`LSUIElement`)
- **Visual Snap Grid** — popover with clickable zones showing miniature monitor previews and shortcut labels; hover effects with Mika+ teal branding
- **Window Snapping** — AXUIElement-based window manipulation with 11 snap actions: Left/Right/Top/Bottom Half, four Quarters, Maximize, Center (2/3), and Restore
- **Multi-Monitor Support** — determines target screen by window center point; coordinate conversion between AX (top-left origin) and NSScreen (bottom-left origin)
- **Window Restore** — saves previous window position before each snap; ⌃⌥⌫ restores the original frame (keyed by PID + window title)
- **Global Hotkeys** — Carbon `RegisterEventHotKey` with signature `0x4D4B4744` ("MKGD"); 11 default bindings on ⌃⌥ + arrow/letter keys
- **Customizable Shortcuts** — inline shortcut recorder in Preferences with conflict detection and restore-defaults
- **Accessibility Permission** — `AXIsProcessTrusted()` check with guided permission request; polling timer for onboarding auto-advance; deep link to System Settings
- **First Launch Onboarding** — 3-screen guided flow: Welcome ("Snap. Organize. Focus."), Accessibility Permission with auto-polling, Shortcuts overview with Launch at Login toggle
- **Preferences Window** — 3-tab NavigationSplitView (General, Shortcuts, About) with NSWindow + NSHostingView pattern
- **General Preferences** — Launch at Login toggle (SMAppService), animation toggle, accessibility status indicator
- **About Tab** — version info, re-show onboarding, reset all settings with confirmation
- **About Window** — standalone branded window with Mika+ gradient background
- **Launch at Login** — SMAppService.mainApp integration
- **Mika+ Brand Colors** — shared color palette (`MikaPlusColors.swift`) matching the Mika+ ecosystem
- **App Icon** — custom 1024px icon with concentric rounded rectangles, crosshair, and "M+" badge
- **Build Pipeline** — SPM build + app bundle assembly + ad-hoc codesign (`scripts/build.sh`)
- **DMG Installer** — two scripts: `create-dmg.sh` (requires brew `create-dmg`) and `create-dmg-simple.sh` (built-in tools only); custom branded background with grid pattern
