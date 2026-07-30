import type { MetadataRoute } from "next"
import { APP } from "@/lib/app"

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: "*", allow: "/" },
    sitemap: `${APP.siteUrl}/sitemap.xml`,
  }
}
