"""FastAPI entrypoint for the Nesty Tour3D service.

    uvicorn app:app --reload --port 8000

POST /generate turns a listing's room photos into a walkthrough MP4.
See README.md for how it plugs into Supabase Storage + listings.tour_3d_url.
"""

from __future__ import annotations

from typing import Literal

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field

from pipeline import generate_kenburns, generate_photogrammetry
from models3d import generate_kling, generate_tripo
from virtual_tour import example_manifest, manifest_from_rooms

app = FastAPI(title="Nesty Tour3D", version="1.1.0")


class GenerateRequest(BaseModel):
    listing_id: str = Field(..., description="Supabase listings.id")
    images: list[str] = Field(..., description="Room photo URLs or local paths")
    mode: Literal["kenburns", "photogrammetry", "tripo", "kling"] = "kenburns"


class GenerateResponse(BaseModel):
    listing_id: str
    mode: str
    # Exactly one of these is populated depending on the mode:
    video_path: str | None = None  # local MP4 (kenburns/photogrammetry)
    video_url: str | None = None   # remote MP4 (kling)
    model_url: str | None = None   # remote GLB mesh (tripo)
    frames: int | None = None


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


class TourRoom(BaseModel):
    name: str
    type: str | None = None
    images: list[str] = Field(default_factory=list)
    panorama_url: str | None = None


class TourRequest(BaseModel):
    listing_id: str = "house"
    rooms: list[TourRoom]


@app.post("/tour")
def tour(req: TourRequest) -> dict:
    """Turn a listing's rooms + photos into a walkable 360° tour manifest.

    Returns the exact shape the app stores in ``listings.rooms`` (rooms with
    images, optional panorama, and doorway links), so a seeker can pre-walk the
    unit virtually. No GPU or API keys required.
    """
    rooms = [r.model_dump() for r in req.rooms]
    if not rooms:
        raise HTTPException(status_code=400, detail="rooms is required")
    return manifest_from_rooms(rooms, req.listing_id)


@app.get("/tour/example")
def tour_example() -> dict:
    """The full worked one-house example, matching the app's demo home."""
    return example_manifest()


@app.post("/generate", response_model=GenerateResponse)
def generate(req: GenerateRequest) -> GenerateResponse:
    try:
        if req.mode == "tripo":
            mesh = generate_tripo(req.listing_id, req.images)
            return GenerateResponse(
                listing_id=mesh.listing_id, mode=mesh.mode, model_url=mesh.model_url
            )
        if req.mode == "kling":
            clip = generate_kling(req.listing_id, req.images)
            return GenerateResponse(
                listing_id=clip.listing_id, mode=clip.mode, video_url=clip.video_url
            )
        if req.mode == "photogrammetry":
            result = generate_photogrammetry(req.listing_id, req.images)
        else:
            result = generate_kenburns(req.listing_id, req.images)
    except NotImplementedError as exc:
        raise HTTPException(status_code=501, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except (RuntimeError, TimeoutError) as exc:
        # Missing API key, provider error, or a poll timeout.
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    except Exception as exc:  # pragma: no cover - surfaced to the caller
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    return GenerateResponse(
        listing_id=result.listing_id,
        mode=result.mode,
        video_path=result.video_path,
        frames=result.frames,
    )


@app.get("/preview/{listing_id}")
def preview(listing_id: str) -> FileResponse:
    """Convenience: stream a just-generated tour for local testing."""
    import os

    path = os.path.join(os.environ.get("TOUR3D_OUT", "out"), f"{listing_id}.mp4")
    if not os.path.exists(path):
        raise HTTPException(status_code=404, detail="No tour generated yet.")
    return FileResponse(path, media_type="video/mp4")
