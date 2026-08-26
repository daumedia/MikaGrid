import { APP } from "@/lib/app"

const FACTS = [
  { value: `${APP.dmgSizeMB} MB`, label: "Download size" },
  { value: "0", label: "Trackers or analytics" },
  { value: "Native", label: "Swift 6 + SwiftUI" },
  { value: APP.license, label: "Open source licence" },
]

export function Trust() {
  return (
    <section className="border-t border-line bg-dark-bg-deep px-6 py-20">
      <div className="mx-auto w-full max-w-6xl">
        <div className="grid gap-px overflow-hidden rounded-2xl border border-line bg-line sm:grid-cols-2 lg:grid-cols-4">
          {FACTS.map((f) => (
            <div key={f.label} className="bg-dark-bg-deep px-7 py-8">
              <p className="font-display text-3xl font-semibold tracking-tight text-teal-light">
                {f.value}
              </p>
              <p className="mt-1.5 text-sm text-teal-lightest/50">{f.label}</p>
            </div>
          ))}
        </div>
        <p className="mx-auto mt-8 max-w-2xl text-center text-sm leading-relaxed text-teal-lightest/50">
          Mika+Grid has no Dock icon and no login. The direct download makes no
          network request beyond the signed update check; the App Store version
          makes none at all. Window positions never leave your Mac.
        </p>
      </div>
    </section>
  )
}
