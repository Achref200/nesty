"use client";

import { useFormState, useFormStatus } from "react-dom";
import Link from "next/link";
import { AlertCircle, Mail, Lock } from "lucide-react";
import { Logo } from "@/components/brand/logo";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { signIn, type AuthState } from "@/lib/actions/auth";

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <Button type="submit" size="lg" className="w-full" disabled={pending}>
      {pending ? "Signing in…" : "Sign in"}
    </Button>
  );
}

export default function LoginPage() {
  const [state, formAction] = useFormState<AuthState, FormData>(signIn, {});

  return (
    <main className="grid min-h-screen place-items-center bg-paper px-6">
      <div className="w-full max-w-sm">
        <Link href="/" className="mb-8 inline-flex">
          <Logo />
        </Link>

        <h1 className="font-display text-3xl font-extrabold tracking-tight">
          Agency sign-in
        </h1>
        <p className="mt-1.5 text-[15px] text-muted">
          Your Nesty dashboard — listings, visits and reservations in one place.
        </p>

        <form action={formAction} className="mt-6 flex flex-col gap-3">
          <Field icon={Mail}>
            <Input
              name="email"
              type="email"
              placeholder="you@agency.tn"
              autoComplete="email"
              required
            />
          </Field>
          <Field icon={Lock}>
            <Input
              name="password"
              type="password"
              placeholder="Password"
              autoComplete="current-password"
              required
            />
          </Field>

          {state?.error && (
            <p className="flex items-center gap-1.5 text-sm text-danger">
              <AlertCircle className="h-4 w-4 shrink-0" />
              {state.error}
            </p>
          )}

          <div className="mt-1">
            <SubmitButton />
          </div>
        </form>

        <div className="mt-6 rounded-2xl border border-separator bg-card p-4 text-sm text-muted">
          Agency accounts are set up by Nesty — there&rsquo;s no sign-up here.
          Need access?{" "}
          <a href="mailto:hello@nesty.tn" className="font-semibold text-ink">
            Talk to us
          </a>
          .
        </div>

        <p className="mt-5 text-center text-sm text-muted">
          Looking for a home?{" "}
          <span className="font-semibold text-ink">Get the Nesty app.</span>
        </p>
      </div>
    </main>
  );
}

function Field({
  icon: Icon,
  children,
}: {
  icon: typeof Mail;
  children: React.ReactNode;
}) {
  return (
    <div className="relative">
      <Icon className="pointer-events-none absolute left-3.5 top-1/2 h-[18px] w-[18px] -translate-y-1/2 text-muted" />
      <div className="[&_input]:pl-11">{children}</div>
    </div>
  );
}
