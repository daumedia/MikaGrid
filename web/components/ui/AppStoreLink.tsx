import { APP } from "@/lib/app"

// Der Link erscheint nur, wenn `APP.appStoreUrl` gesetzt ist. Vor der Freigabe stand dort
// ein leerer String — ein toter Store-Link ist schlimmer als kein Link.
export function AppStoreLink({
  size = "lg",
  className = "",
}: {
  size?: "sm" | "lg"
  className?: string
}) {
  if (!APP.appStoreUrl) return null

  const sizing =
    size === "lg" ? "h-13 px-7 text-base gap-2.5" : "h-9 px-4 text-sm gap-2"

  return (
    <a
      href={APP.appStoreUrl}
      target="_blank"
      rel="noreferrer noopener"
      className={`inline-flex items-center justify-center rounded-full border border-line-strong font-medium text-teal-surface transition-colors hover:border-teal-primary/60 hover:bg-elevated ${sizing} ${className}`}
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
        <rect x="3" y="3" width="18" height="18" rx="5" />
        <path d="M9.5 15.5 14 8.5" />
        <path d="M14.5 15.5 10 8.5" />
        <path d="M8 15.5h8" />
      </svg>
      Mac App Store
    </a>
  )
}
