import type { Zone } from "@/lib/snapActions"

/**
 * A miniature monitor with an optional highlighted zone — the same visual
 * language as the app's popover grid (SnapZoneButton.swift).
 */
export function MonitorFrame({
  zone,
  className = "",
  animated = true,
}: {
  zone?: Zone
  className?: string
  animated?: boolean
}) {
  return (
    <div
      className={`relative aspect-[16/10] w-full rounded-lg border border-line-strong bg-dark-bg-deep p-1 ${className}`}
    >
      <div className="grid-texture relative h-full w-full overflow-hidden rounded-md bg-dark-bg">
        {zone ? (
          <div
            className={`absolute rounded-[3px] border border-teal-light/70 bg-teal-primary/45 ${
              animated ? "transition-all duration-200 ease-out" : ""
            }`}
            style={{
              left: `${zone.x}%`,
              top: `${zone.y}%`,
              width: `${zone.w}%`,
              height: `${zone.h}%`,
            }}
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center">
            <svg
              viewBox="0 0 24 24"
              aria-hidden="true"
              className="h-1/3 w-1/3 text-teal-light/70"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M3 7v6h6" />
              <path d="M3.5 13a9 9 0 1 0 2.3-6.4L3 9" />
            </svg>
          </div>
        )}
      </div>
    </div>
  )
}
