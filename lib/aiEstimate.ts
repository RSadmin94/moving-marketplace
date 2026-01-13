import OpenAI from "openai";
import { estimateResultSchema, type EstimateResult } from "./estimateSchema";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const SYSTEM_PROMPT = `You are a moving estimate AI. Analyze photos and form data to provide accurate moving estimates.

Return ONLY valid JSON matching this exact schema (no markdown, no code blocks, no explanations, no text outside JSON):
{
  "cubicFeet": number (integer, >= 0),
  "truck": "10ft" | "16ft" | "20ft" | "26ft",
  "movers": 2 | 3 | 4,
  "laborHours": number (>= 0, can be 0.5 increments),
  "packingMaterials": {
    "boxes": number (integer, >= 0, optional),
    "tape": number (integer, >= 0, optional),
    "bubbleWrap": number (integer, >= 0, optional),
    "furniturePads": number (integer, >= 0, optional)
  },
  "confidence": "low" | "medium" | "high",
  "explanationBullets": ["string", ...] (max 5, optional)
}

Important: Return ONLY the JSON object, nothing else.`;

export type EstimateFormData = {
  moveType?: "APT" | "HOUSE" | "OFFICE";
  bedrooms?: number;
  stairs?: boolean;
  elevator?: boolean;
  distanceMiles?: number;
  moveDate?: string;
};

/**
 * Convert image URL to base64 data URL if needed
 * @param url - Image URL (can be data URL or HTTP URL)
 * @returns Base64 data URL
 */
async function convertImageToDataUrl(url: string): Promise<string> {
  // If already a data URL, return as-is
  if (url.startsWith("data:")) {
    return url;
  }

  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to fetch image: ${response.statusText}`);
    }
    const arrayBuffer = await response.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    const base64 = buffer.toString("base64");
    const mimeType = response.headers.get("content-type") || "image/jpeg";
    return `data:${mimeType};base64,${base64}`;
  } catch (error) {
    console.error("Error converting image to data URL:", error);
    throw new Error(`Failed to process image: ${error instanceof Error ? error.message : "Unknown error"}`);
  }
}

/**
 * Generate a moving estimate using OpenAI gpt-4o-mini Vision API
 * @param formData - Form input data (moveType, bedrooms, stairs, etc.)
 * @param photoUrls - Array of photo URLs (base64 data URLs or HTTP URLs)
 * @returns Structured estimate result validated against schema
 */
export async function generateEstimate(
  formData: EstimateFormData,
  photoUrls: string[]
): Promise<EstimateResult> {
  try {
    // Validate inputs
    if (!photoUrls || photoUrls.length === 0) {
      throw new Error("At least one photo is required");
    }

    // Limit to 10 photos (OpenAI Vision API limit)
    const photosToProcess = photoUrls.slice(0, 10);

    // Convert all images to base64 data URLs
    const imageDataUrls = await Promise.all(
      photosToProcess.map((url) => convertImageToDataUrl(url))
    );

    // Prepare form data text
    const formFields = {
      moveType: formData.moveType,
      bedrooms: formData.bedrooms,
      stairs: formData.stairs,
      elevator: formData.elevator,
      distanceMiles: formData.distanceMiles,
      moveDate: formData.moveDate,
    };

    const userMessage = `Form data: ${JSON.stringify(formFields)}. Analyze the ${imageDataUrls.length} provided photos and estimate the moving requirements. Consider:
- Move type and size (apartment/house/office, bedrooms)
- Furniture and items visible in photos
- Distance and complexity (stairs, elevator availability)
- Standard moving industry practices

Return the estimate as JSON matching the required schema.`;

    // Call OpenAI Vision API
    const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
      { role: "system", content: SYSTEM_PROMPT },
      {
        role: "user",
        content: [
          { type: "text", text: userMessage },
          ...imageDataUrls.map((dataUrl) => ({
            type: "image_url" as const,
            image_url: { url: dataUrl },
          })),
        ],
      },
    ];

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages,
      max_tokens: 1000,
      temperature: 0.3,
      response_format: { type: "json_object" },
    });

    const content = completion.choices[0]?.message?.content;
    if (!content) {
      throw new Error("No response from AI");
    }

    // Parse JSON response
    let parsed: unknown;
    try {
      parsed = JSON.parse(content);
    } catch {
      // Try to extract JSON if wrapped in markdown
      let jsonStr = content.trim();
      if (jsonStr.startsWith("```json")) {
        jsonStr = jsonStr.replace(/^```json\n?/, "").replace(/```$/, "").trim();
      } else if (jsonStr.startsWith("```")) {
        jsonStr = jsonStr.replace(/^```\n?/, "").replace(/```$/, "").trim();
      }
      parsed = JSON.parse(jsonStr);
    }

    // Validate with Zod schema
    const validationResult = estimateResultSchema.safeParse(parsed);
    if (!validationResult.success) {
      console.error("AI response validation failed:", validationResult.error);
      throw new Error("AI response does not match required schema");
    }

    return validationResult.data;
  } catch (error) {
    console.error("AI estimate generation error:", error);

    if (error instanceof Error) {
      if (error.message.includes("API key") || error.message.includes("OPENAI_API_KEY")) {
        throw new Error("OpenAI API key not configured");
      }
      if (error.message.includes("rate limit")) {
        throw new Error("OpenAI rate limit exceeded");
      }
      throw error;
    }

    throw new Error("Failed to generate estimate");
  }
}

