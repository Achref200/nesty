import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { isSupabaseConfigured } from "@/lib/supabase/env";

/**
 * Waitlist capture. Persists the email to the `waitlist` table via Supabase
 * (RLS allows anonymous inserts). A duplicate email is treated as success.
 */
export async function POST(request: Request) {
  let email = "";
  try {
    const body = await request.json();
    email = String(body?.email ?? "").trim();
  } catch {
    return NextResponse.json({ error: "Invalid body" }, { status: 400 });
  }

  const valid = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
  if (!valid) {
    return NextResponse.json({ error: "Invalid email" }, { status: 422 });
  }

  if (!isSupabaseConfigured) {
    // No backend yet — acknowledge so the UI still works in local preview.
    console.info(`[waitlist] (no backend) ${email}`);
    return NextResponse.json({ ok: true });
  }

  const supabase = createClient();
  const { error } = await supabase
    .from("waitlist")
    .insert({ email, source: "landing" });

  // Unique-violation means they already joined — that's still a success.
  if (error && error.code !== "23505") {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
