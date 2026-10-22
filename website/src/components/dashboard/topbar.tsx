"use client";

import { usePathname } from "next/navigation";
import { Bell } from "lucide-react";

const TITLES: Record<string, string> = {
  "/dashboard": "Overview",
  "/dashboard/listings": "Listings",
  "/dashboard/calendar": "Calendar",
  "/dashboard/requests": "Requests",
};

export function Topbar({
  pending = 0,
  initial = "A",
}: {
  pending?: number;
  initial?: string;
}) {
  const pathname = usePathname();
  const title =
    TITLES[pathname] ??
    (pathname.startsWith("/dashboard/listings")
      ? "Listings"
      : pathname.startsWith("/dashboard/calendar")
        ? "Calendar"
        : pathname.startsWith("/dashboard/requests")
          ? "Requests"
          : "Overview");

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center gap-3 border-b border-separator bg-paper/80 px-6 backdrop-blur-md">
      <h1 className="font-display text-xl font-bold tracking-tight">{title}</h1>
      <div className="flex-1" />
      <button
        type="button"
        aria-label="Notifications"
        className="relative grid h-10 w-10 place-items-center rounded-xl border border-separator bg-card text-ink hover:bg-fill"
      >
        <Bell className="h-[18px] w-[18px]" />
        {pending > 0 && (
          <span className="absolute right-2 top-2 h-2 w-2 rounded-pill bg-ink ring-2 ring-paper" />
        )}
      </button>
      <div className="grid h-10 w-10 place-items-center rounded-pill bg-ink text-sm font-bold uppercase text-paper">
        {initial}
      </div>
    </header>
  );
}
