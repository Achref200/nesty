import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { Database, ShieldAlert } from "lucide-react";
import { Sidebar } from "@/components/dashboard/sidebar";
import { Topbar } from "@/components/dashboard/topbar";
import { Logo } from "@/components/brand/logo";
import { Button } from "@/components/ui/button";
import { getDashboardData } from "@/lib/queries";
import { isSupabaseConfigured } from "@/lib/supabase/env";
import { signOut } from "@/lib/actions/auth";

export const metadata: Metadata = {
  title: "Agency dashboard",
  robots: { index: false, follow: false },
};

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  if (!isSupabaseConfigured) {
    return <ConnectSupabase />;
  }

  const data = await getDashboardData();
  if (!data) redirect("/login");

  // The web portal is B2B only — seeker accounts belong on the mobile app.
  if (data.role !== "host") {
    return <NotAgency />;
  }

  const initial = (data.fullName || data.email || "A").charAt(0);

  return (
    <div className="surface-aura flex min-h-screen">
      <Sidebar pending={data.pending} />
      <div className="flex min-w-0 flex-1 flex-col">
        <Topbar pending={data.pending} initial={initial} />
        <main className="mx-auto w-full max-w-5xl flex-1 px-6 py-8">
          {children}
        </main>
      </div>
    </div>
  );
}

function NotAgency() {
  return (
    <main className="grid min-h-screen place-items-center bg-paper px-6">
      <div className="w-full max-w-md rounded-3xl border border-separator bg-card p-8 text-center">
        <div className="mx-auto mb-5 grid h-14 w-14 place-items-center rounded-2xl bg-fill">
          <ShieldAlert className="h-6 w-6" />
        </div>
        <h1 className="font-display text-2xl font-bold">Agencies only</h1>
        <p className="mt-2 text-[15px] text-muted">
          This dashboard is for real-estate agencies. If you&rsquo;re looking for
          a home, use the Nesty mobile app instead.
        </p>
        <form action={signOut} className="mt-6 flex justify-center">
          <Button type="submit" variant="secondary" size="sm">
            Sign out
          </Button>
        </form>
      </div>
    </main>
  );
}

function ConnectSupabase() {
  return (
    <main className="grid min-h-screen place-items-center bg-paper px-6">
      <div className="w-full max-w-md rounded-3xl border border-separator bg-card p-8 text-center">
        <div className="mx-auto mb-5 grid h-14 w-14 place-items-center rounded-2xl bg-fill">
          <Database className="h-6 w-6" />
        </div>
        <h1 className="font-display text-2xl font-bold">Connect Supabase</h1>
        <p className="mt-2 text-[15px] text-muted">
          Add your project URL and publishable key to{" "}
          <code className="rounded bg-fill px-1.5 py-0.5 text-[13px]">
            web/.env.local
          </code>{" "}
          then restart the dev server:
        </p>
        <pre className="mt-4 overflow-x-auto rounded-xl bg-ink p-4 text-left text-[12px] leading-relaxed text-paper">
          {`NEXT_PUBLIC_SUPABASE_URL=...\nNEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=...`}
        </pre>
        <div className="mt-6 flex justify-center">
          <Logo size={22} />
        </div>
      </div>
    </main>
  );
}
