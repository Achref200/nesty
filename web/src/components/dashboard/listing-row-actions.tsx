"use client";

import { useState, useTransition } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { MoreHorizontal, Pencil, Eye, EyeOff, Trash2 } from "lucide-react";
import { setListingStatus, deleteListing } from "@/lib/actions/listings";
import { cn } from "@/lib/utils";

/** Inline manage menu (edit / hide / delete) for a listing row. */
export function ListingRowActions({
  id,
  hidden,
}: {
  id: string;
  hidden: boolean;
}) {
  const [open, setOpen] = useState(false);
  const [pending, start] = useTransition();
  const router = useRouter();

  function toggleHide() {
    setOpen(false);
    start(async () => {
      const res = await setListingStatus(id, hidden ? "active" : "hidden");
      if (res.error) toast.error(res.error);
      else {
        toast.success(hidden ? "Listing is live" : "Listing hidden");
        router.refresh();
      }
    });
  }

  function remove() {
    setOpen(false);
    if (!confirm("Delete this listing permanently?")) return;
    start(async () => {
      const res = await deleteListing(id);
      if (res?.error) toast.error(res.error);
    });
  }

  return (
    <div className="relative">
      <button
        type="button"
        aria-label="Manage listing"
        disabled={pending}
        onClick={() => setOpen((o) => !o)}
        className={cn(
          "grid h-8 w-8 place-items-center rounded-lg border border-separator bg-card text-ink transition-colors hover:bg-fill",
          pending && "opacity-50",
        )}
      >
        <MoreHorizontal className="h-4 w-4" />
      </button>

      {open && (
        <>
          <div
            className="fixed inset-0 z-10"
            onClick={() => setOpen(false)}
          />
          <div className="absolute right-0 z-20 mt-1 w-44 overflow-hidden rounded-xl border border-separator bg-card py-1 shadow-lg">
            <Link
              href={`/dashboard/listings/${id}`}
              className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-ink hover:bg-fill"
              onClick={() => setOpen(false)}
            >
              <Pencil className="h-4 w-4" /> Edit details
            </Link>
            <button
              type="button"
              onClick={toggleHide}
              className="flex w-full items-center gap-2 px-3 py-2 text-sm font-medium text-ink hover:bg-fill"
            >
              {hidden ? (
                <>
                  <Eye className="h-4 w-4" /> Publish
                </>
              ) : (
                <>
                  <EyeOff className="h-4 w-4" /> Hide
                </>
              )}
            </button>
            <button
              type="button"
              onClick={remove}
              className="flex w-full items-center gap-2 px-3 py-2 text-sm font-medium text-danger hover:bg-fill"
            >
              <Trash2 className="h-4 w-4" /> Delete
            </button>
          </div>
        </>
      )}
    </div>
  );
}
