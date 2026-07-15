import { Router } from "express";
import multer from "multer";
import { extractText } from "../lib/parseFile.js";
import { analyzeResume, isConfigured } from "../groqClient.js";

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });
const router = Router();

router.post("/parse", upload.single("file"), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: "No file uploaded. Send it as multipart field 'file'." });
  }
  try {
    const text = await extractText({
      buffer: req.file.buffer,
      mimeType: req.file.mimetype,
      fileName: req.file.originalname,
    });
    if (!text) {
      return res.status(422).json({ error: "Could not extract any text from that file." });
    }
    res.json({ text, fileName: req.file.originalname });
  } catch (err) {
    res.status(422).json({ error: err.message });
  }
});

// Groq has no schema-enforcement parameter (unlike Anthropic's structured
// output) — the expected JSON shape is taught via a concrete example
// embedded in the system prompt instead of a schema object.
const SCAN_SHAPE_EXAMPLE = `{
  "atsScore": 82,
  "parserBreakdown": [
    {"parser": "Greenhouse-style", "score": 80},
    {"parser": "Workday-style", "score": 78},
    {"parser": "Generic keyword-match ATS", "score": 88}
  ],
  "matchedKeywords": ["stakeholder management", "roadmapping"],
  "missingKeywords": ["SQL", "A/B testing"],
  "questions": ["Plain-language question 1", "Plain-language question 2"]
}`;

router.post("/scan", async (req, res) => {
  if (!isConfigured()) {
    return res.status(503).json({ error: "GROQ_API_KEY is not set on the server." });
  }
  const { resumeText, targetRole } = req.body ?? {};
  if (!resumeText || !targetRole) {
    return res.status(400).json({ error: "resumeText and targetRole are required." });
  }
  try {
    const result = await analyzeResume({
      system:
        `You are Aura, the ATS-simulation engine inside AURA MATCH. You read a resume the way real applicant-tracking systems parse and rank it, then report exactly what a candidate needs to fix. Be specific and honest — never inflate the score. Missing keywords must be genuinely relevant to the target role, not generic buzzwords. Every question you propose must ask about something the candidate could plausibly already know from their own work history — never invent claims for them.\n\nRespond with JSON only, matching exactly this shape:\n${SCAN_SHAPE_EXAMPLE}`,
      prompt: `Target role: ${targetRole}\n\nResume:\n${resumeText}`,
    });
    res.json(result);
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

const REBUILD_SHAPE_EXAMPLE = `{"rebuiltResume": "the full rewritten resume as clean plain text"}`;

router.post("/rebuild", async (req, res) => {
  if (!isConfigured()) {
    return res.status(503).json({ error: "GROQ_API_KEY is not set on the server." });
  }
  const { resumeText, targetRole, qaAnswers } = req.body ?? {};
  if (!resumeText || !targetRole) {
    return res.status(400).json({ error: "resumeText and targetRole are required." });
  }
  try {
    const answersBlock = (qaAnswers || [])
      .map((qa, i) => `Q${i + 1}: ${qa.question}\nA${i + 1}: ${qa.answer}`)
      .join("\n\n");
    const result = await analyzeResume({
      system:
        `You are Aura, resume-rewriting engine inside AURA MATCH. Rebuild the candidate's resume so it is ATS-safe and tailored to the target role, using only facts already present in the original resume or in the candidate's answers below. Never invent employers, titles, dates, or metrics. Keep it to one page's worth of content unless the original clearly needs two.\n\nRespond with JSON only, matching exactly this shape:\n${REBUILD_SHAPE_EXAMPLE}`,
      prompt: `Target role: ${targetRole}\n\nOriginal resume:\n${resumeText}\n\nCandidate's answers to Aura's clarifying questions:\n${answersBlock || "(none provided)"}`,
    });
    res.json(result);
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

export default router;
