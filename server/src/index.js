import "dotenv/config";
import express from "express";
import cors from "cors";
import resumeRoutes from "./routes/resume.js";
import hiringManagerRoutes from "./routes/hiringManager.js";
import { isConfigured } from "./groqClient.js";

const app = express();
const port = process.env.PORT || 8787;

app.use(cors());
app.use(express.json({ limit: "2mb" }));

app.get("/api/health", (_req, res) => {
  res.json({ ok: true, aiConfigured: isConfigured() });
});

app.use("/api/resume", resumeRoutes);
app.use("/api/hiring-manager", hiringManagerRoutes);

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: "Unexpected server error." });
});

app.listen(port, () => {
  if (!isConfigured()) {
    console.warn(
      "\n⚠️  GROQ_API_KEY is not set. Copy .env.example to .env and add your key — AI endpoints will return 503 until then.\n"
    );
  }
  console.log(`AURA MATCH server listening on http://localhost:${port}`);
});
