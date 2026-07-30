export function Kbd({ children }: { children: React.ReactNode }) {
  return (
    <kbd className="inline-flex h-7 min-w-7 items-center justify-center rounded-md border border-line-strong bg-elevated px-2 font-mono text-[13px] leading-none text-teal-lightest shadow-[inset_0_-1px_0_#00000040]">
      {children}
    </kbd>
  )
}

export function KbdCombo({ keys }: { keys: readonly string[] }) {
  return (
    <span className="inline-flex items-center gap-1">
      {keys.map((k, i) => (
        <Kbd key={i}>{k}</Kbd>
      ))}
    </span>
  )
}
