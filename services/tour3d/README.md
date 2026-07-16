# Nesty — Tour3D generation service

A small Python service that turns a listing's **room photos** into an immersive
walkthrough the mobile app can play as its 3D tour. It is the backend half of
the "import photos → tour" promise: the agency uploads photos on web/mobile, we
generate the tour here, and the app plays it from `listings.tour_3d_url`.

It ships with **two levels** so you can demo today and grow into real 3D:

1. **`kenburns` (default, runs anywhere)** — stitches the photos into a smooth
   pan/zoom "walkthrough" MP4. No GPU, no heavy deps beyond Pillow + a video
   encoder. Great for the MVP and for testing the full pipeline end-to-end.
2. **`photogrammetry` (opt-in, heavy)** — reconstructs an actual 3D model from
   overlapping photos using COLMAP / (optionally) Gaussian Splatting, then
   renders an orbit video. Documented below; wire it in when you have a GPU box.

## Why this shape

- Django or FastAPI both work; this reference uses **FastAPI** because it is
  lighter for a single generation endpoint. Drop it behind Django REST just as
  easily — the pipeline in `pipeline.py` is framework-agnostic.
- The app already renders local + remote images and a `Room360Viewer`, so a
  generated MP4 is the smallest thing that upgrades the experience for real.

## Run it

```bash
cd services/tour3d
python -m venv .venv && . .venv/Scripts/activate   # PowerShell: .venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app:app --reload --port 8000
```

`ffmpeg` must be on PATH (imageio-ffmpeg bundles a build, so this usually works
out of the box).

## Use it

```bash
curl -X POST http://localhost:8000/generate \
  -H "Content-Type: application/json" \
  -d '{
        "listing_id": "11111111-1111-1111-1111-111111111101",
        "mode": "kenburns",
        "images": [
          "https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=1200&q=80",
          "https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=1200&q=80",
          "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=1200&q=80"
        ]
      }'
```

Response:

```json
{ "listing_id": "…", "mode": "kenburns", "video_path": "out/<listing>.mp4" }
```

Then upload `video_path` to Supabase Storage (bucket `tours`) and set
`listings.tour_3d_url` to its public URL. The mobile `Property.tour3dUrl` /
`has3dTour` already light up the tour when that is present.

## Wiring into Nesty (recommended flow)

1. Agency publishes a listing (web/mobile) with room photos.
2. A Supabase Edge Function / cron calls `POST /generate` with the photo URLs.
3. Service renders the MP4, uploads to Supabase Storage.
4. Service `UPDATE listings SET tour_3d_url = <public_url> WHERE id = …`.
5. App plays it — no client changes needed.

## Growing into true 3D (photogrammetry)

`mode: "photogrammetry"` is stubbed in `pipeline.py`. The production path:

- **COLMAP** for Structure-from-Motion + Multi-View Stereo → sparse/dense cloud.
  Needs 20–60 overlapping photos per room and a GPU.
- Optionally **Gaussian Splatting** (`gaussian-splatting`, `nerfstudio`) for a
  photoreal, orbitable scene, exported as a video or a `.splat`/`.ply` the app
  renders in a WebGL/three.js view.
- Render an orbit fly-through with the same encoder used by `kenburns`.

Keep the **API contract identical** so the app never has to change as the
quality of the tour improves.
