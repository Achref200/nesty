/** Cloudinary uploads for the web dashboard. */
export const CLOUDINARY_CLOUD_NAME =
  process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME ?? "";
export const CLOUDINARY_UPLOAD_PRESET =
  process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET ?? "";

/**
 * Uploads a file to Cloudinary and returns its secure delivery URL.
 *
 * Prefers a **signed** upload: it asks our server (`/api/cloudinary-sign`) for a
 * signature so the API secret never touches the browser and no preset is
 * needed. Falls back to an unsigned preset if signing isn't available.
 */
export async function uploadToCloudinary(file: File): Promise<string> {
  const folder = "nesty/listings";

  // 1) Try a server-signed upload.
  try {
    const signRes = await fetch("/api/cloudinary-sign", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ folder }),
    });
    if (signRes.ok) {
      const sign = await signRes.json();
      const form = new FormData();
      form.append("file", file);
      form.append("api_key", sign.apiKey);
      form.append("timestamp", String(sign.timestamp));
      form.append("signature", sign.signature);
      form.append("folder", sign.folder);
      return await postToCloudinary(sign.cloudName, form);
    }
  } catch {
    // fall through to unsigned
  }

  // 2) Fall back to an unsigned preset.
  if (!CLOUDINARY_CLOUD_NAME || !CLOUDINARY_UPLOAD_PRESET) {
    throw new Error(
      "Cloudinary isn't configured — add the server API key/secret, or an unsigned preset.",
    );
  }
  const form = new FormData();
  form.append("file", file);
  form.append("upload_preset", CLOUDINARY_UPLOAD_PRESET);
  form.append("folder", folder);
  return postToCloudinary(CLOUDINARY_CLOUD_NAME, form);
}

async function postToCloudinary(
  cloudName: string,
  form: FormData,
): Promise<string> {
  const res = await fetch(
    `https://api.cloudinary.com/v1_1/${cloudName}/image/upload`,
    { method: "POST", body: form },
  );
  const data = await res.json().catch(() => null);
  if (!res.ok || !data?.secure_url) {
    throw new Error(data?.error?.message ?? `Upload failed (${res.status})`);
  }
  return data.secure_url as string;
}
