import { APP } from "@/lib/app"
import { DownloadButton, DownloadMeta } from "@/components/ui/DownloadButton"
import { KbdCombo } from "@/components/ui/Kbd"
import { SnapGridDemo } from "@/components/SnapGridDemo"

export function Hero() {
  return (
    <section id="top" className="relative overflow-hidden pt-32 pb-20 sm:pt-40">
      <div className="glow-teal pointer-events-none absolute inset-x-0 top-0 h-[520px]" />
      <div className="grid-texture pointer-events-none absolute inset-0 [mask-image:radial-gradient(ellipse_70%_60%_at_50%_0%,black,transparent)]" />

      <div className="relative mx-auto w-full max-w-6xl px-6">
        <div className="mx-auto max-w-3xl text-center">
          <span className="inline-flex items-center gap-2 rounded-full border border-line-strong bg-elevated px-3.5 py-1.5 font-mono text-xs text-teal-lightest/70">
            <span className="h-1.5 w-1.5 rounded-full bg-teal-primary" />
            v{APP.version} · macOS {APP.minMacOS}+ · {APP.license}
          </span>

          <h1 className="mt-7 font-display text-5xl leading-[1.05] font-semibold tracking-tight text-teal-surface sm:text-6xl lg:text-7xl">
            Snap. Organize.{" "}
            <span className="bg-gradient-to-r from-teal-primary to-teal-light bg-clip-text text-transparent">
              Focus.
            </span>
          </h1>

          <p className="mx-auto mt-6 max-w-xl text-lg leading-relaxed text-teal-lightest/70">
            A lightweight macOS window manager that lives in your menubar. Snap
            any window to halves, quarters, or a centered layout — with a
            keystroke or a click.
          </p>

          <div className="mt-9 flex flex-col items-center justify-center gap-4 sm:flex-row">
            <DownloadButton />
            <a
              href={APP.repo}
              target="_blank"
              rel="noreferrer noopener"
              className="inline-flex h-13 items-center justify-center rounded-full border border-line-strong px-7 text-base font-medium text-teal-surface transition-colors hover:border-teal-primary/60 hover:bg-elevated"
            >
              View on GitHub
            </a>
          </div>

          <DownloadMeta className="mt-5" />

          <div className="mt-10 flex flex-wrap items-center justify-center gap-x-3 gap-y-2 text-sm text-teal-lightest/50">
            <span className="inline-flex items-center gap-3 whitespace-nowrap">
              Try it: <KbdCombo keys={["⌃", "⌥", "←"]} />
            </span>
            <span className="whitespace-nowrap">
              snaps the frontmost window left.
            </span>
          </div>
        </div>

        <div className="mt-20">
          <SnapGridDemo />
        </div>
      </div>
    </section>
  )
}
