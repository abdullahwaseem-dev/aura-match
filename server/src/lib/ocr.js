import { createWorker } from "tesseract.js";

/**
 * Extracts text from an image (screenshot of a job posting, etc.) via
 * Tesseract OCR. Groq has no vision-capable model on this account (checked
 * live against /openai/v1/models — none available), so this runs fully
 * locally/offline instead of depending on a hosted vision API.
 */
export async function extractTextFromImage(buffer) {
  const worker = await createWorker("eng");
  try {
    const {
      data: { text },
    } = await worker.recognize(buffer);
    return text.trim();
  } finally {
    await worker.terminate();
  }
}
