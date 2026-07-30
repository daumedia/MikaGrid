// Mirrors Sources/SnapAction.swift — labels, default bindings and target geometry.
// Zone values are percentages of the screen's visible frame, matching
// SnapAction.targetFrame(on:currentFrame:).

export type Zone = { x: number; y: number; w: number; h: number }

export type SnapActionInfo = {
  id: string
  label: string
  keys: string[]
  /** Undefined for `restore`, which has no fixed target frame. */
  zone?: Zone
}

const CENTER_INSET = (100 - (100 * 2) / 3) / 2 // 16.666… — center (2/3) inset

export const SNAP_ACTIONS: SnapActionInfo[] = [
  { id: "leftHalf", label: "Left Half", keys: ["⌃", "⌥", "←"], zone: { x: 0, y: 0, w: 50, h: 100 } },
  { id: "rightHalf", label: "Right Half", keys: ["⌃", "⌥", "→"], zone: { x: 50, y: 0, w: 50, h: 100 } },
  { id: "topHalf", label: "Top Half", keys: ["⌃", "⌥", "↑"], zone: { x: 0, y: 0, w: 100, h: 50 } },
  { id: "bottomHalf", label: "Bottom Half", keys: ["⌃", "⌥", "↓"], zone: { x: 0, y: 50, w: 100, h: 50 } },
  { id: "topLeft", label: "Top Left", keys: ["⌃", "⌥", "U"], zone: { x: 0, y: 0, w: 50, h: 50 } },
  { id: "topRight", label: "Top Right", keys: ["⌃", "⌥", "I"], zone: { x: 50, y: 0, w: 50, h: 50 } },
  { id: "bottomLeft", label: "Bottom Left", keys: ["⌃", "⌥", "J"], zone: { x: 0, y: 50, w: 50, h: 50 } },
  { id: "bottomRight", label: "Bottom Right", keys: ["⌃", "⌥", "K"], zone: { x: 50, y: 50, w: 50, h: 50 } },
  { id: "maximize", label: "Maximize", keys: ["⌃", "⌥", "↩"], zone: { x: 0, y: 0, w: 100, h: 100 } },
  {
    id: "center",
    label: "Center",
    keys: ["⌃", "⌥", "C"],
    zone: { x: CENTER_INSET, y: CENTER_INSET, w: (100 * 2) / 3, h: (100 * 2) / 3 },
  },
  { id: "restore", label: "Restore", keys: ["⌃", "⌥", "⌫"] },
]

/** Where the demo window sits before anything is snapped. */
export const RESTING_ZONE: Zone = { x: 14, y: 18, w: 48, h: 52 }

/** Zones shown as the 3x3 + 2 button grid, in visual reading order. */
export const GRID_ORDER = [
  "topLeft",
  "topHalf",
  "topRight",
  "leftHalf",
  "maximize",
  "rightHalf",
  "bottomLeft",
  "bottomHalf",
  "bottomRight",
  "center",
  "restore",
] as const

export const byId = (id: string): SnapActionInfo | undefined =>
  SNAP_ACTIONS.find((a) => a.id === id)
