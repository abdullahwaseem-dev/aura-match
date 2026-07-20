import { Router } from "express";
import { analyzeResume, isConfigured } from "../groqClient.js";
import { requireAuth } from "../middleware/requireAuth.js";

const router = Router();
router.use(requireAuth);

// Groq has no schema-enforcement parameter — the shape is taught by example.
const SCORE_SHAPE_EXAMPLE = `{
  "overallScore": 78,
  "categories": [
    {"name": "Impact", "score": 80},
    {"name": "Clarity", "score": 74},
    {"name": "Keyword Match", "score": 82},
    {"name": "Formatting", "score": 90}
  ],
  "benchmarkPercentile": 18,
  "feedback": ["Short, direct, line-level note 1", "Short, direct, line-level note 2"]
}`;

router.post("/score", async (req, res) => {
  if (!isConfigured()) {
    return res.status(503).json({ error: "GROQ_API_KEY is not set on the server." });
  }
  const { resumeText, persona } = req.body ?? {};
  if (!resumeText || !persona) {
    return res.status(400).json({ error: "resumeText and persona are required." });
  }
  try {
    const result = await analyzeResume({
      system:
        `You are Aura in AI Hiring Manager Mode, reviewing a resume the way a real hiring manager at a "${persona}" company would in a 7-second first skim. Calibrate your rubric to that persona's actual norms — a US SaaS hiring manager, a UK/EU hiring manager, and an APAC manufacturing hiring manager judge resumes differently, and your scoring should reflect that. Be honest, specific, and a little demanding — a resume that would genuinely get an interview at this kind of company scores high; a mediocre one does not. Categories must be exactly Impact, Clarity, Keyword Match, and Formatting, in that order.\n\nRespond with JSON only, matching exactly this shape:\n${SCORE_SHAPE_EXAMPLE}`,
      prompt: `Persona: ${persona}\n\nResume:\n${resumeText}`,
    });
    res.json(result);
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

export default router;
