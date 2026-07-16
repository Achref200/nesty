import { SiteNav } from "@/components/landing/site-nav";
import { Hero } from "@/components/landing/hero";
import {
  Steps,
  Audience,
  Features,
  ProblemSolution,
  Contact,
} from "@/components/landing/sections";
import { WaitlistCta } from "@/components/landing/waitlist-cta";
import { SiteFooter } from "@/components/landing/site-footer";
import { site } from "@/lib/site";

/** JSON-LD structured data helps Google understand the product & organisation. */
function StructuredData() {
  const json = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "Organization",
        name: site.name,
        url: site.url,
        description: site.description,
        areaServed: "TN",
      },
      {
        "@type": "WebSite",
        name: site.name,
        url: site.url,
        inLanguage: "en",
      },
      {
        "@type": "SoftwareApplication",
        name: site.name,
        applicationCategory: "BusinessApplication",
        operatingSystem: "Android, iOS, Web",
        offers: { "@type": "Offer", price: "0", priceCurrency: "TND" },
        description: site.description,
      },
    ],
  };
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(json) }}
    />
  );
}

export default function HomePage() {
  return (
    <>
      <StructuredData />
      <SiteNav />
      <main>
        <Hero />
        <ProblemSolution />
        <Steps />
        <Audience />
        <Features />
        <Contact />
        <WaitlistCta />
      </main>
      <SiteFooter />
    </>
  );
}
