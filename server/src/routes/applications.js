import { Router } from "express";
import { getSupabase, isConfigured as isSupabaseConfigured } from "../lib/supabaseClient.js";

const router = Router();

const STATUSES = ["saved", "drafting", "ready", "applied", "interviewing", "offer", "rejected"];

router.get("/", async (req, res) => {
  if (!isSupabaseConfigured()) return res.status(503).json({ error: "Supabase is not configured on the server." });
  const { deviceId } = req.query;
  if (!deviceId) return res.status(400).json({ error: "deviceId query param is required." });

  try {
    const { data, error } = await getSupabase()
      .from("applications")
      .select("*, job:jobs(*)")
      .eq("device_id", deviceId)
      .order("updated_at", { ascending: false });
    if (error) throw new Error(error.message);
    res.json({ applications: data || [] });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

router.post("/", async (req, res) => {
  if (!isSupabaseConfigured()) return res.status(503).json({ error: "Supabase is not configured on the server." });
  const { deviceId, jobId, status } = req.body ?? {};
  if (!deviceId || !jobId) return res.status(400).json({ error: "deviceId and jobId are required." });
  if (status && !STATUSES.includes(status)) return res.status(400).json({ error: `status must be one of: ${STATUSES.join(", ")}` });

  try {
    const { data, error } = await getSupabase()
      .from("applications")
      .upsert(
        { device_id: deviceId, job_id: jobId, ...(status ? { status } : {}) },
        { onConflict: "device_id,job_id", ignoreDuplicates: false }
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
  const { deviceId, status } = req.body ?? {};
  if (!deviceId || !status) return res.status(400).json({ error: "deviceId and status are required." });
  if (!STATUSES.includes(status)) return res.status(400).json({ error: `status must be one of: ${STATUSES.join(", ")}` });

  try {
    const patch = { status, ...(status === "applied" ? { applied_at: new Date().toISOString() } : {}) };
    const { data, error } = await getSupabase()
      .from("applications")
      .update(patch)
      .eq("id", id)
      .eq("device_id", deviceId)
      .select("*, job:jobs(*)")
      .maybeSingle();
    if (error) throw new Error(error.message);
    if (!data) return res.status(404).json({ error: "Application not found for this device." });
    res.json({ application: data });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

export default router;
