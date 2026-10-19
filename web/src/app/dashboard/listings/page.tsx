import Link from "next/link";
import { Plus, Building2 } from "lucide-react";
import { ListingItem } from "@/components/dashboard/listing-item";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { getDashboardData } from "@/lib/queries";
import { cn } from "@/lib/utils";

const TERM_TABS = [
  { key: "all", label: "All" },
  { key: "longTerm", label: "Long term" },
  { key: "shortTerm", label: "Short term" },
] as const;

export default async function ListingsPage({
  searchParams,
}: {
  searchParams?: { term?: string };
}) {
  const data = await getDashboardData();
  if (!data) return null;

  const term = searchParams?.term ?? "all";
  const listings =
    term === "all"
      ? data.listings
      : data.listings.filter((l) => l.rentalTerm === term);

  const reserved = listings.filter((l) => l.state === "reserved").length;

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center">
        <p className="text-[15px] text-muted">
          {listings.length} places · {reserved} reserved ·{" "}
          {listings.length - reserved} available
        </p>
        <Button asChild size="sm" className="ml-auto">
          <Link href="/dashboard/listings/new">
            <Plus className="h-4 w-4" /> Add listing
          </Link>
        </Button>
      </div>

      <div className="flex gap-2">
        {TERM_TABS.map((t) => (
          <Link
            key={t.key}
            href={t.key === "all" ? "/dashboard/listings" : `?term=${t.key}`}
            className={cn(
              "rounded-full px-3.5 py-1.5 text-sm font-semibold transition-colors",
              term === t.key
                ? "bg-ink text-paper"
                : "bg-fill text-ink hover:bg-separator",
            )}
          >
            {t.label}
          </Link>
        ))}
      </div>

      {listings.length === 0 ? (
        <Card className="flex flex-col items-center gap-3 py-14 text-center">
          <div className="grid h-12 w-12 place-items-center rounded-2xl bg-fill">
            <Building2 className="h-6 w-6" />
          </div>
          <p className="font-display text-lg font-bold">No listings yet</p>
          <p className="max-w-sm text-[15px] text-muted">
            Publish your first place and it will appear in the Nesty app for
            seekers to tour and book.
          </p>
          <Button asChild size="sm" className="mt-1">
            <Link href="/dashboard/listings/new">
              <Plus className="h-4 w-4" /> Add your first listing
            </Link>
          </Button>
        </Card>
      ) : (
        <div className="flex flex-col gap-3">
          {listings.map((l) => (
            <ListingItem key={l.id} listing={l} />
          ))}
        </div>
      )}
    </div>
  );
}
