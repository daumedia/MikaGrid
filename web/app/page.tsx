import { APP } from "@/lib/app"
import { Nav } from "@/components/Nav"
import { Hero } from "@/components/Hero"
import { Features } from "@/components/Features"
import { ShortcutList } from "@/components/Shortcuts"
import { HowItWorks } from "@/components/HowItWorks"
import { Trust } from "@/components/Trust"
import { Faq } from "@/components/Faq"
import { Footer } from "@/components/Footer"
import { Section } from "@/components/ui/Section"

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: APP.name,
  applicationCategory: "UtilitiesApplication",
  operatingSystem: `macOS ${APP.minMacOS}+`,
  softwareVersion: APP.version,
  description: APP.description,
  url: APP.siteUrl,
  downloadUrl: APP.dmgUrl,
  license: "https://opensource.org/licenses/MIT",
  author: { "@type": "Organization", name: APP.vendor, url: APP.vendorUrl },
  offers: { "@type": "Offer", price: "0", priceCurrency: "EUR" },
}

export default function Home() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <Nav />
      <main>
        <Hero />
        <Features />
        <Section
          id="shortcuts"
          eyebrow="Shortcuts"
          title="Eleven actions, all on ⌃⌥"
          lead="One modifier combo, muscle memory in an afternoon. Arrows for halves, U/I/J/K for quarters."
          className="border-t border-line bg-dark-bg-deep"
        >
          <ShortcutList />
        </Section>
        <HowItWorks />
        <Trust />
        <Faq />
      </main>
      <Footer />
    </>
  )
}
