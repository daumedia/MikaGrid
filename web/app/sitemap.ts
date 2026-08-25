import type { MetadataRoute } from "next"
import { APP } from "@/lib/app"

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: APP.siteUrl, changeFrequency: "monthly", priority: 1 },
    { url: `${APP.siteUrl}/privacy`, changeFrequency: "yearly", priority: 0.3 },
    { url: `${APP.siteUrl}/legal`, changeFrequency: "yearly", priority: 0.3 },
  ]
}
