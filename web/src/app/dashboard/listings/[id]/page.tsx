import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import {
  ArrowLeft,
  Building2,
  Eye,
  Heart,
  DoorOpen,
  TrendingUp,
  MapPin,
} from "lucide-react";
import { StatCard } from "@/components/dashboard/stat-card";
import { ListingControls } from "@/components/dashboard/listing-controls";
import { ReservationItem } from "@/components/dashboard/reservation-item";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { getListingDetail } from "@/lib/queries";
import { formatDinars } from "@/lib/utils";
import { RENTAL_TERM_LABEL } from "@/data/types";

export default async function ListingDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const detail = await getListingDetail(params.id);
  if (!detail) notFound();

  const { listing, reservations } = detail;
  const saveRate =
    listing.views > 0 ? Math.round((listing.saves / listing.views) * 100) : 0;
  const hidden = listing.status === "hidden";

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center gap-2">
        <Button asChild variant="ghost" size="sm">
          <Link href="/dashboard/listings">
            <ArrowLeft className="h-4 w-4" /> Listings
          </Link>
        </Button>
      </div>

      <div className="flex flex-col gap-4 sm:flex-row sm:items-center">
        <div className="relative grid h-24 w-24 shrink-0 place-items-center overflow-hidden rounded-3xl bg-fill">
          {listing.cover ? (
            <Image
              src={listing.cover}
              alt={listing.title}
              fill
              sizes="96px"
              unoptimized
              className="object-cover"
            />
          ) : (
            <Building2 className="h-7 w-7 text-muted-soft" />
          )}
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <h1 className="font-display text-2xl font-extrabold tracking-tight">
              {listing.title}
            </h1>
            {hidden ? (
              <Badge variant="soft">Hidden</Badge>
            ) : (
              <Badge variant={listing.state === "reserved" ? "solid" : "soft"}>
                {listing.state === "reserved" ? "Reserved" : "Live"}
              </Badge>
            )}
            <Badge variant="soft">{RENTAL_TERM_LABEL[listing.rentalTerm]}</Badge>
          </div>
          <p className="mt-1 inline-flex items-center gap-1.5 text-[15px] text-muted">
            <MapPin className="h-4 w-4" /> {listing.city}
          </p>
        </div>
        <div className="text-right">
          <div className="font-display text-2xl font-extrabold">
            {formatDinars(listing.pricePerMonth)}
          </div>
          <div className="text-[13px] text-muted">per month</div>
        </div>
      </div>

      {listing.tags.length > 0 && (
        <div className="flex flex-wrap gap-2">
          {listing.tags.map((tag) => (
            <Badge key={tag} variant="soft">
              {tag}
            </Badge>
          ))}
        </div>
      )}

      {listing.audience.length > 0 && (
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-[13px] font-semibold text-muted">
            Suitable for
          </span>
          {listing.audience.map((a) => (
            <Badge key={a} variant="outline">
              {a}
            </Badge>
          ))}
        </div>
      )}

      <section className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatCard icon={Eye} value={`${listing.views}`} label="Views" />
        <StatCard icon={Heart} value={`${listing.saves}`} label="Saves" />
        <StatCard icon={DoorOpen} value={`${listing.tours}`} label="Tour requests" />
        <StatCard
          icon={TrendingUp}
          value={`${saveRate}%`}
          label="Save rate"
        />
      </section>

      <section className="grid gap-6 lg:grid-cols-[1fr_1fr]">
        <ListingControls
          id={listing.id}
          price={listing.pricePerMonth}
          status={listing.status}
        />

        <div>
          <h2 className="mb-4 font-display text-lg font-bold tracking-tight">
            Bookings & tours
          </h2>
          {reservations.length === 0 ? (
            <Card className="py-10 text-center text-[15px] text-muted">
              No requests for this place yet.
            </Card>
          ) : (
            <div className="flex flex-col gap-3">
              {reservations.map((r) => (
                <ReservationItem key={r.id} reservation={r} manage showGuest />
              ))}
            </div>
          )}
        </div>
      </section>
    </div>
  );
}
