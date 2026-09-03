import { Section } from "@/components/ui/Section"
import { DownloadButton, DownloadMeta } from "@/components/ui/DownloadButton"
import { AppStoreLink } from "@/components/ui/AppStoreLink"

const STEPS = [
  {
    title: "Download and install",
    body: "Grab the .dmg and drag Mika+Grid into your Applications folder.",
  },
  {
    title: "Grant Accessibility access",
    body: "A three-screen onboarding walks you through it and detects the moment you flip the switch in System Settings.",
  },
  {
    title: "Start snapping",
    body: "Press ⌃⌥← or click a zone in the menubar popover. That's the whole learning curve.",
  },
]

export function HowItWorks() {
  return (
    <Section
      id="install"
      eyebrow="Getting started"
      title="Up and running in under a minute"
      className="border-t border-line bg-dark-bg"
    >
      <ol className="grid gap-6 md:grid-cols-3">
        {STEPS.map((s, i) => (
          <li
            key={s.title}
            className="relative rounded-2xl border border-line bg-dark-bg-deep p-7"
          >
            <span className="font-mono text-sm text-teal-primary">
              {String(i + 1).padStart(2, "0")}
            </span>
            <h3 className="mt-4 font-display text-lg font-semibold tracking-tight text-teal-surface">
              {s.title}
            </h3>
            <p className="mt-2 text-sm leading-relaxed text-teal-lightest/60">
              {s.body}
            </p>
          </li>
        ))}
      </ol>

      <div className="mt-12 flex flex-col items-center gap-4 rounded-2xl border border-teal-primary/25 bg-teal-primary/[0.07] px-8 py-10 text-center">
        <h3 className="font-display text-2xl font-semibold tracking-tight text-teal-surface">
          Ready when you are
        </h3>
        <p className="max-w-md text-sm leading-relaxed text-teal-lightest/70">
          Free, open source, and no account required.
        </p>
        <div className="mt-2 flex flex-col items-center gap-4 sm:flex-row">
          <DownloadButton />
          <AppStoreLink />
        </div>
        <DownloadMeta />
      </div>
    </Section>
  )
}
