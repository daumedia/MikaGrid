/**
 * Wordmark + glyph. The glyph echoes the app icon: concentric rounded
 * rectangles with a crosshair and a plus badge.
 */
export function LogoGlyph({ className = "h-8 w-8" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 32 32"
      aria-hidden="true"
      className={className}
      fill="none"
    >
      <rect
        x="1.25"
        y="1.25"
        width="29.5"
        height="29.5"
        rx="7.5"
        fill="#0F0F1A"
        stroke="#1D9E75"
        strokeWidth="1.5"
      />
      <rect x="6" y="6" width="8.5" height="8.5" rx="1.75" fill="#1D9E75" />
      <rect
        x="17.5"
        y="6"
        width="8.5"
        height="8.5"
        rx="1.75"
        fill="#5DCAA5"
        opacity="0.45"
      />
      <rect
        x="6"
        y="17.5"
        width="8.5"
        height="8.5"
        rx="1.75"
        fill="#5DCAA5"
        opacity="0.45"
      />
      <rect x="17.5" y="17.5" width="8.5" height="8.5" rx="1.75" fill="#1D9E75" />
    </svg>
  )
}

export function Logo({ className = "" }: { className?: string }) {
  return (
    <span className={`inline-flex items-center gap-2.5 ${className}`}>
      <LogoGlyph className="h-7 w-7" />
      <span className="font-display text-[17px] font-semibold tracking-tight text-teal-surface">
        Mika<span className="text-teal-primary">+</span>Grid
      </span>
    </span>
  )
}
