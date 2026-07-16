"use client";

import { useState } from "react";
import { Check } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

/** Waitlist capture. Posts to /api/waitlist and shows a warm success state. */
export function WaitlistForm({ dark = false }: { dark?: boolean }) {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "done" | "error">(
    "idle",
  );

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    const valid = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email.trim());
    if (!valid) {
      setStatus("error");
      return;
    }
    setStatus("loading");
    try {
      const res = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: email.trim() }),
      });
      if (res.ok) {
        setStatus("done");
        toast.success("You're on the list — we'll be in touch soon.");
      } else {
        setStatus("error");
        toast.error("Something went wrong. Please try again.");
      }
    } catch {
      setStatus("error");
      toast.error("Network hiccup — please try again.");
    }
  }

  if (status === "done") {
    return (
      <div
        className={cn(
          "flex items-center gap-3 text-[15px] font-semibold",
          dark ? "text-paper" : "text-ink",
        )}
      >
        <span
          className={cn(
            "grid h-7 w-7 place-items-center rounded-pill",
            dark ? "bg-paper text-ink" : "bg-ink text-paper",
          )}
        >
          <Check className="h-4 w-4" strokeWidth={3} />
        </span>
        You&rsquo;re on the list. We&rsquo;ll be in touch soon.
      </div>
    );
  }

  return (
    <form onSubmit={onSubmit} noValidate className="w-full max-w-md">
      <div className="flex flex-wrap gap-2.5">
        <input
          type="email"
          value={email}
          onChange={(e) => {
            setEmail(e.target.value);
            if (status === "error") setStatus("idle");
          }}
          placeholder="you@email.com"
          aria-label="Email address"
          className={cn(
            "h-12 min-w-[220px] flex-1 rounded-xl border px-4 text-base outline-none transition-colors",
            dark
              ? "border-white/20 bg-white/10 text-paper placeholder:text-white/50 focus:border-white"
              : "border-separator bg-card text-ink placeholder:text-muted-soft focus:border-ink",
            status === "error" && "border-danger",
          )}
        />
        <Button
          type="submit"
          disabled={status === "loading"}
          variant={dark ? "secondary" : "default"}
          className={dark ? "bg-paper text-ink hover:bg-white" : ""}
        >
          {status === "loading" ? "Joining…" : "Get early access"}
        </Button>
      </div>
      {status === "error" && (
        <p className="mt-2 text-sm text-danger">
          Please enter a valid email address.
        </p>
      )}
    </form>
  );
}
