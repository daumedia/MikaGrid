import { APP } from "@/lib/app"
import { Section } from "@/components/ui/Section"

const FAQS: { q: string; a: React.ReactNode }[] = [
  {
    q: "Why does it need Accessibility permission?",
    a: (
      <>
        Moving another app&apos;s window is only possible through the macOS
        Accessibility API (<code className="font-mono text-teal-lightest/80">AXUIElement</code>).
        macOS gates that behind an explicit permission. Mika+Grid uses it purely
        to read and set window frames — nothing is recorded, stored, or sent
        anywhere.
      </>
    ),
  },
  {
    q: "macOS says the app is from an unidentified developer. What now?",
    a: (
      <>
        The current builds are ad-hoc signed and not notarised yet, so Gatekeeper
        blocks the first launch. Right-click the app in Applications, choose{" "}
        <strong className="text-teal-surface">Open</strong>, then confirm with{" "}
        <strong className="text-teal-surface">Open</strong> in the dialog.
        Alternatively go to System Settings → Privacy &amp; Security and click{" "}
        <strong className="text-teal-surface">Open Anyway</strong>. You only need
        to do this once.
      </>
    ),
  },
  {
    q: "Does it run on Intel Macs?",
    a: (
      <>
        The released build is {APP.arch} (arm64) only. Intel Macs would need a
        build from source — the project compiles with a plain{" "}
        <code className="font-mono text-teal-lightest/80">swift build</code>.
      </>
    ),
  },
  {
    q: "Can I change the keyboard shortcuts?",
    a: (
      <>
        Yes. Preferences → Shortcuts has an inline recorder for all eleven
        actions, flags conflicts as you record, and can restore the defaults at
        any time.
      </>
    ),
  },
  {
    q: "How do updates work?",
    a: (
      <>
        Mika+Grid uses Sparkle. It checks a signed appcast feed and verifies each
        download with an EdDSA signature before installing. Automatic checks can
        be switched off in Preferences → General.
      </>
    ),
  },
  {
    q: "What does it cost?",
    a: (
      <>
        Nothing. Mika+Grid is free and {APP.license}-licensed — the full source
        is on GitHub.
      </>
    ),
  },
]

export function Faq() {
  return (
    <Section
      id="faq"
      eyebrow="FAQ"
      title="Questions people actually ask"
      className="border-t border-line bg-dark-bg"
    >
      <div className="divide-y divide-line overflow-hidden rounded-2xl border border-line bg-dark-bg-deep">
        {FAQS.map((f) => (
          <details key={f.q} className="group px-6 py-5 [&_summary::-webkit-details-marker]:hidden">
            <summary className="flex cursor-pointer list-none items-center justify-between gap-6 text-left">
              <span className="font-display text-base font-medium tracking-tight text-teal-surface">
                {f.q}
              </span>
              <svg
                viewBox="0 0 24 24"
                aria-hidden="true"
                className="h-5 w-5 shrink-0 text-teal-primary transition-transform duration-200 group-open:rotate-45"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.8"
                strokeLinecap="round"
              >
                <path d="M12 5v14M5 12h14" />
              </svg>
            </summary>
            <div className="mt-3 max-w-2xl text-sm leading-relaxed text-teal-lightest/65">
              {f.a}
            </div>
          </details>
        ))}
      </div>
    </Section>
  )
}
