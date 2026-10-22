"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import {
  CalendarClock,
  CalendarDays,
  Check,
  CheckCheck,
  X,
} from "lucide-react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { StatusBadge } from "./status-badge";
import { formatDate } from "@/lib/utils";
import { setReservationStatus } from "@/lib/actions/reservations";
import { isActive, type Reservation, type ReservationStatus } from "@/data/types";

function whenLabel(r: Reservation): string {
  const start = new Date(r.start);
  if (r.type === "visit") {
    const hh = start.getHours().toString().padStart(2, "0");
    const mm = start.getMinutes().toString().padStart(2, "0");
    return `${formatDate(start)} · ${hh}:${mm}`;
  }
  const end = r.end ? new Date(r.end) : null;
  const first = new Date(start.getFullYear(), start.getMonth(), start.getDate());
  const nights = end
    ? Math.round((end.getTime() - first.getTime()) / 86_400_000)
    : 0;
  return `${formatDate(start)} → ${end ? formatDate(end) : ""} · ${nights} nights`;
}

export function ReservationItem({
  reservation,
  manage = false,
  showGuest = true,
}: {
  reservation: Reservation;
  manage?: boolean;
  showGuest?: boolean;
}) {
  const [status, setStatus] = useState<ReservationStatus>(reservation.status);
  const [pending, startTransition] = useTransition();
  const router = useRouter();
  const isVisit = reservation.type === "visit";

  function update(
    next: Extract<ReservationStatus, "confirmed" | "cancelled" | "completed">,
  ) {
    const prev = status;
    setStatus(next);
    startTransition(async () => {
      const res = await setReservationStatus(reservation.id, next);
      if (res && "error" in res && res.error) {
        setStatus(prev); // revert on failure
        toast.error("Couldn't update the reservation. Please try again.");
      } else {
        toast.success(
          next === "confirmed"
            ? "Reservation confirmed"
            : next === "completed"
              ? "Marked as complete"
              : "Reservation declined",
        );
        router.refresh();
      }
    });
  }

  return (
    <Card className="p-4">
      <div className="flex items-start gap-3">
        <div className="grid h-10 w-10 shrink-0 place-items-center rounded-2xl bg-fill">
          {isVisit ? (
            <CalendarClock className="h-[18px] w-[18px]" />
          ) : (
            <CalendarDays className="h-[18px] w-[18px]" />
          )}
        </div>
        <div className="min-w-0 flex-1">
          <p className="truncate text-[15px] font-bold">
            {reservation.listingTitle}
          </p>
          <p className="text-[13px] text-muted">{whenLabel(reservation)}</p>
          {showGuest && (
            <p className="text-xs text-muted-soft">
              {reservation.guestName} · {reservation.guests}{" "}
              {reservation.guests === 1 ? "guest" : "guests"}
            </p>
          )}
        </div>
        <StatusBadge status={status} />
      </div>

      {manage && isActive(status) && (
        <div className="mt-3 flex gap-2">
          {status === "pending" && (
            <Button
              size="sm"
              className="flex-1"
              disabled={pending}
              onClick={() => update("confirmed")}
            >
              <Check className="h-4 w-4" /> Confirm
            </Button>
          )}
          {status === "confirmed" && (
            <Button
              size="sm"
              className="flex-1"
              disabled={pending}
              onClick={() => update("completed")}
            >
              <CheckCheck className="h-4 w-4" /> Mark done
            </Button>
          )}
          <Button
            size="sm"
            variant="secondary"
            className="flex-1"
            disabled={pending}
            onClick={() => update("cancelled")}
          >
            <X className="h-4 w-4" /> Decline
          </Button>
        </div>
      )}
    </Card>
  );
}
