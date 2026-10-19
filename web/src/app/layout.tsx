import type { Metadata, Viewport } from "next";
import { Outfit, Plus_Jakarta_Sans } from "next/font/google";
import { Toaster } from "sonner";
import { site } from "@/lib/site";
import "./globals.css";

const display = Outfit({
  subsets: ["latin"],
  variable: "--font-display",
  weight: ["500", "600", "700", "800"],
  display: "swap",
});

const sans = Plus_Jakarta_Sans({
  subsets: ["latin"],
  variable: "--font-sans",
  weight: ["400", "500", "600", "700"],
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL(site.url),
  title: { default: site.title, template: `%s · ${site.name}` },
  description: site.description,
  applicationName: site.name,
  keywords: [...site.keywords],
  authors: [{ name: site.name }],
  creator: site.name,
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    locale: site.locale,
    url: site.url,
    siteName: site.name,
    title: site.title,
    description: site.description,
  },
  twitter: {
    card: "summary_large_image",
    title: site.title,
    description: site.description,
  },
  robots: {
    index: true,
    follow: true,
    googleBot: { index: true, follow: true, "max-image-preview": "large" },
  },
  category: "real estate",
};

export const viewport: Viewport = {
  themeColor: "#FCFCFB",
  colorScheme: "light",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${display.variable} ${sans.variable}`}>
      <body>
        {children}
        <Toaster
          position="top-center"
          toastOptions={{
            style: {
              borderRadius: "14px",
              border: "1px solid #E6E6E4",
              background: "#ffffff",
              color: "#141414",
              fontFamily: "var(--font-sans)",
            },
          }}
        />
      </body>
    </html>
  );
}
