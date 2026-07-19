import { Router } from "express";
import { isConfigured as isSupabaseConfigured } from "../lib/supabaseClient.js";
import { requireAuth } from "../middleware/requireAuth.js";

const router = Router();
router.use(requireAuth);

const STATUSES = ["saved", "drafting", "ready", "applied", "interviewing", "offer", "rejected"];

router.get("/", async (req, res) => {
  if (!isSupabaseConfigured()) return res.status(503).json({ error: "Supabase is not configured on the server." });

  try {
    const { data, error } = await req.supabase
      .from("applications")
      .select("*, job:jobs(*)")
      .order("updated_at", { ascending: false });
    if (error) throw new Error(error.message);
    res.json({ applications: data || [] });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

router.post("/", async (req, res) => {
  if (!isSupabaseConfigured()) return res.status(503).json({ error: "Supabase is not configured on the server." });
  const { jobId, status } = req.body ?? {};
  if (!jobId) return res.status(400).json({ error: "jobId is required." });
  if (status && !STATUSES.includes(status)) return res.status(400).json({ error: `status must be one of: ${STATUSES.join(", ")}` });

  try {
    const { data, error } = await req.supabase
      .from("applications")
      .upsert(
        { user_id: req.userId, job_id: jobId, ...(status ? { status } : {}) },
        { onConflict: "user_id,job_id", ignoreDuplicates: false }
      )
      .select("*, job:jobs(*)")
      .single();
    if (error) throw new Error(error.message);
    res.json({ application: data });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

router.patch("/:id", async (req, res) => {
  if (!isSupabaseConfigured()) return res.status(503).json({ error: "Supabase is not configured on the server." });
  const { id } = req.params;
  const { status } = req.body ?? {};
  if (!status) return res.status(400).json({ error: "status is required." });
  if (!STATUSES.includes(status)) return res.status(400).json({ error: `status must be one of: ${STATUSES.join(", ")}` });

  try {
    const patch = { status, ...(status === "applied" ? { applied_at: new Date().toISOString() } : {}) };
    const { data, error } = await req.supabase
      .from("applications")
      .update(patch)
      .eq("id", id)
      .select("*, job:jobs(*)")
      .maybeSingle();
    if (error) throw new Error(error.message);
    if (!data) return res.status(404).json({ error: "Application not found." });
    res.json({ application: data });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

export default router;
