import { ImageResponse } from "next/og"
import { APP } from "@/lib/app"

export const alt = `${APP.name} — ${APP.tagline}`
export const size = { width: 1200, height: 630 }
export const contentType = "image/png"

export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          background: "linear-gradient(135deg, #0F0F1A 0%, #1A1A2E 100%)",
          padding: 72,
          position: "relative",
        }}
      >
        {/* Blueprint grid */}
        <div
          style={{
            position: "absolute",
            inset: 0,
            display: "flex",
            backgroundImage:
              "linear-gradient(to right, #ffffff0d 1px, transparent 1px), linear-gradient(to bottom, #ffffff0d 1px, transparent 1px)",
            backgroundSize: "72px 72px",
          }}
        />

        {/* Glyph */}
        <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
          {/* Satori has no reliable flex-wrap — lay the 2x2 out as two rows. */}
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              width: 76,
              height: 76,
              borderRadius: 18,
              border: "2px solid #1D9E75",
              padding: 10,
              gap: 6,
            }}
          >
            <div style={{ display: "flex", gap: 6 }}>
              <div style={{ width: 21, height: 21, borderRadius: 5, background: "#1D9E75" }} />
              <div style={{ width: 21, height: 21, borderRadius: 5, background: "#5DCAA5", opacity: 0.45 }} />
            </div>
            <div style={{ display: "flex", gap: 6 }}>
              <div style={{ width: 21, height: 21, borderRadius: 5, background: "#5DCAA5", opacity: 0.45 }} />
              <div style={{ width: 21, height: 21, borderRadius: 5, background: "#1D9E75" }} />
            </div>
          </div>
          <div style={{ display: "flex", fontSize: 34, fontWeight: 600, color: "#E1F5EE" }}>
            Mika
            <span style={{ color: "#1D9E75" }}>+</span>
            Grid
          </div>
        </div>

        {/* Headline */}
        <div style={{ display: "flex", flexDirection: "column" }}>
          <div
            style={{
              display: "flex",
              fontSize: 92,
              fontWeight: 700,
              letterSpacing: -3,
              color: "#E1F5EE",
              lineHeight: 1.05,
            }}
          >
            Snap. Organize.&nbsp;<span style={{ color: "#5DCAA5" }}>Focus.</span>
          </div>
          <div
            style={{
              display: "flex",
              marginTop: 24,
              fontSize: 30,
              color: "#9FE1CB",
              opacity: 0.75,
              maxWidth: 880,
            }}
          >
            A lightweight macOS window manager that lives in your menubar.
          </div>
        </div>

        {/* Footer badges */}
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          {[`v${APP.version}`, `macOS ${APP.minMacOS}+`, APP.arch, APP.license].map((t) => (
            <div
              key={t}
              style={{
                display: "flex",
                padding: "10px 22px",
                borderRadius: 999,
                border: "1px solid #ffffff26",
                background: "#ffffff0a",
                fontSize: 22,
                color: "#9FE1CB",
              }}
            >
              {t}
            </div>
          ))}
        </div>
      </div>
    ),
    size,
  )
}
