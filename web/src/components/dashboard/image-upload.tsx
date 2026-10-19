"use client";

import { useRef, useState } from "react";
import Image from "next/image";
import { ImagePlus, X } from "lucide-react";
import { uploadToCloudinary } from "@/lib/cloudinary";
import { Dots } from "@/components/ui/dots";
import { cn } from "@/lib/utils";

/**
 * Uploads photos straight from the agency's desktop to Cloudinary and exposes
 * the resulting delivery URLs to the form via hidden inputs:
 *   - `cover`   → the first photo (listing cover)
 *   - `gallery` → all photos, comma-separated (also feeds the 3D tour)
 */
export function ImageUpload() {
  const inputRef = useRef<HTMLInputElement>(null);
  const [urls, setUrls] = useState<string[]>([]);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleFiles(files: FileList | null) {
    if (!files || files.length === 0) return;
    setUploading(true);
    setError(null);
    const uploaded: string[] = [];

    for (const file of Array.from(files)) {
      try {
        uploaded.push(await uploadToCloudinary(file));
      } catch (e) {
        setError(e instanceof Error ? e.message : "Upload failed.");
      }
    }

    setUrls((prev) => [...prev, ...uploaded]);
    setUploading(false);
    if (inputRef.current) inputRef.current.value = "";
  }

  function removeAt(i: number) {
    setUrls((prev) => prev.filter((_, idx) => idx !== i));
  }

  return (
    <div className="flex flex-col gap-3">
      <input type="hidden" name="cover" value={urls[0] ?? ""} />
      <input type="hidden" name="gallery" value={urls.join(",")} />

      <div className="flex flex-wrap gap-3">
        {urls.map((url, i) => (
          <div
            key={url}
            className={cn(
              "relative h-24 w-24 overflow-hidden rounded-2xl bg-fill",
              i === 0 && "ring-2 ring-ink",
            )}
          >
            <Image
              src={url}
              alt={`Photo ${i + 1}`}
              fill
              sizes="96px"
              unoptimized
              className="object-cover"
            />
            <button
              type="button"
              onClick={() => removeAt(i)}
              className="absolute right-1 top-1 grid h-6 w-6 place-items-center rounded-full bg-black/55 text-white"
              aria-label="Remove photo"
            >
              <X className="h-3.5 w-3.5" />
            </button>
            {i === 0 && (
              <span className="absolute bottom-1 left-1 rounded-md bg-ink px-1.5 py-0.5 text-[10px] font-bold text-paper">
                Cover
              </span>
            )}
          </div>
        ))}

        <button
          type="button"
          onClick={() => inputRef.current?.click()}
          disabled={uploading}
          className="grid h-24 w-24 place-items-center rounded-2xl border border-dashed border-separator bg-card text-muted transition-colors hover:border-ink hover:text-ink"
        >
          {uploading ? (
            <Dots />
          ) : (
            <ImagePlus className="h-6 w-6" />
          )}
        </button>
      </div>

      <input
        ref={inputRef}
        type="file"
        accept="image/*"
        multiple
        hidden
        onChange={(e) => handleFiles(e.target.files)}
      />

      <p className="text-[13px] text-muted">
        Upload from your desktop — the first photo is the cover, all photos feed
        the 3D tour.
      </p>
      {error && <p className="text-sm text-danger">{error}</p>}
    </div>
  );
}
