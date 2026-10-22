import { cn } from "@/lib/utils";

/** A calm three-dot loader — used instead of spinners for in-flight states. */
export function Dots({ className }: { className?: string }) {
  return (
    <span
      className={cn("inline-flex items-center gap-1", className)}
      role="status"
      aria-label="Loading"
    >
      <span className="dot h-1.5 w-1.5 rounded-full bg-current" />
      <span
        className="dot h-1.5 w-1.5 rounded-full bg-current"
        style={{ animationDelay: "0.2s" }}
      />
      <span
        className="dot h-1.5 w-1.5 rounded-full bg-current"
        style={{ animationDelay: "0.4s" }}
      />
    </span>
  );
}
