import { Router } from "express";
import { isConfigured as isSupabaseConfigured } from "../lib/supabaseClient.js";
import { requireAuth } from "../middleware/requireAuth.js";

const router = Router();
router.use(requireAuth);

router.get("/", async (req, res) => {
  if (!isSupabaseConfigured()) return res.status(503).json({ error: "Supabase is not configured on the server." });
  try {
    const { data, error } = await req.supabase
      .from("resumes")
      .select("id, file_name, target_role, ats_score, created_at, updated_at")
      .order("updated_at", { ascending: false });
    if (error) throw new Error(error.message);
    res.json({ resumes: data || [] });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

router.get("/:id", async (req, res) => {
  if (!isSupabaseConfigured()) return res.status(503).json({ error: "Supabase is not configured on the server." });
  try {
    const { data, error } = await req.supabase.from("resumes").select("*").eq("id", req.params.id).maybeSingle();
    if (error) throw new Error(error.message);
    if (!data) return res.status(404).json({ error: "Resume not found." });
    res.json({ resume: data });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

router.post("/", async (req, res) => {
  if (!isSupabaseConfigured()) return res.status(503).json({ error: "Supabase is not configured on the server." });
  const { fileName, resumeText, targetRole, atsScore } = req.body ?? {};
  if (!fileName || !resumeText || !targetRole) {
    return res.status(400).json({ error: "fileName, resumeText, and targetRole are required." });
  }
  try {
    const { data, error } = await req.supabase
      .from("resumes")
      .insert({
        user_id: req.userId,
        file_name: fileName,
        resume_text: resumeText,
        target_role: targetRole,
        ats_score: typeof atsScore === "number" ? atsScore : null,
      })
      .select("id, file_name, target_role, ats_score, created_at, updated_at")
      .single();
    if (error) throw new Error(error.message);
    res.json({ resume: data });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

router.delete("/:id", async (req, res) => {
  if (!isSupabaseConfigured()) return res.status(503).json({ error: "Supabase is not configured on the server." });
  try {
    const { error } = await req.supabase.from("resumes").delete().eq("id", req.params.id);
    if (error) throw new Error(error.message);
    res.json({ ok: true });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

export default router;
