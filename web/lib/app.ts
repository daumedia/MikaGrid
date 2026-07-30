// Single source of truth for all product data shown on the site.
// Keep in sync with Resources/Info.plist and appcast.xml on every release.

export const APP = {
  name: "Mika+Grid",
  tagline: "Snap. Organize. Focus.",
  description:
    "A lightweight macOS menubar window manager. Snap windows to halves, quarters, or a centered layout with a keystroke — or click a zone in the visual grid.",
  version: "1.1.0",
  minMacOS: "14.0",
  minMacOSName: "Sonoma",
  arch: "Apple Silicon",
  license: "MIT",
  repo: "https://github.com/Mukaarts/MikaGrid",
  releases: "https://github.com/Mukaarts/MikaGrid/releases",
  dmgUrl:
    "https://github.com/Mukaarts/MikaGrid/releases/download/v1.1.0/Mika%2BGrid-v1.1.0.dmg",
  dmgSizeMB: 2.5,
  siteUrl: "https://mikagrid.vercel.app",
  vendor: "Daumedia",
  vendorUrl: "https://daumedia.lu",
} as const
