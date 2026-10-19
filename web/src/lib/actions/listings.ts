"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export type CreateListingState = { error?: string };

const TYPE_MAP: Record<string, "entire_place" | "private_room" | "shared_room"> =
  {
    entirePlace: "entire_place",
    privateRoom: "private_room",
    sharedRoom: "shared_room",
  };

function num(value: FormDataEntryValue | null, fallback = 0): number {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

/** Create a listing owned by the signed-in agency. */
export async function createListing(
  _prev: CreateListingState,
  formData: FormData,
): Promise<CreateListingState> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: "You need to be signed in." };

  const title = String(formData.get("title") ?? "").trim();
  const city = String(formData.get("city") ?? "").trim();
  if (!title) return { error: "Give your place a title." };
  if (!city) return { error: "Add a city or area." };

  const { data: profile } = await supabase
    .from("profiles")
    .select("full_name")
    .eq("id", user.id)
    .single();

  const lat = formData.get("latitude");
  const lng = formData.get("longitude");
  const hasCoords = Boolean(lat) && Boolean(lng);

  const rentalTerm =
    String(formData.get("rentalTerm") ?? "longTerm") === "shortTerm"
      ? "short_term"
      : "long_term";
  const audience = String(formData.get("audience") ?? "")
    .split(",")
    .map((a) => a.trim())
    .filter(Boolean);

  const gallery = String(formData.get("gallery") ?? "")
    .split(",")
    .map((g) => g.trim())
    .filter(Boolean);
  const cover = String(formData.get("cover") ?? "").trim() || gallery[0] || null;

  const { error } = await supabase.from("listings").insert({
    host_id: user.id,
    host_name: profile?.full_name ?? null,
    title,
    city,
    address: String(formData.get("address") ?? "").trim() || null,
    price_per_month: num(formData.get("price")),
    type: TYPE_MAP[String(formData.get("type") ?? "entirePlace")] ?? "entire_place",
    rental_term: rentalTerm,
    audience,
    bedrooms: num(formData.get("bedrooms")),
    bathrooms: num(formData.get("bathrooms")),
    area_sqm: num(formData.get("area")),
    cover_image: cover,
    gallery,
    description: String(formData.get("description") ?? "").trim() || null,
    // Only sent when a pin is dropped, so basic creation works even before the
    // location columns migration is applied.
    ...(hasCoords
      ? { latitude: num(lat), longitude: num(lng) }
      : {}),
  });
  if (error) return { error: error.message };

  redirect("/dashboard/listings");
}

async function ownedListing(id: string) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { supabase, error: "You need to be signed in." as string };
  const { data } = await supabase
    .from("listings")
    .select("id")
    .eq("id", id)
    .eq("host_id", user.id)
    .maybeSingle();
  if (!data) return { supabase, error: "Listing not found." as string };
  return { supabase, error: undefined };
}

export type ListingControlState = { error?: string; ok?: boolean };

/** Update the monthly price of a listing the host owns. */
export async function updateListingPrice(
  id: string,
  price: number,
): Promise<ListingControlState> {
  if (!Number.isFinite(price) || price <= 0) {
    return { error: "Enter a valid price." };
  }
  const { supabase, error } = await ownedListing(id);
  if (error) return { error };
  const { error: updateError } = await supabase
    .from("listings")
    .update({ price_per_month: Math.round(price) })
    .eq("id", id);
  if (updateError) return { error: updateError.message };
  revalidatePath(`/dashboard/listings/${id}`);
  revalidatePath("/dashboard/listings");
  revalidatePath("/dashboard");
  return { ok: true };
}

/** Toggle a listing between active (visible) and hidden. */
export async function setListingStatus(
  id: string,
  status: "active" | "hidden",
): Promise<ListingControlState> {
  const { supabase, error } = await ownedListing(id);
  if (error) return { error };
  const { error: updateError } = await supabase
    .from("listings")
    .update({ status })
    .eq("id", id);
  if (updateError) return { error: updateError.message };
  revalidatePath(`/dashboard/listings/${id}`);
  revalidatePath("/dashboard/listings");
  revalidatePath("/dashboard");
  return { ok: true };
}

/** Permanently delete a listing the host owns. */
export async function deleteListing(id: string): Promise<ListingControlState> {
  const { supabase, error } = await ownedListing(id);
  if (error) return { error };
  const { error: deleteError } = await supabase
    .from("listings")
    .delete()
    .eq("id", id);
  if (deleteError) return { error: deleteError.message };
  revalidatePath("/dashboard/listings");
  revalidatePath("/dashboard");
  redirect("/dashboard/listings");
}
