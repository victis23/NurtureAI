import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

admin.initializeApp();

const openaiApiKey = defineSecret("OPENAI_API_KEY");

interface AskAIData {
  query: string;
  systemPrompt: string;
}

interface OpenAIResponse {
  choices: Array<{
    message: {
      content: string;
    };
  }>;
}

export const askAI = onCall(
  {
    secrets: [openaiApiKey],
    timeoutSeconds: 60,
    region: "us-central1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }

    const { query, systemPrompt } = request.data as AskAIData;

    if (!query || typeof query !== "string" || query.trim().length === 0) {
      throw new HttpsError("invalid-argument", "query is required.");
    }

    if (!systemPrompt || typeof systemPrompt !== "string") {
      throw new HttpsError("invalid-argument", "systemPrompt is required.");
    }

    const apiKey = openaiApiKey.value();

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: query },
        ],
        temperature: 0.3,
        response_format: { type: "json_object" },
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      console.error("OpenAI error", response.status, body);
      throw new HttpsError("internal", `OpenAI returned ${response.status}.`);
    }

    const data = (await response.json()) as OpenAIResponse;
    const responseJSON = data.choices?.[0]?.message?.content;

    if (!responseJSON) {
      throw new HttpsError("internal", "Empty response from OpenAI.");
    }

    return { responseJSON };
  }
);
