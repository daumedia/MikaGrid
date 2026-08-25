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
    q: "macOS warns me when I open it. What now?",
    a: (
      <>
        Builds are signed with a Developer ID but are not notarised yet, so
        Gatekeeper asks for confirmation on first launch. Right-click the app in
        Applications, choose{" "}
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
        Releases ship as a universal binary covering Apple Silicon and Intel. If
        you prefer to build it yourself, a plain{" "}
        <code className="font-mono text-teal-lightest/80">swift build</code> works
        on either architecture.
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
    q: "What data does it collect?",
    a: (
      <>
        None. There is no account, no server and no telemetry — the app stores a
        handful of settings on your Mac and talks to GitHub once a day to look for
        updates. Details are on the{" "}
        <a href="/privacy" className="text-teal-light underline underline-offset-4">
          privacy page
        </a>
        .
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
