export function LegalPage({
  title,
  lead,
  updated,
  children,
}: {
  title: string
  lead: string
  updated: string
  children: React.ReactNode
}) {
  return (
    <section className="px-6 pt-32 pb-20 sm:pt-40">
      <div className="mx-auto w-full max-w-3xl">
        <h1 className="font-display text-4xl font-semibold tracking-tight text-teal-surface sm:text-5xl">
          {title}
        </h1>
        <p className="mt-5 text-lg leading-relaxed text-teal-lightest/70">{lead}</p>
        <p className="mt-3 font-mono text-xs text-teal-lightest/40">
          Last updated: {updated}
        </p>
        <div className="mt-12 space-y-10">{children}</div>
      </div>
    </section>
  )
}

export function LegalSection({
  title,
  children,
}: {
  title: string
  children: React.ReactNode
}) {
  return (
    <section>
      <h2 className="font-display text-xl font-medium tracking-tight text-teal-surface">
        {title}
      </h2>
      <div className="mt-3 space-y-3 text-sm leading-relaxed text-teal-lightest/65 [&_code]:rounded [&_code]:bg-elevated [&_code]:px-1.5 [&_code]:py-0.5 [&_code]:font-mono [&_code]:text-xs [&_code]:text-teal-lightest/80">
        {children}
      </div>
    </section>
  )
}
