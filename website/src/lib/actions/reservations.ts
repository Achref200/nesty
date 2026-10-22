"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { ReservationStatus } from "@/data/types";

/** Update a reservation's status. RLS ensures only the host (or guest) can. */
export async function setReservationStatus(
  id: string,
  status: Extract<ReservationStatus, "confirmed" | "cancelled" | "completed">,
) {
  const supabase = createClient();
  const { error } = await supabase
    .from("reservations")
    .update({ status })
    .eq("id", id);
  if (error) return { error: error.message };

  revalidatePath("/dashboard");
  revalidatePath("/dashboard/requests");
  revalidatePath("/dashboard/calendar");
  return { ok: true };
}
