"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { Eye, EyeOff, Save, Trash2 } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  deleteListing,
  setListingStatus,
  updateListingPrice,
} from "@/lib/actions/listings";

export function ListingControls({
  id,
  price,
  status,
}: {
  id: string;
  price: number;
  status: "active" | "hidden";
}) {
  const router = useRouter();
  const [value, setValue] = useState(String(price));
  const [confirming, setConfirming] = useState(false);
  const [pending, startTransition] = useTransition();

  function savePrice() {
    const next = Number(value);
    if (!Number.isFinite(next) || next <= 0) {
      toast.error("Enter a valid price.");
      return;
    }
    startTransition(async () => {
      const res = await updateListingPrice(id, next);
      if (res.error) {
        toast.error(res.error);
      } else {
        toast.success("Price updated");
        router.refresh();
      }
    });
  }

  function toggleStatus() {
    const next = status === "active" ? "hidden" : "active";
    startTransition(async () => {
      const res = await setListingStatus(id, next);
      if (res.error) {
        toast.error(res.error);
      } else {
        toast.success(next === "hidden" ? "Listing hidden" : "Listing is live");
        router.refresh();
      }
    });
  }

  function remove() {
    startTransition(async () => {
      const res = await deleteListing(id);
      // deleteListing redirects on success; only errors return here.
      if (res?.error) toast.error(res.error);
    });
  }

  return (
    <Card className="flex flex-col gap-5 p-5">
      <div>
        <p className="font-display text-[15px] font-bold">Price control</p>
        <p className="mt-0.5 text-[13px] text-muted">
          Update the monthly price seekers see in the app.
        </p>
        <div className="mt-3 flex items-center gap-2">
          <div className="relative flex-1">
            <Input
              type="number"
              inputMode="numeric"
              min={1}
              value={value}
              onChange={(e) => setValue(e.target.value)}
              className="pr-14"
            />
            <span className="pointer-events-none absolute right-4 top-1/2 -translate-y-1/2 text-sm text-muted">
              TND
            </span>
          </div>
          <Button
            onClick={savePrice}
            disabled={pending || value === String(price)}
            size="default"
          >
            <Save className="h-4 w-4" /> Save
          </Button>
        </div>
      </div>

      <div className="h-px bg-separator" />

      <div className="flex items-center gap-3">
        <div className="min-w-0 flex-1">
          <p className="font-display text-[15px] font-bold">Visibility</p>
          <p className="mt-0.5 text-[13px] text-muted">
            {status === "active"
              ? "Live and bookable in the app."
              : "Hidden — seekers can't find or book it."}
          </p>
        </div>
        <Button variant="outline" onClick={toggleStatus} disabled={pending}>
          {status === "active" ? (
            <>
              <EyeOff className="h-4 w-4" /> Hide
            </>
          ) : (
            <>
              <Eye className="h-4 w-4" /> Publish
            </>
          )}
        </Button>
      </div>

      <div className="h-px bg-separator" />

      <div className="flex items-center gap-3">
        <div className="min-w-0 flex-1">
          <p className="font-display text-[15px] font-bold">Delete listing</p>
          <p className="mt-0.5 text-[13px] text-muted">
            Permanently remove this place and its data.
          </p>
        </div>
        {confirming ? (
          <div className="flex items-center gap-2">
            <Button
              variant="ghost"
              onClick={() => setConfirming(false)}
              disabled={pending}
            >
              Cancel
            </Button>
            <Button variant="danger" onClick={remove} disabled={pending}>
              <Trash2 className="h-4 w-4" /> Confirm
            </Button>
          </div>
        ) : (
          <Button
            variant="outline"
            onClick={() => setConfirming(true)}
            disabled={pending}
          >
            <Trash2 className="h-4 w-4" /> Delete
          </Button>
        )}
      </div>
    </Card>
  );
}
