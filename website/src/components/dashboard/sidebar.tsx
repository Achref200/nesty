"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutGrid,
  Building2,
  CalendarDays,
  Inbox,
  LogOut,
} from "lucide-react";
import { Logo } from "@/components/brand/logo";
import { cn } from "@/lib/utils";
import { signOut } from "@/lib/actions/auth";

const NAV = [
  { href: "/dashboard", label: "Overview", icon: LayoutGrid },
  { href: "/dashboard/listings", label: "Listings", icon: Building2 },
  { href: "/dashboard/calendar", label: "Calendar", icon: CalendarDays },
  { href: "/dashboard/requests", label: "Requests", icon: Inbox },
];

export function Sidebar({ pending = 0 }: { pending?: number }) {
  const pathname = usePathname();

  return (
    <aside className="sticky top-0 hidden h-screen w-64 shrink-0 flex-col border-r border-separator bg-paper px-4 py-6 md:flex">
      <div className="px-2">
        <Logo />
      </div>

      <nav className="mt-8 flex flex-1 flex-col gap-1">
        {NAV.map((item) => {
          const active =
            item.href === "/dashboard"
              ? pathname === item.href
              : pathname.startsWith(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center gap-3 rounded-xl px-3 py-2.5 text-[15px] font-semibold transition-colors",
                active
                  ? "bg-ink text-paper"
                  : "text-muted hover:bg-fill hover:text-ink",
              )}
            >
              <item.icon className="h-[18px] w-[18px]" />
              <span className="flex-1">{item.label}</span>
              {item.label === "Requests" && pending > 0 && (
                <span
                  className={cn(
                    "grid h-5 min-w-5 place-items-center rounded-pill px-1 text-xs font-bold",
                    active ? "bg-paper text-ink" : "bg-ink text-paper",
                  )}
                >
                  {pending}
                </span>
              )}
            </Link>
          );
        })}
      </nav>

      <form action={signOut}>
        <button
          type="submit"
          className="flex w-full items-center gap-2 rounded-xl px-3 py-2.5 text-sm font-semibold text-muted hover:bg-fill hover:text-ink"
        >
          <LogOut className="h-4 w-4" />
          Sign out
        </button>
      </form>
    </aside>
  );
}
