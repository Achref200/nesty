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

app = FastAPI(title="Nesty Tour3D", version="1.0.0")


class GenerateRequest(BaseModel):
    listing_id: str = Field(..., description="Supabase listings.id")
    images: list[str] = Field(..., description="Room photo URLs or local paths")
    mode: Literal["kenburns", "photogrammetry"] = "kenburns"


class GenerateResponse(BaseModel):
    listing_id: str
    mode: str
    video_path: str
    frames: int


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/generate", response_model=GenerateResponse)
def generate(req: GenerateRequest) -> GenerateResponse:
    try:
        if req.mode == "photogrammetry":
            result = generate_photogrammetry(req.listing_id, req.images)
        else:
            result = generate_kenburns(req.listing_id, req.images)
    except NotImplementedError as exc:
        raise HTTPException(status_code=501, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
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
