import Anthropic from "@anthropic-ai/sdk";

const MODEL = "claude-opus-4-8";

let client = null;

export function isConfigured() {
  return Boolean(process.env.ANTHROPIC_API_KEY);
}

function getClient() {
  if (!client) {
    client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
  }
  return client;
}

/**
 * Runs a single structured-output call against Claude and returns the parsed JSON.
 * `schema` is a JSON Schema object (additionalProperties: false, required fields set).
 */
export async function structuredCall({ system, prompt, schema, maxTokens = 4096 }) {
  const anthropic = getClient();

  const response = await anthropic.messages.create({
    model: MODEL,
    max_tokens: maxTokens,
    thinking: { type: "adaptive" },
    output_config: {
      effort: "medium",
      format: {
        type: "json_schema",
        schema,
      },
    },
    system,
    messages: [{ role: "user", content: prompt }],
  });

  if (response.stop_reason === "refusal") {
    const category = response.stop_details?.category ?? "unknown";
    throw new Error(`Aura declined to process this request (category: ${category}).`);
  }

  const textBlock = response.content.find((block) => block.type === "text");
  if (!textBlock) {
    throw new Error("Aura returned no usable content.");
  }

  return JSON.parse(textBlock.text);
}
