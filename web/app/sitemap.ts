import type { MetadataRoute } from "next"
import { APP } from "@/lib/app"

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    {
      url: APP.siteUrl,
      changeFrequency: "monthly",
      priority: 1,
    },
  ]
}
