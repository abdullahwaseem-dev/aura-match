import { getSupabase, getSupabaseForUser } from "../lib/supabaseClient.js";

/**
 * Verifies the caller's Supabase access token (Authorization: Bearer <jwt>)
 * against Supabase's auth server, then attaches:
 *   req.userId   — the verified user's uuid (never trust a client-supplied id)
 *   req.supabase — a Supabase client authenticated AS that user, so RLS
 *                  (auth.uid() = user_id) is enforced natively by Postgres.
 * Responds 401 if the header is missing or the token is invalid/expired.
 */
export async function requireAuth(req, res, next) {
  const header = req.headers.authorization ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: "Sign in required." });

  try {
    const { data, error } = await getSupabase().auth.getUser(token);
    if (error || !data?.user) return res.status(401).json({ error: "Your session has expired — please sign in again." });
    req.userId = data.user.id;
    req.supabase = getSupabaseForUser(token);
    next();
  } catch (err) {
    res.status(401).json({ error: "Could not verify your session." });
  }
}
