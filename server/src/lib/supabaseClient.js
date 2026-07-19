import { createClient } from "@supabase/supabase-js";

let anonClient = null;

export function isConfigured() {
  return Boolean(process.env.SUPABASE_URL && process.env.SUPABASE_ANON_KEY);
}

// Base client, authenticated as anon — used only to verify a user's JWT
// (auth.getUser) and for the shared, non-user-scoped `jobs` cache table.
export function getSupabase() {
  if (!anonClient) {
    anonClient = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY, {
      auth: { persistSession: false },
    });
  }
  return anonClient;
}

// Per-request client authenticated as the calling user (their verified JWT
// forwarded as the Authorization header). PostgREST verifies the JWT itself
// and sets auth.uid() accordingly, so RLS policies like
// `using (auth.uid() = user_id)` are enforced natively by Postgres — not by
// application code remembering to filter every query.
export function getSupabaseForUser(accessToken) {
  return createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY, {
    auth: { persistSession: false },
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
  });
}
