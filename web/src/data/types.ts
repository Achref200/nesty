/** Domain types shared across the web app — mirrors the mobile app's model. */

export type ListingType = "entirePlace" | "privateRoom" | "sharedRoom";

export type ListingState = "available" | "reserved";

export type RentalTerm = "shortTerm" | "longTerm";

export const RENTAL_TERM_LABEL: Record<RentalTerm, string> = {
  shortTerm: "Short term",
  longTerm: "Long term",
};

export interface Listing {
  id: string;
  hostId: string;
  title: string;
  city: string;
  pricePerMonth: number;
  type: ListingType;
  rentalTerm: RentalTerm;
  audience: string[];
  bedrooms: number;
  bathrooms: number;
  areaSqm: number;
  cover: string | null;
  rating: number;
  reviewCount: number;
  state: ListingState;
  latitude: number | null;
  longitude: number | null;
  status: "active" | "hidden";
  tags: string[];
  views: number;
  saves: number;
  tours: number;
}

export type ReservationType = "visit" | "stay";

export type ReservationStatus =
  | "pending"
  | "confirmed"
  | "cancelled"
  | "completed";

export interface Reservation {
  id: string;
  listingId: string;
  listingTitle: string;
  city: string;
  guestName: string;
  type: ReservationType;
  /** ISO date (visit: date + time; stay: check-in). */
  start: string;
  /** ISO date (stay check-out). */
  end?: string;
  guests: number;
  status: ReservationStatus;
  note?: string;
  estimatedTotal?: number;
}

export const RESERVATION_STATUS_LABEL: Record<ReservationStatus, string> = {
  pending: "Pending",
  confirmed: "Confirmed",
  cancelled: "Cancelled",
  completed: "Completed",
};

export function isActive(status: ReservationStatus): boolean {
  return status === "pending" || status === "confirmed";
}
