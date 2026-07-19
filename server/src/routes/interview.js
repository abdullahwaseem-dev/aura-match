import { Router } from "express";
import { analyzeResume, isConfigured } from "../groqClient.js";

const router = Router();

const QUESTIONS_SHAPE_EXAMPLE = `{
  "questions": [
    "A behavioral question grounded in the candidate's actual experience",
    "A role-specific technical or judgement question for the target role",
    "A question probing a gap or stretch area",
    "A question about impact or metrics",
    "A closing 'why this role' style question"
  ]
}`;

router.post("/start", async (req, res) => {
  if (!isConfigured()) return res.status(503).json({ error: "GROQ_API_KEY is not set on the server." });
  const { resumeText, targetRole } = req.body ?? {};
  if (!resumeText || !targetRole) {
    return res.status(400).json({ error: "resumeText and targetRole are required." });
  }
  try {
    const result = await analyzeResume({
      system:
        `You are Aura in Interview Simulator mode inside AURA MATCH. Generate exactly 5 interview questions a real hiring manager would ask this candidate for the target role. Ground them in the candidate's actual resume — reference their real projects, employers, or skills where useful — and mix behavioral, role-specific, and stretch questions. Questions must be answerable by this specific person; never assume facts not in the resume. Ask one clear question at a time, no multi-part compound questions.\n\nRespond with JSON only, matching exactly this shape:\n${QUESTIONS_SHAPE_EXAMPLE}`,
      prompt: `Target role: ${targetRole}\n\nResume:\n${resumeText.slice(0, 6000)}`,
    });
    const questions = Array.isArray(result?.questions) ? result.questions.filter((q) => typeof q === "string").slice(0, 5) : [];
    if (questions.length === 0) return res.status(502).json({ error: "Could not generate interview questions." });
    res.json({ questions });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

const EVAL_SHAPE_EXAMPLE = `{
  "overallScore": 74,
  "categories": [
    {"name": "Relevance", "score": 78},
    {"name": "Specificity", "score": 70},
    {"name": "Structure", "score": 72},
    {"name": "Confidence", "score": 76}
  ],
  "strengths": ["short, specific strength grounded in what they actually said"],
  "improvements": ["short, specific, actionable improvement"],
  "verdict": "one-line overall interview-readiness verdict"
}`;

router.post("/evaluate", async (req, res) => {
  if (!isConfigured()) return res.status(503).json({ error: "GROQ_API_KEY is not set on the server." });
  const { resumeText, targetRole, answers } = req.body ?? {};
  if (!resumeText || !targetRole || !Array.isArray(answers) || answers.length === 0) {
    return res.status(400).json({ error: "resumeText, targetRole, and a non-empty answers array are required." });
  }
  try {
    const transcript = answers
      .map((a, i) => `Q${i + 1}: ${a.question}\nA${i + 1}: ${a.answer}`)
      .join("\n\n");
    const result = await analyzeResume({
      system:
        `You are Aura in Interview Simulator mode inside AURA MATCH, evaluating a mock interview for the target role. Score the candidate honestly on how they actually answered — relevance to the question, specificity/evidence, structure (e.g. STAR), and confidence/clarity. Be encouraging but real: weak, vague, or evasive answers score low. Categories must be exactly Relevance, Specificity, Structure, and Confidence, in that order. Strengths and improvements must reference what the candidate genuinely said, not generic advice.\n\nRespond with JSON only, matching exactly this shape:\n${EVAL_SHAPE_EXAMPLE}`,
      prompt: `Target role: ${targetRole}\n\nResume (for context):\n${resumeText.slice(0, 3000)}\n\nInterview transcript:\n${transcript}`,
    });
    res.json(result);
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

export default router;
