"use client";

import { useState } from "react";
import { ReservationItem } from "@/components/dashboard/reservation-item";
import { cn } from "@/lib/utils";
import type { Reservation, ReservationStatus } from "@/data/types";

const FILTERS: { key: "all" | ReservationStatus; label: string }[] = [
  { key: "all", label: "All" },
  { key: "pending", label: "Pending" },
  { key: "confirmed", label: "Confirmed" },
  { key: "completed", label: "Completed" },
];

export function RequestsView({
  reservations,
}: {
  reservations: Reservation[];
}) {
  const [filter, setFilter] = useState<"all" | ReservationStatus>("all");

  const items =
    filter === "all"
      ? reservations
      : reservations.filter((r) => r.status === filter);

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap gap-2">
        {FILTERS.map((f) => {
          const count =
            f.key === "all"
              ? reservations.length
              : reservations.filter((r) => r.status === f.key).length;
          return (
            <button
              key={f.key}
              type="button"
              onClick={() => setFilter(f.key)}
              className={cn(
                "inline-flex items-center gap-1.5 rounded-pill px-3.5 py-2 text-sm font-bold transition-colors",
                filter === f.key
                  ? "bg-ink text-paper"
                  : "bg-fill text-ink hover:bg-separator",
              )}
            >
              {f.label}
              <span
                className={cn(
                  "text-xs",
                  filter === f.key ? "text-paper/70" : "text-muted",
                )}
              >
                {count}
              </span>
            </button>
          );
        })}
      </div>

      {items.length === 0 ? (
        <p className="text-[15px] text-muted">No requests in this view.</p>
      ) : (
        <div className="grid gap-3 md:grid-cols-2">
          {items.map((r) => (
            <ReservationItem key={r.id} reservation={r} manage showGuest />
          ))}
        </div>
      )}
    </div>
  );
}
