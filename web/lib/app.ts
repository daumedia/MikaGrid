// Single source of truth for all product data shown on the site.
// Keep in sync with Resources/Info.plist and appcast.xml on every release.

export const APP = {
  name: "Mika+Grid",
  tagline: "Snap. Organize. Focus.",
  description:
    "A lightweight macOS menubar window manager. Snap windows to halves, quarters, or a centered layout with a keystroke — or click a zone in the visual grid.",
  version: "1.2.0",
  minMacOS: "14.0",
  minMacOSName: "Sonoma",
  arch: "Universal (Apple Silicon + Intel)",
  license: "MIT",
  repo: "https://github.com/daumedia/MikaGrid",
  // /blob/HEAD/ folgt immer dem Standardzweig. Bis 1.1.1 stand hier /blob/master/ —
  // fest verdrahtet auf einen Zweig, der nicht der Entwicklungszweig ist.
  licenseUrl: "https://github.com/daumedia/MikaGrid/blob/HEAD/LICENSE",
  releases: "https://github.com/daumedia/MikaGrid/releases",
  dmgUrl:
    "https://github.com/daumedia/MikaGrid/releases/download/v1.2.0/Mika%2BGrid-v1.2.0.dmg",
  dmgSizeMB: 2.5,
  siteUrl: "https://mikagrid.vercel.app",
  vendor: "Daumedia",
  vendorUrl: "https://daumedia.lu",
} as const
