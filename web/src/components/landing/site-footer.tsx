import { Logo } from "@/components/brand/logo";

export function SiteFooter() {
  return (
    <footer className="border-t border-separator py-9">
      <div className="mx-auto flex max-w-content flex-wrap items-center gap-4 px-6 text-sm text-muted">
        <Logo size={22} />
        <div className="flex-1" />
        <span>
          &copy; {new Date().getFullYear()} Nesty &middot; Made in Tunisia
        </span>
      </div>
    </footer>
  );
}
