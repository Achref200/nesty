import {
  Box,
  CalendarCheck,
  ShieldCheck,
  Search,
  Building2,
  BadgeCheck,
  MapPin,
  LineChart,
  CalendarDays,
  Check,
  X,
  Mail,
  ArrowRight,
} from "lucide-react";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Reveal } from "./reveal";

function SectionHead({
  kicker,
  title,
  sub,
}: {
  kicker: string;
  title: string;
  sub?: string;
}) {
  return (
    <Reveal>
      <span className="text-[13px] font-bold uppercase tracking-[0.08em] text-muted-soft">
        {kicker}
      </span>
      <h2 className="mt-3 text-3xl font-bold md:text-[42px]">{title}</h2>
      {sub && <p className="mt-3 max-w-xl text-[17px] text-muted">{sub}</p>}
    </Reveal>
  );
}

const STEPS = [
  {
    icon: Box,
    n: "01",
    title: "Tour in 3D",
    body: "Walk through every room from your couch, day or night. What you see is what you get.",
  },
  {
    icon: CalendarCheck,
    n: "02",
    title: "Book a visit or reserve",
    body: "Pick a viewing slot, or hold your summer dates with a check-in and check-out.",
  },
  {
    icon: ShieldCheck,
    n: "03",
    title: "Move in with confidence",
    body: "Every listing is verified and tracked, so there are no surprises when you arrive.",
  },
];

export function Steps() {
  return (
    <section id="how" className="py-20">
      <div className="mx-auto max-w-content px-6">
        <SectionHead
          kicker="How it works"
          title="Three steps to a home you trust."
          sub="The whole point of Nesty: only visit the place you already believe in."
        />
        <div className="mt-10 grid gap-4 md:grid-cols-3">
          {STEPS.map((s, i) => (
            <Reveal key={s.n} delay={i * 70}>
              <Card hover className="h-full">
                <div className="mb-4 grid h-11 w-11 place-items-center rounded-2xl bg-fill">
                  <s.icon className="h-5 w-5" />
                </div>
                <span className="font-display text-sm font-extrabold text-muted-soft">
                  {s.n}
                </span>
                <h3 className="mt-1 text-lg font-bold">{s.title}</h3>
                <p className="mt-2 text-[15px] text-muted">{s.body}</p>
              </Card>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

export function Audience() {
  return (
    <section id="who" className="py-20">
      <div className="mx-auto max-w-content px-6">
        <SectionHead
          kicker="Who it's for"
          title="Two sides, one calm marketplace."
        />
        <div className="mt-9 grid gap-4 md:grid-cols-2">
          <Reveal>
            <div className="h-full rounded-3xl border border-separator p-8">
              <Badge variant="soft">
                <Search className="h-3.5 w-3.5" /> For seekers
              </Badge>
              <h3 className="mt-4 font-display text-2xl font-bold">
                Find a home without the guesswork
              </h3>
              <p className="mt-2.5 text-[15px] text-muted">
                Students and young professionals who want to tour, compare and
                shortlist homes &mdash; then book a visit or reserve their dates
                in a couple of taps.
              </p>
            </div>
          </Reveal>
          <Reveal delay={70}>
            <div className="h-full rounded-3xl border border-ink bg-ink p-8 text-paper">
              <Badge className="bg-white/15 text-paper">
                <Building2 className="h-3.5 w-3.5" /> For agencies
              </Badge>
              <h3 className="mt-4 font-display text-2xl font-bold">
                See your whole portfolio at a glance
              </h3>
              <p className="mt-2.5 text-[15px] text-white/70">
                List properties, and track visits, reservations and requests on
                a live calendar &mdash; know instantly what&rsquo;s reserved and
                what&rsquo;s free.
              </p>
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}

const FEATURES = [
  { icon: Box, title: "Immersive 3D tours", body: "Every room, navigable in 360° — a real walkthrough, not a slideshow." },
  { icon: CalendarDays, title: "Visits & reservations", body: "A full booking flow with a live calendar for both sides." },
  { icon: BadgeCheck, title: "Trust & verification", body: "Verified listings and owners — confidence before you commit." },
  { icon: LineChart, title: "Agency insights", body: "Views, saves and tour attention — see how people react to a place." },
  { icon: MapPin, title: "Neighbourhood intel", body: "Transport, schools and lifestyle scores around every home." },
  { icon: CalendarCheck, title: "Summer rentals", body: "Hold your vacation dates with a clear check-in and check-out." },
];

export function Features() {
  return (
    <section id="features" className="py-20">
      <div className="mx-auto max-w-content px-6">
        <SectionHead kicker="What's inside" title="Built to feel effortless." />
        <div className="mt-10 grid gap-4 md:grid-cols-3">
          {FEATURES.map((f, i) => (
            <Reveal key={f.title} delay={(i % 3) * 70}>
              <Card hover className="h-full">
                <div className="mb-4 grid h-11 w-11 place-items-center rounded-2xl bg-fill">
                  <f.icon className="h-5 w-5" />
                </div>
                <h3 className="text-lg font-bold">{f.title}</h3>
                <p className="mt-2 text-[15px] text-muted">{f.body}</p>
              </Card>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

const PROBLEMS = [
  "Listings live in Facebook groups and blurry photos.",
  "You lose whole Saturdays visiting places that don't match.",
  "No way to know if an owner — or a listing — is real.",
  "Agencies have zero visibility into who's interested.",
];

const SOLUTIONS = [
  "Every home is a real 3D walkthrough you tour from your couch.",
  "Book a visit or reserve your dates in a couple of taps.",
  "Verified listings and owners, with trust built in.",
  "Agencies get a live dashboard of visits and reservations.",
];

export function ProblemSolution() {
  return (
    <section id="why" className="py-20">
      <div className="mx-auto max-w-content px-6">
        <SectionHead
          kicker="Why we built it"
          title="Renting shouldn't feel like a gamble."
          sub="In Tunisia, finding a home means scrolling groups, guessing from photos and hoping for the best. Nesty replaces the guesswork with confidence — for seekers and agencies alike."
        />
        <div className="mt-10 grid gap-4 md:grid-cols-2">
          <Reveal>
            <div className="h-full rounded-3xl border border-separator p-8">
              <span className="text-[13px] font-bold uppercase tracking-[0.08em] text-muted-soft">
                The problem
              </span>
              <ul className="mt-4 flex flex-col gap-3">
                {PROBLEMS.map((p) => (
                  <li key={p} className="flex items-start gap-3 text-[15px]">
                    <span className="mt-0.5 grid h-5 w-5 shrink-0 place-items-center rounded-pill bg-fill">
                      <X className="h-3 w-3 text-muted" />
                    </span>
                    <span className="text-muted">{p}</span>
                  </li>
                ))}
              </ul>
            </div>
          </Reveal>
          <Reveal delay={70}>
            <div className="h-full rounded-3xl border border-ink bg-ink p-8 text-paper">
              <span className="text-[13px] font-bold uppercase tracking-[0.08em] text-white/50">
                How Nesty solves it
              </span>
              <ul className="mt-4 flex flex-col gap-3">
                {SOLUTIONS.map((s) => (
                  <li key={s} className="flex items-start gap-3 text-[15px]">
                    <span className="mt-0.5 grid h-5 w-5 shrink-0 place-items-center rounded-pill bg-white/15">
                      <Check className="h-3 w-3 text-paper" />
                    </span>
                    <span className="text-white/85">{s}</span>
                  </li>
                ))}
              </ul>
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}

export function Contact() {
  return (
    <section id="contact" className="py-20">
      <div className="mx-auto max-w-content px-6">
        <div className="grid gap-4 md:grid-cols-2">
          <Reveal>
            <Card className="flex h-full flex-col justify-between gap-6 p-8">
              <div>
                <div className="mb-4 grid h-11 w-11 place-items-center rounded-2xl bg-fill">
                  <Search className="h-5 w-5" />
                </div>
                <h3 className="font-display text-2xl font-bold">
                  Looking for a home?
                </h3>
                <p className="mt-2 text-[15px] text-muted">
                  Join the waitlist above and we&rsquo;ll bring you into the
                  Nesty app the moment it&rsquo;s ready.
                </p>
              </div>
              <Button asChild variant="secondary" className="w-fit">
                <a href="#waitlist">
                  Join the waitlist <ArrowRight className="h-4 w-4" />
                </a>
              </Button>
            </Card>
          </Reveal>
          <Reveal delay={70}>
            <Card className="flex h-full flex-col justify-between gap-6 p-8">
              <div>
                <div className="mb-4 grid h-11 w-11 place-items-center rounded-2xl bg-fill">
                  <Building2 className="h-5 w-5" />
                </div>
                <h3 className="font-display text-2xl font-bold">
                  Are you an agency?
                </h3>
                <p className="mt-2 text-[15px] text-muted">
                  Nesty sets your dashboard up for you — listings, visits,
                  reservations and offers, all in one place. Reach out and
                  we&rsquo;ll get you access.
                </p>
              </div>
              <Button asChild className="w-fit">
                <a href="mailto:hello@nesty.tn">
                  <Mail className="h-4 w-4" /> hello@nesty.tn
                </a>
              </Button>
            </Card>
          </Reveal>
        </div>
      </div>
    </section>
  );
}
