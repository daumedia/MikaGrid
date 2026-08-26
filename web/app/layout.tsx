import type { Metadata, Viewport } from "next"
import { Inter, Inter_Tight, JetBrains_Mono } from "next/font/google"
import { APP } from "@/lib/app"
import "./globals.css"

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
})

const interTight = Inter_Tight({
  subsets: ["latin"],
  variable: "--font-inter-tight",
  display: "swap",
})

const jetbrainsMono = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-jetbrains-mono",
  display: "swap",
})

export const metadata: Metadata = {
  metadataBase: new URL(APP.siteUrl),
  title: {
    default: `${APP.name} — macOS Window Manager for the Menubar`,
    template: `%s · ${APP.name}`,
  },
  description: APP.description,
  applicationName: APP.name,
  keywords: [
    "macOS window manager",
    "window snapping",
    "menubar app",
    "Rectangle alternative",
    "Mac App Store",
    "keyboard shortcuts",
    "Apple Silicon",
    "Mika+",
  ],
  authors: [{ name: APP.vendor, url: APP.vendorUrl }],
  creator: APP.vendor,
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    url: APP.siteUrl,
    siteName: APP.name,
    title: `${APP.name} — ${APP.tagline}`,
    description: APP.description,
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title: `${APP.name} — ${APP.tagline}`,
    description: APP.description,
  },
}

export const viewport: Viewport = {
  themeColor: "#0F0F1A",
  colorScheme: "dark",
}

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html
      lang="en"
      className={`${inter.variable} ${interTight.variable} ${jetbrainsMono.variable}`}
    >
      <body className="font-sans antialiased">{children}</body>
    </html>
  )
}
