import type { LucideIcon } from "lucide-react";
import { ArrowUpRight, ArrowDownRight } from "lucide-react";
import { Card } from "@/components/ui/card";
import { cn } from "@/lib/utils";

export function StatCard({
  icon: Icon,
  value,
  label,
  trend,
  positive,
}: {
  icon: LucideIcon;
  value: string;
  label: string;
  trend?: string;
  positive?: boolean;
}) {
  return (
    <Card className="p-5">
      <div className="flex items-center">
        <div className="grid h-10 w-10 place-items-center rounded-2xl bg-fill">
          <Icon className="h-[18px] w-[18px]" />
        </div>
        {trend && (
          <span
            className={cn(
              "ml-auto inline-flex items-center gap-0.5 text-xs font-bold",
              positive ? "text-ink" : "text-muted",
            )}
          >
            {positive ? (
              <ArrowUpRight className="h-3.5 w-3.5" />
            ) : (
              <ArrowDownRight className="h-3.5 w-3.5" />
            )}
            {trend}
          </span>
        )}
      </div>
      <div className="mt-4 font-display text-2xl font-extrabold">{value}</div>
      <div className="mt-0.5 text-[13px] text-muted">{label}</div>
    </Card>
  );
}
