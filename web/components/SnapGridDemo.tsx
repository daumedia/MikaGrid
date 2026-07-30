"use client"

import { useCallback, useEffect, useRef, useState } from "react"
import {
  GRID_ORDER,
  RESTING_ZONE,
  byId,
  type SnapActionInfo,
  type Zone,
} from "@/lib/snapActions"

const AUTOPLAY: string[] = [
  "leftHalf",
  "topRight",
  "maximize",
  "center",
  "restore",
]

const AUTOPLAY_INTERVAL_MS = 1800

function ZoneIcon({ action }: { action: SnapActionInfo }) {
  if (!action.zone) {
    return (
      <svg
        viewBox="0 0 24 24"
        aria-hidden="true"
        className="h-4 w-4"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M3 7v6h6" />
        <path d="M3.5 13a9 9 0 1 0 2.3-6.4L3 9" />
      </svg>
    )
  }

  return (
    <span className="relative block h-4 w-[22px] rounded-[3px] border border-current opacity-90">
      <span
        className="absolute rounded-[1px] bg-current"
        style={{
          left: `${action.zone.x}%`,
          top: `${action.zone.y}%`,
          width: `${action.zone.w}%`,
          height: `${action.zone.h}%`,
        }}
      />
    </span>
  )
}

export function SnapGridDemo() {
  const [zone, setZone] = useState<Zone>(RESTING_ZONE)
  const [activeId, setActiveId] = useState<string | null>(null)
  const [autoplay, setAutoplay] = useState(false)
  const stepRef = useRef(0)

  // Only start the loop for users who haven't asked for reduced motion.
  useEffect(() => {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)")
    if (!mq.matches) setAutoplay(true)
  }, [])

  useEffect(() => {
    if (!autoplay) return
    const id = window.setInterval(() => {
      const nextId = AUTOPLAY[stepRef.current % AUTOPLAY.length]
      stepRef.current += 1
      const action = byId(nextId)
      setActiveId(nextId)
      setZone(action?.zone ?? RESTING_ZONE)
    }, AUTOPLAY_INTERVAL_MS)
    return () => window.clearInterval(id)
  }, [autoplay])

  const apply = useCallback((action: SnapActionInfo) => {
    setAutoplay(false) // hand control over on first interaction
    setActiveId(action.id)
    setZone(action.zone ?? RESTING_ZONE)
  }, [])

  return (
    <div className="grid items-center gap-10 lg:grid-cols-[1.35fr_1fr] lg:gap-14">
      {/* Screen */}
      <div className="rounded-2xl border border-line bg-elevated p-3 shadow-[0_40px_120px_-40px_#000]">
        <div className="grid-texture relative aspect-[16/10] w-full overflow-hidden rounded-xl bg-dark-bg-deep">
          {/* Menubar */}
          <div className="absolute inset-x-0 top-0 z-10 flex h-6 items-center justify-end gap-2 border-b border-line bg-dark-bg/80 px-3 backdrop-blur-sm">
            <svg viewBox="0 0 16 16" aria-hidden="true" className="h-3 w-3">
              <rect
                x="0.75"
                y="0.75"
                width="14.5"
                height="14.5"
                rx="3"
                fill="none"
                stroke="#5DCAA5"
                strokeWidth="1.2"
              />
              <rect x="3" y="3" width="4.5" height="4.5" rx="1" fill="#1D9E75" />
              <rect x="8.5" y="8.5" width="4.5" height="4.5" rx="1" fill="#1D9E75" />
            </svg>
            <span className="font-mono text-[9px] text-teal-lightest/50">
              14:32
            </span>
          </div>

          {/* Visible frame — everything below the menubar, like screen.visibleFrame */}
          <div className="absolute inset-x-0 bottom-0 top-6">
            <div
              className="absolute p-[3px] transition-all duration-[220ms] ease-out"
              style={{
                left: `${zone.x}%`,
                top: `${zone.y}%`,
                width: `${zone.w}%`,
                height: `${zone.h}%`,
              }}
            >
              <div className="flex h-full w-full flex-col overflow-hidden rounded-lg border border-line-strong bg-dark-bg shadow-2xl">
                <div className="flex h-6 shrink-0 items-center gap-1.5 border-b border-line px-2.5">
                  <span className="h-2 w-2 rounded-full bg-[#E24B4A]" />
                  <span className="h-2 w-2 rounded-full bg-[#E0A44B]" />
                  <span className="h-2 w-2 rounded-full bg-[#5DCAA5]" />
                </div>
                <div className="flex flex-1 flex-col justify-center gap-2 overflow-hidden p-3">
                  <span className="h-1.5 w-3/5 rounded-full bg-teal-primary/50" />
                  <span className="h-1.5 w-4/5 rounded-full bg-white/10" />
                  <span className="h-1.5 w-2/5 rounded-full bg-white/10" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Popover-style zone picker — kept compact below lg so the buttons
          don't balloon when the grid spans the full column width. */}
      <div className="mx-auto w-full max-w-sm rounded-2xl border border-line bg-elevated p-5 backdrop-blur-sm lg:max-w-none">
        <p className="mb-4 font-mono text-[11px] tracking-[0.18em] text-teal-lightest/50 uppercase">
          Snap a zone
        </p>
        <div
          className="grid grid-cols-3 gap-2"
          role="group"
          aria-label="Snap zones"
        >
          {GRID_ORDER.map((id) => {
            const action = byId(id)
            if (!action) return null
            const isActive = activeId === action.id
            return (
              <button
                key={action.id}
                type="button"
                onClick={() => apply(action)}
                aria-pressed={isActive}
                className={`flex aspect-[4/3] cursor-pointer flex-col items-center justify-center gap-2 rounded-xl border p-2 transition-colors duration-150 ${
                  isActive
                    ? "border-teal-primary bg-teal-primary/20 text-teal-light"
                    : "border-line bg-white/[0.02] text-teal-lightest/60 hover:border-teal-primary/50 hover:bg-teal-primary/10 hover:text-teal-light"
                }`}
              >
                <ZoneIcon action={action} />
                <span className="text-center text-[10px] leading-tight font-medium">
                  {action.label}
                </span>
              </button>
            )
          })}
        </div>
        <p className="mt-4 text-xs leading-relaxed text-teal-lightest/50">
          The real popover looks like this — every zone also has a global
          shortcut.
        </p>
      </div>
    </div>
  )
}
