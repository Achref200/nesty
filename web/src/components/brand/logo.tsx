import { cn } from "@/lib/utils";

/** The Nesty house mark + wordmark, in one place. */
export function Logo({
  className,
  showWordmark = true,
  size = 26,
}: {
  className?: string;
  showWordmark?: boolean;
  size?: number;
}) {
  return (
    <span className={cn("inline-flex items-center gap-2.5", className)}>
      <span
        className="grid place-items-center rounded-lg bg-ink text-paper"
        style={{ width: size, height: size }}
        aria-hidden="true"
      >
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth={2.2}
          strokeLinecap="round"
          strokeLinejoin="round"
          style={{ width: size * 0.58, height: size * 0.58 }}
        >
          <path d="M3 10.5 12 3l9 7.5" />
          <path d="M5 9.5V21h14V9.5" />
        </svg>
      </span>
      {showWordmark && (
        <span className="font-display text-xl font-extrabold tracking-tight">
          Nesty
        </span>
      )}
    </span>
  );
}
