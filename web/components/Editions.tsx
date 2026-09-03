import { APP } from "@/lib/app"
import { Section } from "@/components/ui/Section"

// Die Zeilen spiegeln den Abschnitt „Two versions" im README. Was hier steht, steht auch
// in AppStore/metadata/en-US/description.txt — ein Store-Eintrag, der etwas anderes sagt
// als die verlinkte Marketing-Seite, fällt bei der Prüfung auf.
const ROWS: { label: string; direct: string; store: string; note?: boolean }[] = [
  {
    label: "Requires",
    direct: `macOS ${APP.minMacOS} ${APP.minMacOSName}`,
    store: `macOS ${APP.minMacOSStore} ${APP.minMacOSStoreName}`,
  },
  {
    label: "Moves windows",
    direct: "itself, via the Accessibility API",
    store: "by asking Apple's Shortcuts app",
  },
  {
    label: "Permission",
    direct: "Accessibility",
    store: "Automation (control Shortcuts)",
  },
  {
    label: "Setup",
    direct: "grant permission",
    store: "grant permission + add one shortcut",
    note: true,
  },
  {
    label: "Snap actions",
    direct: "11",
    store: `${APP.storeSnapActions}`,
  },
  {
    label: "Restore previous position",
    direct: "yes",
    store: "no — Shortcuts does not report window frames",
    note: true,
  },
  {
    label: "Displays above or left of the main one",
    direct: "yes",
    store: "no — Move Window rejects negative coordinates",
    note: true,
  },
  { label: "Updates", direct: "Sparkle, in-app", store: "App Store" },
  { label: "Network access", direct: "signed update check", store: "none at all" },
  { label: "Price", direct: "free", store: "free" },
]

function Cell({ children, note }: { children: React.ReactNode; note?: boolean }) {
  return (
    <td
      className={`border-t border-line px-5 py-4 align-top text-sm leading-relaxed ${
        note ? "text-teal-lightest/60" : "text-teal-surface"
      }`}
    >
      {children}
    </td>
  )
}

export function Editions() {
  return (
    <Section
      id="editions"
      eyebrow="Versions"
      title="Two versions, one difference"
      lead="Both are the same app. They part ways at exactly one point: how a window gets moved."
      className="border-t border-line"
    >
      <div className="overflow-x-auto">
        <table className="w-full min-w-[40rem] border-collapse text-left">
          <thead>
            <tr>
              <th className="px-5 pb-4 text-xs font-medium tracking-[0.14em] text-teal-lightest/50 uppercase">
                {""}
              </th>
              <th className="px-5 pb-4 text-sm font-semibold text-teal-surface">
                Direct download
              </th>
              <th className="px-5 pb-4 text-sm font-semibold text-teal-surface">
                {APP.appStoreUrl ? (
                  <a
                    href={APP.appStoreUrl}
                    target="_blank"
                    rel="noreferrer noopener"
                    className="underline decoration-teal-primary/40 underline-offset-4 transition-colors hover:text-teal-primary"
                  >
                    Mac App Store
                  </a>
                ) : (
                  <>
                    Mac App Store
                    <span className="ml-2 rounded-full border border-teal-primary/40 px-2 py-0.5 align-middle text-[10px] font-normal tracking-wide text-teal-primary">
                      coming soon
                    </span>
                  </>
                )}
              </th>
            </tr>
          </thead>
          <tbody>
            {ROWS.map((r) => (
              <tr key={r.label}>
                <th className="border-t border-line px-5 py-4 align-top text-sm font-medium text-teal-lightest/70">
                  {r.label}
                </th>
                <Cell>{r.direct}</Cell>
                <Cell note={r.note}>{r.store}</Cell>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="mt-12 grid gap-6 sm:grid-cols-2">
        <div className="rounded-xl border border-line bg-elevated p-6">
          <h3 className="font-display text-lg font-semibold text-teal-surface">
            The companion shortcut
          </h3>
          <p className="mt-3 text-sm leading-relaxed text-teal-lightest/70">
            The App Store version ships a shortcut called{" "}
            <span className="text-teal-surface">“{APP.companionShortcutName}”</span> and the
            welcome flow adds it to your library in one click. The app checks that it is
            still intact before every snap, and runs nothing else. Removing the app leaves
            the shortcut behind — it is yours to delete.
          </p>
        </div>
        <div className="rounded-xl border border-line bg-elevated p-6">
          <h3 className="font-display text-lg font-semibold text-teal-surface">
            Why the detour
          </h3>
          <p className="mt-3 text-sm leading-relaxed text-teal-lightest/70">
            App Store apps run in a sandbox, and a sandbox has no access to the
            Accessibility API that moves windows. Sandboxing is mandatory for new
            submissions, so that version asks Apple’s Shortcuts app to do the moving
            instead — which is also why it makes no network request at all.
          </p>
        </div>
      </div>
    </Section>
  )
}
