import { createClient } from "@supabase/supabase-js";

let client = null;

export function isConfigured() {
  return Boolean(process.env.SUPABASE_URL && process.env.SUPABASE_ANON_KEY);
}

// The server authenticates with the anon/publishable key (no service-role
// key is provisioned here) — table RLS policies are written to match that
// trust model. See the phase2_jobs_schema migration for details.
export function getSupabase() {
  if (!client) {
    client = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY, {
      auth: { persistSession: false },
    });
  }
  return client;
}
