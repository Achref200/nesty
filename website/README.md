# Nesty — Web (landing + agency dashboard)

The marketing site and the agency-facing dashboard for **Nesty**, built with
**Next.js (App Router) + TypeScript + Tailwind** and a small, hand-rolled
shadcn-style component layer. It shares the mobile app's strict black / white /
grey identity (Outfit + Plus Jakarta Sans).

## Getting started

```bash
cd web
npm install
npm run dev      # http://localhost:3000
```

## Scripts

- `npm run dev` — local dev server
- `npm run build` — production build
- `npm run start` — serve the production build
- `npm run lint` — Next.js lint
- `npm run typecheck` — TypeScript, no emit

## Architecture

```
src/
  app/
    layout.tsx              # fonts + global SEO metadata
    page.tsx                # landing page (+ JSON-LD structured data)
    globals.css             # design tokens + base styles
    sitemap.ts / robots.ts / manifest.ts   # SEO routes
    api/waitlist/route.ts   # waitlist capture endpoint
    dashboard/
      layout.tsx            # sidebar + topbar shell (noindex)
      page.tsx              # overview: stats + next up + portfolio
      listings/page.tsx     # portfolio with Available/Reserved state
      calendar/page.tsx     # month calendar + day agenda
      requests/page.tsx     # filterable request queue with actions
  components/
    ui/                     # Button, Card, Badge, Input, Separator (shadcn-style)
    brand/logo.tsx          # house mark + wordmark
    landing/                # nav, hero, sections, waitlist, footer, motion
    dashboard/              # sidebar, topbar, stat card, reservation/listing items, calendar
  data/                     # types + demo dataset (swap for Supabase/Postgres)
  lib/                      # cn(), formatters, site/SEO config
```

## SEO

- Per-route Metadata API (title template, OpenGraph, Twitter, canonical).
- `sitemap.xml`, `robots.txt`, and a web manifest as first-class routes.
- JSON-LD (`Organization` + `WebSite` + `SoftwareApplication`) on the landing page.
- Landing content is server-rendered; only motion is client-side, so crawlers
  see the full copy. The dashboard is `noindex`.

## Going live

- **Waitlist:** replace the marked block in `src/app/api/waitlist/route.ts`
  with a real store (Supabase table, Postgres, or Resend/Mailchimp).
- **Data:** swap `src/data/mock.ts` for a real client behind the same types in
  `src/data/types.ts` — the UI won't change.
- Set the canonical URL in `src/lib/site.ts`.
