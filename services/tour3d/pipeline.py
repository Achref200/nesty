"""Photo -> walkthrough pipeline for Nesty listings.

Framework-agnostic so it can sit behind FastAPI (see app.py) or Django REST.
The default `kenburns` mode turns a listing's room photos into a smooth
pan/zoom walkthrough MP4 with cross-fades — a real, GPU-free tour for the MVP.
`photogrammetry` is documented and stubbed for the GPU-backed future.
"""

from __future__ import annotations

import io
import os
from dataclasses import dataclass

import imageio.v2 as imageio
import numpy as np
import requests
from PIL import Image

OUT_DIR = os.environ.get("TOUR3D_OUT", "out")

# Output tuning — 1280x720 @ 30fps reads well on phones without huge files.
_W, _H = 1280, 720
_FPS = 30
_SECONDS_PER_IMAGE = 3.0
_CROSSFADE = 0.6


@dataclass
class GenerateResult:
    listing_id: str
    mode: str
    video_path: str
    frames: int


def _load_image(src: str) -> Image.Image:
    """Load an image from a URL or a local path, normalized to RGB + cover crop."""
    if src.startswith("http://") or src.startswith("https://"):
        resp = requests.get(src, timeout=20)
        resp.raise_for_status()
        img = Image.open(io.BytesIO(resp.content))
    else:
        img = Image.open(src)
    img = img.convert("RGB")
    return _cover(img, _W, _H)


def _cover(img: Image.Image, w: int, h: int) -> Image.Image:
    """Scale + center-crop so the image fills w x h (like CSS object-fit: cover)."""
    src_ratio = img.width / img.height
    dst_ratio = w / h
    if src_ratio > dst_ratio:
        new_h = h
        new_w = round(h * src_ratio)
    else:
        new_w = w
        new_h = round(w / src_ratio)
    img = img.resize((new_w, new_h), Image.LANCZOS)
    left = (new_w - w) // 2
    top = (new_h - h) // 2
    return img.crop((left, top, left + w, top + h))


def _ken_burns_frames(img: Image.Image, seconds: float):
    """Yield frames slowly zooming/panning across `img` — the 'walk' feeling."""
    total = max(1, int(seconds * _FPS))
    base = np.asarray(img, dtype=np.uint8)
    for i in range(total):
        t = i / max(1, total - 1)
        zoom = 1.08 - 0.08 * t  # ease from slightly zoomed-in to full frame
        crop_w, crop_h = int(_W / zoom), int(_H / zoom)
        max_x, max_y = _W - crop_w, _H - crop_h
        x = int(max_x * t)          # gentle left -> right pan
        y = int(max_y * (0.5))      # hold vertical center
        frame = base[y : y + crop_h, x : x + crop_w]
        yield np.asarray(
            Image.fromarray(frame).resize((_W, _H), Image.LANCZOS)
        )


def _blend(a: np.ndarray, b: np.ndarray, alpha: float) -> np.ndarray:
    return (a.astype(np.float32) * (1 - alpha) + b.astype(np.float32) * alpha).astype(
        np.uint8
    )


def generate_kenburns(listing_id: str, images: list[str]) -> GenerateResult:
    if not images:
        raise ValueError("At least one image is required.")
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, f"{listing_id}.mp4")

    loaded = [_load_image(src) for src in images]
    writer = imageio.get_writer(path, fps=_FPS, codec="libx264", quality=7)
    count = 0
    prev_tail: np.ndarray | None = None
    fade_n = int(_CROSSFADE * _FPS)

    try:
        for img in loaded:
            frames = list(_ken_burns_frames(img, _SECONDS_PER_IMAGE))
            if prev_tail is not None and fade_n > 0:
                for k in range(fade_n):
                    writer.append_data(
                        _blend(prev_tail, frames[k], k / max(1, fade_n - 1))
                    )
                    count += 1
                frames = frames[fade_n:]
            for f in frames:
                writer.append_data(f)
                count += 1
            prev_tail = frames[-1] if frames else prev_tail
    finally:
        writer.close()

    return GenerateResult(listing_id, "kenburns", path, count)


def generate_photogrammetry(listing_id: str, images: list[str]) -> GenerateResult:
    """Real 3D reconstruction — requires COLMAP (+ optionally Gaussian Splatting).

    Outline of the production pipeline:
      1. Download images to a working dir.
      2. `colmap automatic_reconstructor` -> sparse + dense point cloud / mesh.
      3. (optional) train Gaussian Splatting / NeRF for a photoreal scene.
      4. Render an orbit fly-through to MP4 with the same encoder as kenburns.
    Kept as a clearly-marked stub so the API contract is stable today.
    """
    raise NotImplementedError(
        "photogrammetry mode needs COLMAP/Gaussian-Splatting on a GPU host — "
        "see README. Use mode='kenburns' for the MVP."
    )
