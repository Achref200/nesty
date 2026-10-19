import { NextResponse } from "next/server";
import crypto from "crypto";

/**
 * Signs a Cloudinary upload server-side so the API secret never reaches the
 * browser. The client then uploads directly to Cloudinary with the returned
 * signature — no unsigned preset required.
 */
export async function POST(req: Request) {
  const apiKey = process.env.CLOUDINARY_API_KEY;
  const apiSecret = process.env.CLOUDINARY_API_SECRET;
  const cloudName = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME;

  if (!apiKey || !apiSecret || !cloudName) {
    return NextResponse.json(
      { error: "Cloudinary is not configured on the server." },
      { status: 500 },
    );
  }

  const body = await req.json().catch(() => ({}));
  const folder =
    typeof body?.folder === "string" ? body.folder : "nesty/listings";
  const timestamp = Math.round(Date.now() / 1000);

  // Params to sign must be sorted alphabetically, joined, then hashed with the
  // secret appended (Cloudinary's signature scheme).
  const toSign = `folder=${folder}&timestamp=${timestamp}`;
  const signature = crypto
    .createHash("sha1")
    .update(toSign + apiSecret)
    .digest("hex");

  return NextResponse.json({ timestamp, signature, apiKey, cloudName, folder });
}
