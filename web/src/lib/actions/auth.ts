"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export type AuthState = { error?: string };

/**
 * Agency sign-in. The B2B portal has no self-registration — accounts are
 * provisioned by Nesty, so this only ever signs an existing agency in.
 */
export async function signIn(
  _prev: AuthState,
  formData: FormData,
): Promise<AuthState> {
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");

  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    return { error: "Enter a valid email address." };
  }
  if (password.length < 1) {
    return { error: "Enter your password." };
  }

  const supabase = createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    // Surface the real cause so provisioning issues are easy to diagnose.
    const msg = error.message.toLowerCase();
    if (msg.includes("email not confirmed")) {
      return {
        error:
          "This account exists but its email isn't confirmed. In Supabase → Authentication → Users, open the user and confirm it (or enable Auto Confirm).",
      };
    }
    if (msg.includes("invalid login credentials")) {
      return {
        error:
          "No account matched that email/password. Create the agency user in Supabase (Add user → Auto Confirm) with these exact values.",
      };
    }
    return { error: error.message };
  }

  redirect("/dashboard");
}

export async function signOut() {
  const supabase = createClient();
  await supabase.auth.signOut();
  redirect("/login");
}
