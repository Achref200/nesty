"use client";

import { useEffect } from "react";
import { WifiOff, RotateCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";

/** Error boundary for the dashboard — catches failed data fetches / network issues. */
export default function DashboardError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // Surface for debugging; wire to your error tracker later.
    console.error(error);
  }, [error]);

  return (
    <div className="grid min-h-[60vh] place-items-center">
      <Card className="max-w-md p-8 text-center">
        <div className="mx-auto mb-5 grid h-14 w-14 place-items-center rounded-2xl bg-fill">
          <WifiOff className="h-6 w-6" />
        </div>
        <h2 className="font-display text-2xl font-bold">
          Something went sideways
        </h2>
        <p className="mt-2 text-[15px] text-muted">
          We couldn&rsquo;t load this just now — it&rsquo;s usually a dropped
          connection. Give it another try.
        </p>
        <div className="mt-6 flex justify-center">
          <Button onClick={reset} size="sm">
            <RotateCw className="h-4 w-4" /> Try again
          </Button>
        </div>
      </Card>
    </div>
  );
}
