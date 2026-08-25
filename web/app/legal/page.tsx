import type { Metadata } from "next"
import { APP } from "@/lib/app"
import { Nav } from "@/components/Nav"
import { Footer } from "@/components/Footer"
import { LegalPage, LegalSection } from "@/components/LegalPage"

export const metadata: Metadata = {
  title: "Legal Notice",
  description: `Provider information for ${APP.name}.`,
  alternates: { canonical: "/legal" },
}

export default function Legal() {
  return (
    <>
      <Nav />
      <main>
        <LegalPage
          title="Legal Notice"
          lead="Provider information under the Luxembourg Act of 14 August 2000 on electronic commerce."
          updated="25 August 2026"
        >
          <LegalSection title="Provider">
            <p>
              {APP.vendor}
              <br />
              Luxembourg
              <br />
              <a
                href={APP.vendorUrl}
                target="_blank"
                rel="noreferrer noopener"
                className="text-teal-light underline underline-offset-4"
              >
                {APP.vendorUrl.replace("https://", "")}
              </a>
            </p>
          </LegalSection>

          <LegalSection title="Contact">
            <p>
              For questions about {APP.name}, please open an issue on{" "}
              <a
                href={`${APP.repo}/issues`}
                target="_blank"
                rel="noreferrer noopener"
                className="text-teal-light underline underline-offset-4"
              >
                GitHub
              </a>
              . For anything else, use the contact details on{" "}
              <a
                href={APP.vendorUrl}
                target="_blank"
                rel="noreferrer noopener"
                className="text-teal-light underline underline-offset-4"
              >
                {APP.vendorUrl.replace("https://", "")}
              </a>
              .
            </p>
          </LegalSection>

          <LegalSection title="Licence and liability">
            <p>
              {APP.name} is free software under the{" "}
              <a
                href={APP.licenseUrl}
                target="_blank"
                rel="noreferrer noopener"
                className="text-teal-light underline underline-offset-4"
              >
                MIT licence
              </a>
              . It is provided &ldquo;as is&rdquo;, without warranty of any kind, as
              set out in the licence text.
            </p>
            <p>
              This site links to external websites. We have no influence over their
              content and accept no responsibility for it; responsibility rests with
              their respective operators.
            </p>
          </LegalSection>

          <LegalSection title="Privacy">
            <p>
              See the{" "}
              <a href="/privacy" className="text-teal-light underline underline-offset-4">
                privacy page
              </a>
              . Short version: the app collects nothing, and the site has no cookies
              and no analytics.
            </p>
          </LegalSection>
        </LegalPage>
      </main>
      <Footer />
    </>
  )
}
