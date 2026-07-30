"use client"

import { useState } from "react"
import { SNAP_ACTIONS, type Zone } from "@/lib/snapActions"
import { KbdCombo } from "@/components/ui/Kbd"
import { MonitorFrame } from "@/components/ui/MonitorFrame"

export function ShortcutList() {
  const [hovered, setHovered] = useState<string | null>(null)
  const active = SNAP_ACTIONS.find((a) => a.id === hovered)
  const previewZone: Zone | undefined = active
    ? active.zone
    : SNAP_ACTIONS[0].zone

  return (
    <div className="grid gap-10 lg:grid-cols-[1fr_20rem] lg:gap-16">
      <ul className="divide-y divide-line overflow-hidden rounded-2xl border border-line bg-dark-bg">
        {SNAP_ACTIONS.map((a) => (
          <li key={a.id}>
            {/* Hover-only: the preview repeats what the row already states, so
                it stays out of the tab order rather than adding empty stops. */}
            <div
              onMouseEnter={() => setHovered(a.id)}
              onMouseLeave={() => setHovered(null)}
              className={`flex items-center justify-between gap-4 px-5 py-3.5 transition-colors ${
                hovered === a.id ? "bg-teal-primary/10" : ""
              }`}
            >
              <span className="text-sm font-medium text-teal-surface">
                {a.label}
              </span>
              <KbdCombo keys={a.keys} />
            </div>
          </li>
        ))}
      </ul>

      <div className="mx-auto w-full max-w-sm lg:sticky lg:top-28 lg:max-w-none lg:self-start">
        <div aria-hidden="true">
          <MonitorFrame zone={previewZone} />
        </div>
        <p aria-hidden="true" className="mt-4 text-sm leading-relaxed text-teal-lightest/60">
          {active
            ? active.zone
              ? `${active.label} — the window fills the highlighted area of the screen.`
              : "Restore — puts the window back where it was before the last snap."
            : `Showing ${SNAP_ACTIONS[0].label}. Hover any shortcut to preview where the window lands.`}
        </p>
        <p className="mt-4 text-xs text-teal-lightest/40">
          All shortcuts are reconfigurable in Preferences → Shortcuts, with
          conflict detection built in.
        </p>
      </div>
    </div>
  )
}
