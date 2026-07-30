import { Section } from "@/components/ui/Section"

type Feature = {
  title: string
  body: string
  icon: React.ReactNode
}

const stroke = {
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 1.6,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
}

const FEATURES: Feature[] = [
  {
    title: "Visual snap grid",
    body: "Open the menubar popover and click a zone. Each button previews the resulting layout on a miniature monitor.",
    icon: (
      <svg viewBox="0 0 24 24" aria-hidden="true" {...stroke}>
        <rect x="3" y="3" width="7.5" height="7.5" rx="1.5" />
        <rect x="13.5" y="3" width="7.5" height="7.5" rx="1.5" />
        <rect x="3" y="13.5" width="7.5" height="7.5" rx="1.5" />
        <rect x="13.5" y="13.5" width="7.5" height="7.5" rx="1.5" />
      </svg>
    ),
  },
  {
    title: "11 snap actions",
    body: "Halves, all four quarters, maximize, and a centered two-thirds layout for focused work — plus restore.",
    icon: (
      <svg viewBox="0 0 24 24" aria-hidden="true" {...stroke}>
        <rect x="3" y="4" width="18" height="16" rx="2" />
        <path d="M12 4v16M3 12h9" />
      </svg>
    ),
  },
  {
    title: "Global hotkeys",
    body: "Carbon-registered shortcuts that work from any app, without focus stealing. Every binding is reconfigurable.",
    icon: (
      <svg viewBox="0 0 24 24" aria-hidden="true" {...stroke}>
        <rect x="2" y="5.5" width="20" height="13" rx="2.5" />
        <path d="M6.5 9.5h.01M10 9.5h.01M13.5 9.5h.01M17 9.5h.01M7.5 14h9" />
      </svg>
    ),
  },
  {
    title: "Multi-monitor aware",
    body: "Snaps to the display the window's center sits on, converting between Accessibility and screen coordinates.",
    icon: (
      <svg viewBox="0 0 24 24" aria-hidden="true" {...stroke}>
        <rect x="2" y="4" width="13" height="10" rx="1.8" />
        <rect x="12" y="10" width="10" height="8" rx="1.8" />
        <path d="M7 18h6" />
      </svg>
    ),
  },
  {
    title: "Undo any snap",
    body: "The previous frame is remembered per window. One press of ⌃⌥⌫ puts it back exactly where it was.",
    icon: (
      <svg viewBox="0 0 24 24" aria-hidden="true" {...stroke}>
        <path d="M3 7v6h6" />
        <path d="M3.5 13a9 9 0 1 0 2.3-6.4L3 9" />
      </svg>
    ),
  },
  {
    title: "Signed auto-updates",
    body: "Sparkle checks for new versions and verifies every download with an EdDSA signature. Turn it off any time.",
    icon: (
      <svg viewBox="0 0 24 24" aria-hidden="true" {...stroke}>
        <path d="M12 3 4.5 6v5.5c0 4.4 3.1 8.2 7.5 9.5 4.4-1.3 7.5-5.1 7.5-9.5V6L12 3Z" />
        <path d="m9 12 2 2 4-4" />
      </svg>
    ),
  },
]

export function Features() {
  return (
    <Section
      id="features"
      eyebrow="Features"
      title="Everything a window manager needs. Nothing it doesn't."
      lead="Native Swift and SwiftUI, no Electron, no background service. It sits in the menubar and stays out of your way."
      className="border-t border-line bg-dark-bg"
    >
      <div className="grid gap-px overflow-hidden rounded-2xl border border-line bg-line sm:grid-cols-2 lg:grid-cols-3">
        {FEATURES.map((f) => (
          <div key={f.title} className="group bg-dark-bg p-7 transition-colors hover:bg-white/[0.03]">
            <div className="mb-5 inline-flex h-11 w-11 items-center justify-center rounded-xl border border-line-strong bg-elevated text-teal-primary transition-colors group-hover:text-teal-light">
              <span className="block h-5 w-5">{f.icon}</span>
            </div>
            <h3 className="font-display text-lg font-semibold tracking-tight text-teal-surface">
              {f.title}
            </h3>
            <p className="mt-2 text-sm leading-relaxed text-teal-lightest/60">
              {f.body}
            </p>
          </div>
        ))}
      </div>
    </Section>
  )
}
