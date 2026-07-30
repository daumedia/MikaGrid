import { APP } from "@/lib/app"

export function DownloadButton({
  size = "lg",
  className = "",
}: {
  size?: "sm" | "lg"
  className?: string
}) {
  const sizing =
    size === "lg"
      ? "h-13 px-7 text-base gap-2.5"
      : "h-9 px-4 text-sm gap-2"

  return (
    <a
      href={APP.dmgUrl}
      className={`group inline-flex items-center justify-center rounded-full bg-teal-primary font-medium text-white transition-colors duration-200 hover:bg-teal-light hover:text-dark-bg-deep ${sizing} ${className}`}
    >
      <svg
        viewBox="0 0 24 24"
        aria-hidden="true"
        className={size === "lg" ? "h-5 w-5" : "h-4 w-4"}
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M12 3v12" />
        <path d="m7 11 5 5 5-5" />
        <path d="M4 20h16" />
      </svg>
      {size === "lg" ? "Download for macOS" : "Download"}
    </a>
  )
}

export function DownloadMeta({ className = "" }: { className?: string }) {
  return (
    <p className={`font-mono text-xs text-teal-lightest/50 ${className}`}>
      v{APP.version} · .dmg · {APP.dmgSizeMB} MB · macOS {APP.minMacOS}+ ·{" "}
      {APP.arch}
    </p>
  )
}
