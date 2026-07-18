# Nesty — Tour3D generation service

Python service that turns a listing's **room photos** into an immersive tour the
mobile app plays. It is the backend half of the "import photos → tour" promise:
an agency uploads photos, we transform them here, and the app lets a seeker
**pre-walk the unit virtually** before ever visiting.

The **headline mechanic** (and the one to start with) is a connected **360°
virtual walk** built from the photos alone — no GPU, no API keys. See
[`virtual_tour.py`](#photos--360-virtual-walk-the-headline) below. The other
modes layer "even more real" mesh/video on top.

## Photos → 360° virtual walk (the headline)

`virtual_tour.py` groups a home's photos into rooms and wires the **doorways**
between them, producing the exact `listings.rooms` shape the app reads. The app
then lets you stand in each room, look around, and walk room-to-room through the
doors — choosing your direction, like an indoor Street View built from photos.

```bash
cd services/tour3d
python virtual_tour.py example                       # writes the worked example
python virtual_tour.py build my_house/ --base-url https://cdn/...   # your photos
python virtual_tour.py walkthrough my_house/         # first-person MP4 (reel-style)
```

Folder layout (one sub-folder per room; order = walk order; a file named
`*360*`/`*pano*` becomes that room's look-around panorama):

```
my_house/
  1 Salon/            2 Salle a manger/   3 Cuisine/
  4 Couloir/          5 Chambre/          6 Salle d'eau/
```

A complete, ready-to-read example lives at
[`examples/nesty_demo_house/tour.json`](examples/nesty_demo_house/tour.json)
(7 rooms, many photos, fully connected — the same home the app ships in demo
mode). Over HTTP, `POST /tour` does the same from a JSON body and `GET
/tour/example` returns that example. **Django:** call `build_manifest(...)` /
`manifest_from_rooms(...)` from a management command or DRF view — both return a
plain dict.

## Coherent single-house builder (same house, linked, walkable)

A walkthrough only feels real if every photo is the **same home**.
[`build_house.py`](build_house.py) assembles a coherent single-house listing —
all rooms from one house, classified, connected by doorways, and emitted as the
walkable `listings.rooms` manifest (+ optional Supabase SQL). Two sources:

```bash
# 1) A real house from Wikimedia Commons (free-licensed, same building):
python build_house.py commons --category "Interior of Fallingwater" --out house.json
python build_house.py commons --category "Interior of Fallingwater" \
    --sql --listing-id <uuid> > house.sql        # drop it into a listing

# 2) Imagine a coherent home from scratch with an image model (one style):
export OPENAI_API_KEY=sk-…
python build_house.py generate --style "sunlit modern Tunisian apartment" \
    --rooms "Salon,Salle a manger,Cuisine,Couloir,Chambre,Salle d'eau" --out house.json
```

It classifies each photo into a room, drops exterior/plan/logo shots, wires the
doorway graph (hallway = hub), and can attach real depth (see below) so each
room is a navigable 3D space. The demo migration
`supabase/migrations/20260718160000_coherent_house_demo.sql` was produced this
way — run it to see a coherent, connected same-house walk in the app.

## Photo → real 3D (depth & point cloud)

The app already makes a flat room photo navigable on-device (it estimates depth
and renders parallax so you can "surf" the space). [`depth.py`](depth.py) is the
**accuracy upgrade**: it runs a neural depth model (MiDaS) on a photo and

* writes a real **depth map** (PNG), and
* reprojects the photo into a colored **3D point cloud** (`.ply`) — every pixel
  lifted into space, i.e. "all the points of the room turned into a 3D space".

```bash
pip install torch torchvision timm            # heavy, optional (CPU ok)
python depth.py room.jpg --depth depth.png --ply room.ply
```

Run it per room photo to build the whole home as point clouds, then view/merge
them or feed them onward to meshing / **Gaussian splatting** for a fully
photoreal walk (the "gaussian splats?" people ask about). Without these deps the
app simply keeps using its on-device depth estimate — nothing breaks.

## Other modes (grow into "even more real")

It ships with **four generation modes** too, so you can grow into real 3D:

1. **`kenburns` (default, runs anywhere)** — stitches the photos into a smooth
   pan/zoom "walkthrough" MP4. No GPU, no heavy deps beyond Pillow + a video
   encoder. Great for the MVP and for testing the full pipeline end-to-end.
2. **`tripo` (real 3D mesh)** — turns a photo into an actual explorable **GLB
   model** via [Tripo3D](https://www.tripo3d.ai/). This is what feeds the in-app
   3D model viewer + AR. Needs `TRIPO_API_KEY`.
3. **`kling` (cinematic video)** — turns a photo into a short lifelike
   fly-through **video** via Kling (hosted on fal.ai). Needs `KLING_API_KEY`.
4. **`photogrammetry` (opt-in, heavy)** — reconstructs a full 3D model from many
   overlapping photos using COLMAP / Gaussian Splatting, then renders an orbit
   video. Documented below; wire it in when you have a GPU box.

## Modes at a glance

| Mode             | Input            | Output            | Explorable? | Keys needed      | Writes to           |
| ---------------- | ---------------- | ----------------- | ----------- | ---------------- | ------------------- |
| `kenburns`       | a few room pics  | MP4 walkthrough   | no (video)  | none             | `listings.tour_3d_url` |
| `tripo`          | 1 photo          | GLB **3D mesh**   | **yes**     | `TRIPO_API_KEY`  | `listings.model_3d_url` |
| `kling`          | 1 photo          | MP4 fly-through   | no (video)  | `KLING_API_KEY`  | `listings.tour_3d_url` |
| `photogrammetry` | 20–60 photos/room | orbit MP4 / splat | partial     | GPU + COLMAP     | `listings.tour_3d_url` |

### What about Kling AI? (honest answer)

Kling is **image-to-video**: it animates a still into a short (~5–10s) clip with
cinematic camera motion and parallax. It is *not* a 3D model — you can't walk
around it or view it from a new angle it wasn't shown. It's perfect for a
lifelike **hero clip** of a home, and we support it (`mode: "kling"`).

For the "walk the home, choose your direction" experience the app is built
around, you want an actual **3D mesh** or a **navigable set of 360° panoramas**:

- **One photo → explorable mesh:** Tripo (`mode: "tripo"`), Meshy, Hunyuan3D, or
  TRELLIS → a `.glb` the app orbits + drops into AR.
- **Whole home → walkable scene:** photogrammetry (COLMAP) or Gaussian Splatting
  from many overlapping photos.

The app already delivers the walkable experience today **with zero keys** via the
dollhouse + 360° room panoramas with doorway navigation; `tripo` and `kling`
layer "even more real" mesh/video on top when you add keys.

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

## Environment (for the cloud modes)

```bash
# Real image-to-3D mesh (mode=tripo):
export TRIPO_API_KEY=tsk_xxx           # from https://platform.tripo3d.ai/
# Real image-to-video (mode=kling), via fal.ai's hosted Kling:
export KLING_API_KEY=fal_xxx           # or FAL_KEY; from https://fal.ai/
# Optional overrides: TRIPO_BASE, KLING_MODEL, KLING_PROVIDER (default 'fal'),
# KLING_PROMPT, GEN_TIMEOUT.
```

Without these keys the `tripo`/`kling` endpoints return a clear 502 and the app
simply keeps using its sample GLB + ken-burns tour — nothing breaks.

## Wiring into Nesty (recommended flow)

1. Agency publishes a listing (web/mobile) with room photos.
2. A Supabase Edge Function / cron calls `POST /generate` with the photo URLs.
3. Service renders the output (MP4 for `kenburns`/`kling`, GLB for `tripo`).
4. Service updates the listing:
   - `tripo`  → `UPDATE listings SET model_3d_url = <glb_url> WHERE id = …`
   - others → `UPDATE listings SET tour_3d_url = <public_url> WHERE id = …`
5. App plays it — no client changes needed (`model3dUrl` / `tour3dUrl` light up).

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
