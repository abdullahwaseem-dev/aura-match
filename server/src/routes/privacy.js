import { Router } from "express";
import { isConfigured as isSupabaseConfigured } from "../lib/supabaseClient.js";
import { requireAuth } from "../middleware/requireAuth.js";

const router = Router();
router.use(requireAuth);

// Everything this app stores about the caller, scoped entirely by RLS
// (auth.uid() = user_id) — not by anything the client claims.
router.get("/export", async (req, res) => {
  if (!isSupabaseConfigured()) return res.status(503).json({ error: "Supabase is not configured on the server." });
  try {
    const [profile, resumes, applications, jobMatches] = await Promise.all([
      req.supabase.from("profiles").select("*").eq("user_id", req.userId).maybeSingle(),
      req.supabase.from("resumes").select("*"),
      req.supabase.from("applications").select("*, job:jobs(*)"),
      req.supabase.from("job_matches").select("*, job:jobs(*)"),
    ]);
    for (const r of [profile, resumes, applications, jobMatches]) {
      if (r.error) throw new Error(r.error.message);
    }
    res.json({
      exportedAt: new Date().toISOString(),
      userId: req.userId,
      profile: profile.data,
      resumes: resumes.data || [],
      applications: applications.data || [],
      jobMatches: jobMatches.data || [],
    });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

// Deletes every row this app holds for the caller (resumes, applications,
// job matches, profile settings). Cannot remove the login account itself —
// that requires Supabase's service-role key, which this server doesn't
// have; the account and its login remain, just with a clean slate.
router.delete("/data", async (req, res) => {
  if (!isSupabaseConfigured()) return res.status(503).json({ error: "Supabase is not configured on the server." });
  try {
    const results = await Promise.all([
      req.supabase.from("resumes").delete().eq("user_id", req.userId),
      req.supabase.from("applications").delete().eq("user_id", req.userId),
      req.supabase.from("job_matches").delete().eq("user_id", req.userId),
      req.supabase.from("profiles").delete().eq("user_id", req.userId),
    ]);
    for (const r of results) {
      if (r.error) throw new Error(r.error.message);
    }
    res.json({ ok: true });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

export default router;
