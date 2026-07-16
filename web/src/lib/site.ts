/**
 * Single source of truth for site-wide SEO metadata. Keep the canonical URL in
 * one place so sitemap, robots, OpenGraph and JSON-LD all stay consistent.
 */
export const site = {
  name: "Nesty",
  title: "Nesty — Tour before you visit",
  description:
    "Nesty is Tunisia's PropTech for renting with confidence. Tour every home in immersive 3D, book a visit or reserve your summer dates, and let agencies track everything on one calm calendar.",
  url: "https://nesty.tn",
  locale: "en_TN",
  tagline: "Tour before you visit.",
  keywords: [
    "Nesty",
    "PropTech Tunisia",
    "location Tunisie",
    "real estate Tunisia",
    "3D property tour",
    "book a visit",
    "summer rental Tunisia",
    "colocation",
    "immobilier Tunisie",
  ],
  nav: [
    { href: "/#why", label: "Why Nesty" },
    { href: "/#how", label: "How it works" },
    { href: "/#who", label: "Who it's for" },
    { href: "/#contact", label: "Contact" },
  ],
} as const;

export type SiteConfig = typeof site;
