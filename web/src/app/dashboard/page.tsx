import Link from "next/link";
import {
  Inbox,
  CalendarCheck,
  Building2,
  BadgeCheck,
  Plus,
  Eye,
  Heart,
  DoorOpen,
} from "lucide-react";
import { StatCard } from "@/components/dashboard/stat-card";
import { ReservationItem } from "@/components/dashboard/reservation-item";
import { ListingItem } from "@/components/dashboard/listing-item";
import { Button } from "@/components/ui/button";
import { getDashboardData } from "@/lib/queries";
import { isActive } from "@/data/types";

export default async function OverviewPage() {
  const data = await getDashboardData();
  if (!data) return null;

  const now = Date.now();
  const upcoming = data.reservations.filter(
    (r) => isActive(r.status) && new Date(r.start).getTime() >= now - 864e5,
  );
  const confirmed = data.reservations.filter(
    (r) => r.status === "confirmed",
  ).length;
  const reserved = data.listings.filter((l) => l.state === "reserved").length;

  return (
    <div className="flex flex-col gap-8">
      <p className="text-[15px] text-muted">
        Welcome back, <span className="font-semibold text-ink">{data.fullName}</span>.
      </p>

      <section className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatCard icon={Inbox} value={`${data.pending}`} label="Pending requests" />
        <StatCard
          icon={CalendarCheck}
          value={`${upcoming.length}`}
          label="Upcoming"
        />
        <StatCard
          icon={Building2}
          value={`${data.listings.length}`}
          label="Active listings"
        />
        <StatCard
          icon={BadgeCheck}
          value={`${confirmed}`}
          label="Confirmed"
        />
      </section>

      <section>
        <div className="mb-4 flex items-center">
          <h2 className="font-display text-lg font-bold tracking-tight">
            Engagement
          </h2>
          <Button asChild variant="ghost" size="sm" className="ml-auto">
            <Link href="/dashboard/listings">By listing</Link>
          </Button>
        </div>
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-3">
          <StatCard
            icon={Eye}
            value={`${data.totals.views}`}
            label="Total views"
          />
          <StatCard
            icon={Heart}
            value={`${data.totals.saves}`}
            label="Total saves"
          />
          <StatCard
            icon={DoorOpen}
            value={`${data.totals.tours}`}
            label="Tour requests"
          />
        </div>
      </section>

      <section className="grid gap-8 lg:grid-cols-[1.4fr_1fr]">
        <div>
          <div className="mb-4 flex items-center">
            <h2 className="font-display text-lg font-bold tracking-tight">
              Next up
            </h2>
            <Button asChild variant="ghost" size="sm" className="ml-auto">
              <Link href="/dashboard/requests">View all</Link>
            </Button>
          </div>
          {upcoming.length === 0 ? (
            <p className="text-[15px] text-muted">
              No requests yet. When seekers book a visit or reserve dates on your
              listings, they land here.
            </p>
          ) : (
            <div className="flex flex-col gap-3">
              {upcoming.slice(0, 4).map((r) => (
                <ReservationItem key={r.id} reservation={r} manage showGuest />
              ))}
            </div>
          )}
        </div>

        <div>
          <div className="mb-4 flex items-center">
            <h2 className="font-display text-lg font-bold tracking-tight">
              Your portfolio
            </h2>
            <Button asChild variant="ghost" size="sm" className="ml-auto">
              <Link href="/dashboard/listings">Manage</Link>
            </Button>
          </div>
          {data.listings.length === 0 ? (
            <Button asChild size="sm">
              <Link href="/dashboard/listings/new">
                <Plus className="h-4 w-4" /> Add your first listing
              </Link>
            </Button>
          ) : (
            <div className="flex flex-col gap-3">
              {data.listings.slice(0, 4).map((l) => (
                <ListingItem key={l.id} listing={l} />
              ))}
            </div>
          )}
        </div>
      </section>
    </div>
  );
}
