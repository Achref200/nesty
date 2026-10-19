import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

/** Merge Tailwind class names with correct precedence. */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/** Format a whole-dinar amount the Tunisian way, e.g. 1900 -> "1 900 DT". */
export function formatDinars(amount: number): string {
  const digits = Math.round(Math.abs(amount)).toString();
  let out = "";
  for (let i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 === 0) out += " ";
    out += digits[i];
  }
  return `${amount < 0 ? "-" : ""}${out} DT`;
}

const MONTHS = [
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];

export function formatDate(d: Date): string {
  return `${d.getDate()} ${MONTHS[d.getMonth()]}`;
}

export function isSameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}
