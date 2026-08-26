import type { Metadata } from "next"
import { APP } from "@/lib/app"
import { Nav } from "@/components/Nav"
import { Footer } from "@/components/Footer"
import { LegalPage, LegalSection } from "@/components/LegalPage"

export const metadata: Metadata = {
  title: "Privacy",
  description: `How ${APP.name} handles data — it doesn't collect any.`,
  alternates: { canonical: "/privacy" },
}

export default function Privacy() {
  return (
    <>
      <Nav />
      <main>
        <LegalPage
          title="Privacy"
          lead={`${APP.name} does not collect personal data. There is no account, no server, no database and no telemetry. This page explains what that means in detail — and names the one connection the app does make.`}
          updated="25 August 2026"
        >
          <LegalSection title="What the app stores">
            <p>
              Everything stays on your Mac, in a single preferences file
              (<code>~/Library/Preferences/lu.daumedia.mikagrid.plist</code>):
              whether you have completed onboarding, whether you skipped the
              permission step, and your keyboard shortcuts. That is all. No
              Application Support folder, no keychain entry, no log file.
            </p>
          </LegalSection>

          <LegalSection title="What the app reads but never stores">
            <p>
              With Accessibility permission granted, {APP.name} reads the{" "}
              <strong className="text-teal-surface">position, size and window number</strong> of
              the frontmost window and sets its position and size. Nothing else —
              no window contents, no text you type, no keystrokes in other apps.
            </p>
            <p>
              Window <em>titles</em> are not read at all. Until version 1.1.1 the
              undo history was keyed by
              process ID and window title, which meant titles — a document name, a
              website you visited — sat in memory. The key is now the system&apos;s
              window number: a plain integer that says nothing about you. The
              history itself lives in memory only, is capped at 100 entries and is
              gone when the app quits.
            </p>
            <p>
              The <strong className="text-teal-surface">App Store version works
              differently</strong>. It does not move windows itself — it asks
              Apple&apos;s Shortcuts app to do it, and passes the action and the
              target frame: five numbers and a random value, nothing else. No
              application name, no window title. The information never leaves your
              Mac: the recipient is a system app on the same machine, no network
              request is made and nothing is stored.
            </p>
          </LegalSection>

          <LegalSection title="Permissions">
            <p>
              <strong className="text-teal-surface">Accessibility</strong> is required to move and
              resize other apps&apos; windows — it is the only macOS interface that
              allows this. Without it the app runs and its interface works, but it
              cannot arrange windows, and it tells you so when you try.
            </p>
            <p>
              {APP.name} does <strong className="text-teal-surface">not</strong> request Input
              Monitoring. Global shortcuts go through Carbon&apos;s{" "}
              <code>RegisterEventHotKey</code>, which reports only the eleven
              combinations the app registered. Keystroke logging is technically
              impossible here, not merely something we choose not to do.
            </p>
          </LegalSection>

          <LegalSection title="The one network connection">
            <p>
              Once a day, Sparkle checks a signed update feed hosted on GitHub. In
              doing so GitHub, Inc. (USA) sees your IP address, the time of the
              request and Sparkle&apos;s user agent — the same information any
              request for a public file produces. Legal basis: Art. 6(1)(f) GDPR,
              our legitimate interest in delivering security and bug fixes.
            </p>
            <p>
              Sparkle&apos;s system profiling is <strong className="text-teal-surface">off</strong>.
              No hardware or system details are transmitted. You can switch automatic
              checks off entirely in Preferences → General; after that the app makes
              no network requests at all until you press &ldquo;Check Now&rdquo;.
            </p>
            <p>
              There are no other recipients. No analytics, no crash reporting, no
              advertising identifiers.
            </p>
          </LegalSection>

          <LegalSection title="This website">
            <p>
              The site is static and hosted by Vercel Inc. It sets no cookies, writes
              nothing to local storage and contains no analytics. Fonts are bundled at
              build time, so your browser never contacts Google Fonts.
            </p>
            <p>
              Vercel processes server access logs containing IP address, timestamp and
              user agent, on the basis of Art. 6(1)(f) GDPR (technically sound delivery
              of the site).
            </p>
          </LegalSection>

          <LegalSection title="Your rights">
            <p>
              Access, rectification, erasure, restriction, objection and portability
              under Art. 15–21 GDPR apply — but there is nothing to exercise them
              against, because no personal data is processed. To remove every trace of
              the app:
            </p>
            <pre className="overflow-x-auto rounded-xl border border-line bg-dark-bg-deep p-4 font-mono text-xs text-teal-lightest/70">
{`rm -rf /Applications/Mika+Grid.app
defaults delete lu.daumedia.mikagrid`}
            </pre>
            <p>
              Then remove the entry under System Settings → Privacy &amp; Security →
              Accessibility, and under General → Login Items if you enabled it. No
              application is allowed to delete those for you.
            </p>
          </LegalSection>

          <LegalSection title="Controller">
            <p>
              {APP.vendor}, Luxembourg —{" "}
              <a href="/legal" className="text-teal-light underline underline-offset-4">
                full details in the legal notice
              </a>
              .
            </p>
          </LegalSection>
        </LegalPage>
      </main>
      <Footer />
    </>
  )
}
