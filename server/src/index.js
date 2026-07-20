import "dotenv/config";
import express from "express";
import cors from "cors";
import multer from "multer";
import resumeRoutes from "./routes/resume.js";
import hiringManagerRoutes from "./routes/hiringManager.js";
import jobsRoutes from "./routes/jobs.js";
import applicationsRoutes from "./routes/applications.js";
import interviewRoutes from "./routes/interview.js";
import profileRoutes from "./routes/profile.js";
import resumesRoutes from "./routes/resumes.js";
import privacyRoutes from "./routes/privacy.js";
import { isConfigured } from "./groqClient.js";
import { isConfigured as isSupabaseConfigured } from "./lib/supabaseClient.js";

const app = express();
const port = process.env.PORT || 8787;

app.use(cors());
app.use(express.json({ limit: "2mb" }));

app.get("/api/health", (_req, res) => {
  res.json({ ok: true, aiConfigured: isConfigured(), dbConfigured: isSupabaseConfigured() });
});

app.use("/api/resume", resumeRoutes);
app.use("/api/hiring-manager", hiringManagerRoutes);
app.use("/api/jobs", jobsRoutes);
app.use("/api/applications", applicationsRoutes);
app.use("/api/interview", interviewRoutes);
app.use("/api/profile", profileRoutes);
app.use("/api/resumes", resumesRoutes);
app.use("/api/privacy", privacyRoutes);

app.use((err, _req, res, _next) => {
  if (err instanceof multer.MulterError) {
    const message = err.code === "LIMIT_FILE_SIZE" ? "That file is too large (10MB max)." : err.message;
    return res.status(413).json({ error: message });
  }
  console.error(err);
  res.status(500).json({ error: "Unexpected server error." });
});

app.listen(port, () => {
  if (!isConfigured()) {
    console.warn(
      "\n⚠️  GROQ_API_KEY is not set. Copy .env.example to .env and add your key — AI endpoints will return 503 until then.\n"
    );
  }
  if (!isSupabaseConfigured()) {
    console.warn("\n⚠️  SUPABASE_URL/SUPABASE_ANON_KEY are not set — Jobs endpoints will return 503 until then.\n");
  }
  console.log(`AURA MATCH server listening on http://localhost:${port}`);
});
