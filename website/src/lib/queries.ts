import { createClient } from "@/lib/supabase/server";
import type { Database } from "@/types/database";
import type {
  Listing,
  ListingType,
  Reservation,
  ReservationStatus,
  ReservationType,
} from "@/data/types";

type ListingRow = Database["public"]["Tables"]["listings"]["Row"];
type ReservationRow = Database["public"]["Tables"]["reservations"]["Row"] & {
  listings?: { title: string | null; city: string | null } | null;
};
type EventLite = { listing_id: string; type: string };

export interface ListingStats {
  views: number;
  saves: number;
  tours: number;
}

const emptyStats = (): ListingStats => ({ views: 0, saves: 0, tours: 0 });

function toListingType(t: string): ListingType {
  if (t === "private_room") return "privateRoom";
  if (t === "shared_room") return "sharedRoom";
  return "entirePlace";
}

function aggregate(events: EventLite[]): {
  byListing: Map<string, ListingStats>;
  totals: ListingStats;
} {
  const byListing = new Map<string, ListingStats>();
  const totals = emptyStats();
  for (const e of events) {
    const s = byListing.get(e.listing_id) ?? emptyStats();
    if (e.type === "view") {
      s.views += 1;
      totals.views += 1;
    } else if (e.type === "save") {
      s.saves += 1;
      totals.saves += 1;
    } else if (e.type === "tour") {
      s.tours += 1;
      totals.tours += 1;
    }
    byListing.set(e.listing_id, s);
  }
  return { byListing, totals };
}

function mapListing(
  row: ListingRow,
  reserved: boolean,
  stats: ListingStats,
): Listing {
  return {
    id: row.id,
    hostId: row.host_id,
    title: row.title,
    city: row.city,
    pricePerMonth: Number(row.price_per_month),
    type: toListingType(row.type),
    rentalTerm: row.rental_term === "short_term" ? "shortTerm" : "longTerm",
    audience: row.audience ?? [],
    bedrooms: row.bedrooms,
    bathrooms: row.bathrooms,
    areaSqm: Number(row.area_sqm),
    cover: row.cover_image,
    rating: Number(row.rating),
    reviewCount: row.review_count,
    state: reserved ? "reserved" : "available",
    latitude: row.latitude ?? null,
    longitude: row.longitude ?? null,
    status: row.status,
    tags: row.tags ?? [],
    views: stats.views,
    saves: stats.saves,
    tours: stats.tours,
  };
}

function mapReservation(row: ReservationRow): Reservation {
  return {
    id: row.id,
    listingId: row.listing_id,
    listingTitle: row.listings?.title ?? "Listing",
    city: row.listings?.city ?? "",
    guestName: row.guest_name ?? "Guest",
    type: row.type as ReservationType,
    start: row.start_at,
    end: row.end_at ?? undefined,
    guests: row.guests,
    status: row.status as ReservationStatus,
    note: row.note ?? undefined,
    estimatedTotal: row.estimated_total ?? undefined,
  };
}

function isReservedNow(rows: { status: string; start_at: string }[]): boolean {
  const grace = Date.now() - 864e5;
  return rows.some(
    (r) =>
      (r.status === "pending" || r.status === "confirmed") &&
      new Date(r.start_at).getTime() >= grace,
  );
}

export interface DashboardData {
  role: "seeker" | "host";
  fullName: string;
  email: string;
  listings: Listing[];
  reservations: Reservation[];
  pending: number;
  totals: ListingStats;
}

/** Everything the agency dashboard needs for the signed-in host. */
export async function getDashboardData(): Promise<DashboardData | null> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const [profileRes, listingsRes, reservationsRes, eventsRes] =
    await Promise.all([
      supabase.from("profiles").select("*").eq("id", user.id).single(),
      supabase
        .from("listings")
        .select("*")
        .eq("host_id", user.id)
        .order("created_at", { ascending: false }),
      supabase
        .from("reservations")
        .select("*, listings(title, city)")
        .eq("host_id", user.id)
        .order("start_at", { ascending: true }),
      supabase
        .from("listing_events")
        .select("listing_id,type")
        .eq("host_id", user.id),
    ]);

  const reservationRows = (reservationsRes.data ??
    []) as unknown as ReservationRow[];
  const reservations = reservationRows.map(mapReservation);

  const grace = Date.now() - 864e5;
  const reservedIds = new Set(
    reservationRows
      .filter(
        (r) =>
          (r.status === "pending" || r.status === "confirmed") &&
          new Date(r.start_at).getTime() >= grace,
      )
      .map((r) => r.listing_id),
  );

  const { byListing, totals } = aggregate(
    (eventsRes.data ?? []) as EventLite[],
  );

  const listings = (listingsRes.data ?? []).map((row) =>
    mapListing(
      row as ListingRow,
      reservedIds.has((row as ListingRow).id),
      byListing.get((row as ListingRow).id) ?? emptyStats(),
    ),
  );

  const pending = reservations.filter((r) => r.status === "pending").length;

  return {
    role: profileRes.data?.role ?? "host",
    fullName: profileRes.data?.full_name ?? user.email?.split("@")[0] ?? "there",
    email: user.email ?? "",
    listings,
    reservations,
    pending,
    totals,
  };
}

export interface ListingDetail {
  listing: Listing;
  reservations: Reservation[];
}

/** A single listing owned by the current host, with its analytics & bookings. */
export async function getListingDetail(
  id: string,
): Promise<ListingDetail | null> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const [listingRes, eventsRes, reservationsRes] = await Promise.all([
    supabase
      .from("listings")
      .select("*")
      .eq("id", id)
      .eq("host_id", user.id)
      .maybeSingle(),
    supabase.from("listing_events").select("listing_id,type").eq("listing_id", id),
    supabase
      .from("reservations")
      .select("*, listings(title, city)")
      .eq("listing_id", id)
      .eq("host_id", user.id)
      .order("start_at", { ascending: true }),
  ]);

  if (!listingRes.data) return null;

  const { byListing } = aggregate((eventsRes.data ?? []) as EventLite[]);
  const reservationRows = (reservationsRes.data ??
    []) as unknown as ReservationRow[];
  const reservations = reservationRows.map(mapReservation);
  const reserved = isReservedNow(reservationRows);

  const listing = mapListing(
    listingRes.data as ListingRow,
    reserved,
    byListing.get(id) ?? emptyStats(),
  );
  return { listing, reservations };
}
