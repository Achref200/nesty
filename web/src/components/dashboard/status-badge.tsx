import { Badge } from "@/components/ui/badge";
import {
  RESERVATION_STATUS_LABEL,
  type ReservationStatus,
} from "@/data/types";

const VARIANT: Record<
  ReservationStatus,
  "solid" | "soft" | "muted" | "outline"
> = {
  confirmed: "solid",
  pending: "soft",
  completed: "muted",
  cancelled: "muted",
};

export function StatusBadge({ status }: { status: ReservationStatus }) {
  return (
    <Badge variant={VARIANT[status]}>{RESERVATION_STATUS_LABEL[status]}</Badge>
  );
}
