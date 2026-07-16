import { TypingHeadline } from "./typing-headline";
import { WaitlistForm } from "./waitlist-form";
import { ParallaxPanels } from "./parallax-panels";
import { site } from "@/lib/site";

export function Hero() {
  return (
    <section className="relative overflow-hidden py-24 md:py-28">
      <ParallaxPanels />
      <div className="mx-auto max-w-content px-6">
        <span className="mb-6 inline-flex items-center gap-2 rounded-pill bg-fill px-3 py-1.5 text-[13px] font-bold tracking-wide text-ink-soft">
          <span className="h-1.5 w-1.5 rounded-pill bg-ink" />
          Tunisia&rsquo;s PropTech, in private beta
        </span>
        <h1 className="max-w-[14ch] text-5xl font-extrabold leading-[1.03] md:text-7xl">
          <TypingHeadline text={site.tagline} />
        </h1>
        <p className="mt-5 max-w-xl text-lg text-muted md:text-xl">
          Nesty is a calmer way to rent. Walk every home in 3D, then book a
          visit or reserve your summer dates &mdash; no blurry photos, no wasted
          Saturdays.
        </p>
        <div className="mt-8" id="waitlist-hero">
          <WaitlistForm />
        </div>
        <p className="mt-3 text-sm text-muted-soft">
          Join <strong className="text-ink">312</strong> early movers. No spam,
          ever.
        </p>
      </div>
    </section>
  );
}
