import { WaitlistForm } from "./waitlist-form";
import { Reveal } from "./reveal";

export function WaitlistCta() {
  return (
    <section id="waitlist" className="pb-20 pt-4">
      <div className="mx-auto max-w-content px-6">
        <Reveal>
          <div className="rounded-[28px] bg-ink px-8 py-14 text-center text-paper md:px-10">
            <h2 className="mx-auto max-w-2xl text-3xl font-bold md:text-[44px]">
              Be first through the door.
            </h2>
            <p className="mx-auto mt-3.5 max-w-md text-white/70">
              We&rsquo;re opening Nesty to a small group of seekers and agencies.
              Leave your email and we&rsquo;ll bring you in.
            </p>
            <div className="mt-7 flex justify-center">
              <WaitlistForm dark />
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
