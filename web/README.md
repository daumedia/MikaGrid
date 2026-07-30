# Mika+Grid — Marketing Site

Next.js 15 landing page for Mika+Grid, deployed on Vercel.

## Develop

```bash
npm install
npm run dev      # http://localhost:3000
npm run build    # production build (fully static)
npm start        # serve the production build
```

## Stack

- Next.js 15 (App Router) + TypeScript
- Tailwind CSS v4 — tokens live in `app/globals.css` under `@theme`, mirroring
  `Sources/MikaPlusColors.swift`
- No UI or animation libraries; the snap demo is React state + CSS transitions
- OG image is generated at build time by `app/opengraph-image.tsx` (`next/og`)

## Deploy

Import the repository in Vercel and set **Root Directory** to `web`. Everything
else is zero-config. Or from the CLI:

```bash
npx vercel --cwd web
```

## Release checklist

`lib/app.ts` is the single source of truth for version, download URL and DMG
size. On every app release, update it to match:

| Field in `lib/app.ts` | Source |
|---|---|
| `version` | `Resources/Info.plist` → `CFBundleShortVersionString` |
| `dmgUrl` | the new GitHub release asset |
| `dmgSizeMB` | `appcast.xml` → `enclosure length` (bytes ÷ 1024²) |
| `minMacOS` | `Resources/Info.plist` → `LSMinimumSystemVersion` |

`lib/snapActions.ts` mirrors `Sources/SnapAction.swift`. If snap actions or
their default bindings change, update it too.
