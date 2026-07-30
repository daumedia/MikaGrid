export function Section({
  id,
  eyebrow,
  title,
  lead,
  children,
  className = "",
}: {
  id?: string
  eyebrow?: string
  title?: string
  lead?: string
  children: React.ReactNode
  className?: string
}) {
  return (
    <section id={id} className={`px-6 py-24 sm:py-28 ${className}`}>
      <div className="mx-auto w-full max-w-6xl">
        {(eyebrow || title || lead) && (
          <div className="mb-14 max-w-2xl">
            {eyebrow && (
              <p className="mb-3 font-mono text-xs tracking-[0.2em] text-teal-primary uppercase">
                {eyebrow}
              </p>
            )}
            {title && (
              <h2 className="font-display text-3xl font-semibold tracking-tight text-teal-surface sm:text-4xl">
                {title}
              </h2>
            )}
            {lead && (
              <p className="mt-4 text-lg leading-relaxed text-teal-lightest/70">
                {lead}
              </p>
            )}
          </div>
        )}
        {children}
      </div>
    </section>
  )
}
