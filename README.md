# Nesty — Tunisian PropTech

A trust‑ and 3D‑first housing platform for Tunisia.

- **Mobile app** (`/` — Flutter): seekers browse homes, tour them in 3D, book a
  visit or reserve; agencies (hosts) publish listings and track engagement.
- **Web dashboard** (`/web` — Next.js): the agency (B2B) portal — listings,
  reservations, calendar and analytics.
- **Backend**: Supabase (Postgres + Auth + RLS + Realtime). Migrations in
  `/supabase/migrations`.
- **Image hosting**: Cloudinary.
- **Tour3D service** (`/services/tour3d` — FastAPI): turns room photos into a
  walkthrough video.

## Run the web dashboard

```bash
cd web
npm install
cp .env.example .env.local   # then fill in the values
npm run dev                  # http://localhost:3000
```

Required env vars are listed in `web/.env.example` (Supabase + Cloudinary).

## Run the mobile app

```bash
flutter pub get
flutter run
```

## Database

Apply the SQL migrations in `/supabase/migrations` in filename order using the
Supabase SQL editor (init → location → analytics → rental_term_and_seed →
demo_prototype_seed → storage → notifications).

## Deploy the website (Vercel)

1. Push this repo to GitHub.
2. On https://vercel.com → New Project → import the repo.
3. Set **Root Directory** to `web`.
4. Add the environment variables from `web/.env.example` (keep
   `CLOUDINARY_API_SECRET` without the `NEXT_PUBLIC_` prefix so it stays
   server‑only).
5. Deploy — Vercel gives a public URL viewable from any PC or phone and
   auto‑deploys on every push to `main`.

> The Flutter app is not a website — distribute it as an APK / TestFlight build;
> only the `/web` dashboard is web‑hosted.
