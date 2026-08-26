import { APP } from "@/lib/app"
import { Logo } from "@/components/ui/Logo"
import { DownloadButton } from "@/components/ui/DownloadButton"

const LINKS = [
  { href: "#features", label: "Features" },
  { href: "#shortcuts", label: "Shortcuts" },
  { href: "#install", label: "Install" },
  { href: "#editions", label: "Versions" },
  { href: "#faq", label: "FAQ" },
]

export function Nav() {
  return (
    <header className="fixed inset-x-0 top-0 z-50 border-b border-line bg-dark-bg-deep/80 backdrop-blur-xl">
      <nav className="mx-auto flex h-16 w-full max-w-6xl items-center justify-between px-6">
        <a href="#top" aria-label={`${APP.name} home`}>
          <Logo />
        </a>

        <ul className="hidden items-center gap-8 md:flex">
          {LINKS.map((l) => (
            <li key={l.href}>
              <a
                href={l.href}
                className="text-sm text-teal-lightest/60 transition-colors hover:text-teal-surface"
              >
                {l.label}
              </a>
            </li>
          ))}
        </ul>

        <div className="flex items-center gap-3">
          <a
            href={APP.repo}
            target="_blank"
            rel="noreferrer noopener"
            aria-label="View source on GitHub"
            className="hidden text-teal-lightest/60 transition-colors hover:text-teal-surface sm:block"
          >
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="currentColor" aria-hidden="true">
              <path d="M12 .3a12 12 0 0 0-3.8 23.4c.6.1.8-.3.8-.6v-2c-3.3.7-4-1.6-4-1.6-.6-1.4-1.4-1.8-1.4-1.8-1.1-.7.1-.7.1-.7 1.2.1 1.8 1.2 1.8 1.2 1.1 1.8 2.8 1.3 3.5 1 .1-.8.4-1.3.8-1.6-2.7-.3-5.5-1.3-5.5-5.9 0-1.3.5-2.4 1.2-3.2-.1-.3-.5-1.5.1-3.2 0 0 1-.3 3.3 1.2a11.5 11.5 0 0 1 6 0c2.3-1.5 3.3-1.2 3.3-1.2.6 1.7.2 2.9.1 3.2.8.8 1.2 1.9 1.2 3.2 0 4.6-2.8 5.6-5.5 5.9.4.4.8 1.1.8 2.2v3.3c0 .3.2.7.8.6A12 12 0 0 0 12 .3Z" />
            </svg>
          </a>
          <DownloadButton size="sm" />
        </div>
      </nav>
    </header>
  )
}
