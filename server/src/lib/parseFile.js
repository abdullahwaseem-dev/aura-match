import { PDFParse } from "pdf-parse";
import mammoth from "mammoth";

/**
 * Extracts plain text from an uploaded resume file.
 * Supports PDF, DOCX, and plain text.
 */
export async function extractText({ buffer, mimeType, fileName }) {
  const lowerName = (fileName || "").toLowerCase();

  if (mimeType === "application/pdf" || lowerName.endsWith(".pdf")) {
    const parser = new PDFParse({ data: buffer });
    try {
      const result = await parser.getText();
      return result.text.trim();
    } finally {
      await parser.destroy();
    }
  }

  if (
    mimeType === "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ||
    lowerName.endsWith(".docx")
  ) {
    const result = await mammoth.extractRawText({ buffer });
    return result.value.trim();
  }

  if (mimeType?.startsWith("text/") || lowerName.endsWith(".txt")) {
    return buffer.toString("utf-8").trim();
  }

  throw new Error(`Unsupported file type: ${mimeType || fileName}. Upload a PDF, DOCX, or TXT resume.`);
}
