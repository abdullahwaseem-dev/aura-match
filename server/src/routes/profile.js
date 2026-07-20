import { Router } from "express";
import { isConfigured as isSupabaseConfigured } from "../lib/supabaseClient.js";
import { requireAuth } from "../middleware/requireAuth.js";

const router = Router();
router.use(requireAuth);

router.get("/", async (req, res) => {
  if (!isSupabaseConfigured()) return res.status(503).json({ error: "Supabase is not configured on the server." });
  try {
    const { data, error } = await req.supabase.from("profiles").select("*").eq("user_id", req.userId).maybeSingle();
    if (error) throw new Error(error.message);
    res.json({ profile: data ?? { user_id: req.userId, auto_draft_enabled: false } });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

router.patch("/", async (req, res) => {
  if (!isSupabaseConfigured()) return res.status(503).json({ error: "Supabase is not configured on the server." });
  const { autoDraftEnabled } = req.body ?? {};
  if (typeof autoDraftEnabled !== "boolean") return res.status(400).json({ error: "autoDraftEnabled (boolean) is required." });

  try {
    const { data, error } = await req.supabase
      .from("profiles")
      .upsert({ user_id: req.userId, auto_draft_enabled: autoDraftEnabled }, { onConflict: "user_id" })
      .select("*")
      .single();
    if (error) throw new Error(error.message);
    res.json({ profile: data });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

export default router;
