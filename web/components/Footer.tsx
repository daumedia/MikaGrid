import { APP } from "@/lib/app"
import { Logo } from "@/components/ui/Logo"

export function Footer() {
  return (
    <footer className="border-t border-line bg-dark-bg-deep px-6 py-14">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-8 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <Logo />
          <p className="mt-3 max-w-xs text-sm leading-relaxed text-teal-lightest/45">
            Part of the Mika+ ecosystem — small, native macOS tools built by{" "}
            <a
              href={APP.vendorUrl}
              target="_blank"
              rel="noreferrer noopener"
              className="text-teal-lightest/70 underline underline-offset-4 transition-colors hover:text-teal-light"
            >
              {APP.vendor}
            </a>
            .
          </p>
        </div>

        <nav className="flex flex-wrap items-center gap-x-7 gap-y-3 text-sm text-teal-lightest/60">
          <a href={APP.repo} target="_blank" rel="noreferrer noopener" className="transition-colors hover:text-teal-surface">
            GitHub
          </a>
          <a href={APP.releases} target="_blank" rel="noreferrer noopener" className="transition-colors hover:text-teal-surface">
            Releases
          </a>
          <a
            href={`${APP.repo}/issues`}
            target="_blank"
            rel="noreferrer noopener"
            className="transition-colors hover:text-teal-surface"
          >
            Report an issue
          </a>
          <a
            href={`${APP.repo}/blob/master/LICENSE`}
            target="_blank"
            rel="noreferrer noopener"
            className="transition-colors hover:text-teal-surface"
          >
            {APP.license} Licence
          </a>
        </nav>
      </div>

      <p className="mx-auto mt-10 w-full max-w-6xl font-mono text-xs text-teal-lightest/30">
        {APP.name} v{APP.version} · macOS {APP.minMacOS} ({APP.minMacOSName}) or
        later
      </p>
    </footer>
  )
}
