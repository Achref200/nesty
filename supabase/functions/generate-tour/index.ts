// Supabase Edge Function: generate-tour
// ---------------------------------------------------------------------------
// Auto-generates a listing's 3D walkthrough. Call it after a listing is created
// (from a DB webhook or the dashboard). It fetches the listing's photos, asks
// the Tour3D service (services/tour3d) to render the walkthrough, then stores
// the resulting URL on listings.tour_3d_url so the mobile app plays it.
//
// Deploy:
//   supabase functions deploy generate-tour
// Secrets (supabase secrets set ...):
//   TOUR3D_URL       = https://<your-tour3d-service>       (FastAPI base URL)
//   SERVICE_ROLE_KEY = <supabase service role key>          (server-side only)
//
// Invoke:
//   POST { "listing_id": "<uuid>", "mode": "kenburns" | "tripo" | "kling" }
// ---------------------------------------------------------------------------

import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY =
  Deno.env.get("SERVICE_ROLE_KEY") ??
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const TOUR3D_URL = Deno.env.get("TOUR3D_URL") ?? "http://localhost:8000";

Deno.serve(async (req) => {
  try {
    const { listing_id, mode = "kenburns" } = await req.json();
    if (!listing_id) {
      return json({ error: "listing_id is required" }, 400);
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    // Gather the photos that feed the reconstruction: gallery + every room.
    const { data: listing, error } = await supabase
      .from("listings")
      .select("id, gallery, rooms")
      .eq("id", listing_id)
      .maybeSingle();
    if (error || !listing) {
      return json({ error: error?.message ?? "Listing not found" }, 404);
    }

    const roomImages = Array.isArray(listing.rooms)
      ? (listing.rooms as Array<{ images?: string[] }>).flatMap(
          (r) => r.images ?? [],
        )
      : [];
    const images = [...(listing.gallery ?? []), ...roomImages];
    if (images.length === 0) {
      return json({ error: "No photos to build a tour from" }, 422);
    }

    // Ask the Tour3D service to render the walkthrough / mesh / clip.
    const genRes = await fetch(`${TOUR3D_URL}/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ listing_id, images, mode }),
    });
    if (!genRes.ok) {
      return json({ error: `Tour3D failed: ${await genRes.text()}` }, 502);
    }
    const gen = await genRes.json();

    // Route the result to the right column: tripo yields an explorable GLB
    // mesh (model_3d_url); everything else yields a video (tour_3d_url).
    let update: Record<string, string>;
    if (mode === "tripo" && gen.model_url) {
      update = { model_3d_url: gen.model_url };
    } else {
      update = {
        tour_3d_url: gen.public_url ?? gen.video_url ?? gen.video_path,
      };
    }
    const { error: updErr } = await supabase
      .from("listings")
      .update(update)
      .eq("id", listing_id);
    if (updErr) return json({ error: updErr.message }, 500);

    return json({ listing_id, mode, ...update });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
