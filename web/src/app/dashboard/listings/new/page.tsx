"use client";

import { useState } from "react";
import { useFormState, useFormStatus } from "react-dom";
import dynamic from "next/dynamic";
import Link from "next/link";
import { ArrowLeft, AlertCircle, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { Dots } from "@/components/ui/dots";
import { createListing, type CreateListingState } from "@/lib/actions/listings";
import { ImageUpload } from "@/components/dashboard/image-upload";
import { cn } from "@/lib/utils";

// Leaflet needs the browser, so load the picker client-side only.
const LocationPicker = dynamic(
  () =>
    import("@/components/dashboard/location-picker").then(
      (m) => m.LocationPicker,
    ),
  {
    ssr: false,
    loading: () => (
      <div className="h-64 w-full animate-pulse rounded-2xl bg-fill" />
    ),
  },
);

const TYPES = [
  { key: "entirePlace", label: "Entire place" },
  { key: "privateRoom", label: "Private room" },
  { key: "sharedRoom", label: "Colocation" },
];

const TERMS = [
  { key: "longTerm", label: "Long term", blurb: "Students & families" },
  { key: "shortTerm", label: "Short term", blurb: "Summer & vacation" },
];

const AUDIENCE = [
  { key: "adults", label: "Adults" },
  { key: "children", label: "Children" },
  { key: "baby", label: "Baby" },
  { key: "pets", label: "Pets" },
];

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="flex flex-col gap-1.5">
      <span className="text-[13px] font-bold uppercase tracking-wide text-muted">
        {label}
      </span>
      {children}
    </label>
  );
}

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <Button type="submit" size="lg" disabled={pending}>
      {pending ? (
        <span className="inline-flex items-center gap-2">
          Publishing <Dots />
        </span>
      ) : (
        "Publish listing"
      )}
    </Button>
  );
}

export default function NewListingPage() {
  const [type, setType] = useState("entirePlace");
  const [term, setTerm] = useState("longTerm");
  const [audience, setAudience] = useState<string[]>([]);
  const [state, formAction] = useFormState<CreateListingState, FormData>(
    createListing,
    {},
  );

  const toggleAudience = (key: string) =>
    setAudience((prev) =>
      prev.includes(key) ? prev.filter((a) => a !== key) : [...prev, key],
    );

  return (
    <div className="mx-auto max-w-2xl">
      <Link
        href="/dashboard/listings"
        className="mb-6 inline-flex items-center gap-2 text-sm font-semibold text-muted hover:text-ink"
      >
        <ArrowLeft className="h-4 w-4" /> Back to listings
      </Link>

      <div className="mb-6 rounded-3xl border border-separator bg-card/70 p-6 glass-panel">
        <span className="inline-flex items-center gap-1.5 rounded-full bg-fill px-3 py-1 text-xs font-bold uppercase tracking-wide text-muted">
          <Sparkles className="h-3.5 w-3.5" /> New listing
        </span>
        <h1 className="mt-3 font-display text-3xl font-extrabold tracking-tight">
          Publish a place
        </h1>
        <p className="mt-1.5 max-w-lg text-[15px] text-muted">
          Add photos, price and location. It goes live in the Nesty app for
          seekers to tour in 3D, then book a visit or reserve.
        </p>
      </div>

      <form action={formAction} className="mt-6">
        <input type="hidden" name="type" value={type} />
        <input type="hidden" name="rentalTerm" value={term} />
        <input type="hidden" name="audience" value={audience.join(",")} />
        <Card className="flex flex-col gap-5">
          <Field label="Title">
            <Input name="title" placeholder="Bright T3 near Lac 2" required />
          </Field>
          <Field label="City / area">
            <Input name="city" placeholder="Tunis, Les Berges du Lac" required />
          </Field>
          <Field label="Address (optional)">
            <Input name="address" placeholder="Rue du Lac Turkana, Lac 2" />
          </Field>

          <Field label="Type">
            <div className="grid grid-cols-3 gap-2">
              {TYPES.map((t) => (
                <button
                  key={t.key}
                  type="button"
                  onClick={() => setType(t.key)}
                  className={cn(
                    "rounded-xl py-2.5 text-sm font-bold transition-colors",
                    type === t.key
                      ? "bg-ink text-paper"
                      : "bg-fill text-ink hover:bg-separator",
                  )}
                >
                  {t.label}
                </button>
              ))}
            </div>
          </Field>

          <Field label="Rental term">
            <div className="grid grid-cols-2 gap-2">
              {TERMS.map((t) => (
                <button
                  key={t.key}
                  type="button"
                  onClick={() => setTerm(t.key)}
                  className={cn(
                    "flex flex-col items-start rounded-xl px-3 py-2.5 text-left transition-colors",
                    term === t.key
                      ? "bg-ink text-paper"
                      : "bg-fill text-ink hover:bg-separator",
                  )}
                >
                  <span className="text-sm font-bold">{t.label}</span>
                  <span
                    className={cn(
                      "text-[11px]",
                      term === t.key ? "text-paper/80" : "text-muted",
                    )}
                  >
                    {t.blurb}
                  </span>
                </button>
              ))}
            </div>
          </Field>

          <Field label="Suitable for">
            <div className="flex flex-wrap gap-2">
              {AUDIENCE.map((a) => (
                <button
                  key={a.key}
                  type="button"
                  onClick={() => toggleAudience(a.key)}
                  className={cn(
                    "rounded-full px-3.5 py-1.5 text-sm font-semibold transition-colors",
                    audience.includes(a.key)
                      ? "bg-ink text-paper"
                      : "bg-fill text-ink hover:bg-separator",
                  )}
                >
                  {a.label}
                </button>
              ))}
            </div>
          </Field>

          <div className="grid grid-cols-2 gap-4">
            <Field label="Price / month (DT)">
              <Input name="price" type="number" min="0" placeholder="1900" />
            </Field>
            <Field label="Area (m²)">
              <Input name="area" type="number" min="0" placeholder="68" />
            </Field>
            <Field label="Bedrooms">
              <Input name="bedrooms" type="number" min="0" placeholder="2" />
            </Field>
            <Field label="Bathrooms">
              <Input name="bathrooms" type="number" min="0" placeholder="1" />
            </Field>
          </div>

          <Field label="Photos">
            <ImageUpload />
          </Field>

          <Field label="Exact location (tap the map)">
            <LocationPicker />
          </Field>
          <Field label="Description (optional)">
            <textarea
              name="description"
              rows={4}
              placeholder="What makes this place feel like home…"
              className="w-full rounded-xl border border-separator bg-card p-4 text-base text-ink outline-none transition-colors placeholder:text-muted-soft focus:border-ink"
            />
          </Field>

          {state?.error && (
            <p className="flex items-center gap-1.5 text-sm text-danger">
              <AlertCircle className="h-4 w-4 shrink-0" />
              {state.error}
            </p>
          )}

          <div className="flex justify-end">
            <SubmitButton />
          </div>
        </Card>
      </form>
    </div>
  );
}
