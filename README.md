# Nesty - Tunisian PropTech

A trust-first housing platform for Tunisia, with Flutter apps for web and mobile.

- **Flutter app** (`/`): renters discover homes, book visits, and reserve stays; agencies publish listings and manage requests.
- **Next.js website** (`/website`): marketing site and agency dashboard.
- **Backend**: Supabase (Postgres, Auth, RLS, and Realtime). Migrations are in `supabase/migrations`.
- **Image hosting**: Cloudinary.
- **Tour3D service** (`services/tour3d`): turns room photos into a walkthrough video.

## Run the Flutter app on the web

```bash
flutter pub get
flutter run -d chrome
flutter build web --release
```

## Run the Next.js website

```bash
cd website
npm install
cp .env.example .env.local
npm run dev
```

Required website environment variables are listed in `website/.env.example`.

## Database

Apply the SQL migrations in `supabase/migrations` in filename order using the
Supabase SQL editor.

## Deploy the Flutter app to Vercel

The root `vercel.json` builds the Flutter web app with Flutter 3.47.2 and serves
the generated static files from `build/release_web`. Pushes to `main` trigger a
production deployment.

## Deploy the Next.js website separately

Create a separate Vercel project for this repository and set its Root Directory
to `website`. Add the environment variables from `website/.env.example` before
deploying.
