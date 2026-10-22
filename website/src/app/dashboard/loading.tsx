import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

/** Route-level loading skeleton shown while a dashboard page fetches data. */
export default function DashboardLoading() {
  return (
    <div className="flex flex-col gap-8">
      <Skeleton className="h-5 w-40" />

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <Card key={i} className="p-5">
            <Skeleton className="h-10 w-10 rounded-2xl" />
            <Skeleton className="mt-4 h-7 w-16" />
            <Skeleton className="mt-2 h-4 w-24" />
          </Card>
        ))}
      </div>

      <div className="grid gap-8 lg:grid-cols-[1.4fr_1fr]">
        <div>
          <Skeleton className="mb-4 h-6 w-24" />
          <div className="flex flex-col gap-3">
            {Array.from({ length: 3 }).map((_, i) => (
              <Card key={i} className="p-4">
                <div className="flex items-center gap-3">
                  <Skeleton className="h-10 w-10 rounded-2xl" />
                  <div className="flex-1">
                    <Skeleton className="h-4 w-40" />
                    <Skeleton className="mt-2 h-3 w-24" />
                  </div>
                  <Skeleton className="h-6 w-16 rounded-pill" />
                </div>
              </Card>
            ))}
          </div>
        </div>
        <div>
          <Skeleton className="mb-4 h-6 w-28" />
          <div className="flex flex-col gap-3">
            {Array.from({ length: 3 }).map((_, i) => (
              <Card key={i} className="flex items-center gap-4 p-3">
                <Skeleton className="h-20 w-20 rounded-2xl" />
                <div className="flex-1">
                  <Skeleton className="h-4 w-32" />
                  <Skeleton className="mt-2 h-3 w-20" />
                </div>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
