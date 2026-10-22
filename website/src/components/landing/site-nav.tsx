import Link from "next/link";
import { Logo } from "@/components/brand/logo";
import { Button } from "@/components/ui/button";
import { site } from "@/lib/site";

export function SiteNav() {
  return (
    <header className="sticky top-0 z-50 border-b border-separator bg-paper/70 backdrop-blur-md backdrop-saturate-150">
      <div className="mx-auto flex h-16 max-w-content items-center gap-3 px-6">
        <Link href="/" aria-label="Nesty home">
          <Logo />
        </Link>
        <div className="flex-1" />
        <nav className="hidden items-center gap-7 text-sm font-semibold text-muted md:flex">
          {site.nav.map((item) => (
            <a key={item.href} href={item.href} className="hover:text-ink">
              {item.label}
            </a>
          ))}
        </nav>
        <div className="ml-2 flex items-center gap-2">
          <Button asChild variant="ghost" size="sm" className="hidden sm:inline-flex">
            <Link href="/dashboard">Agency login</Link>
          </Button>
          <Button asChild size="sm">
            <a href="#waitlist">Join the waitlist</a>
          </Button>
        </div>
      </div>
    </header>
  );
}
