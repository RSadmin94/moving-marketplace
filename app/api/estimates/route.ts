import { NextRequest, NextResponse } from "next/server";
import { auth, clerkClient } from "@clerk/nextjs/server";
import { prisma } from "@/lib/prisma";
import OpenAI from "openai";
import { estimateResultSchema, type EstimateResult } from "@/lib/estimateSchema";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const SYSTEM_PROMPT = `You are a moving estimate AI. Analyze photos and form data to provide moving estimates.
Return ONLY valid JSON matching this schema (no markdown, no code blocks, no explanations):
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
}`;

async function fetchAndConvertImage(url: string): Promise<string> {
  if (url.startsWith("data:")) {
    return url;
  }
  
  try {
    const response = await fetch(url);
    if (!response.ok) throw new Error("Failed to fetch image");
    const arrayBuffer = await response.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    const base64 = buffer.toString("base64");
    const mimeType = response.headers.get("content-type") || "image/jpeg";
    return `data:${mimeType};base64,${base64}`;
  } catch (error) {
    console.error("Error fetching image:", error);
    throw error;
  }
}

type FormData = {
  stairs?: boolean | null;
  elevator?: boolean | null;
};

function applyRulesClamp(result: EstimateResult, formData: FormData): EstimateResult {
  const { cubicFeet } = result;
  let { truck, movers, laborHours } = result;

  // Clamp truck size based on cubicFeet thresholds
  if (cubicFeet <= 400) truck = "10ft";
  else if (cubicFeet <= 800) truck = "16ft";
  else if (cubicFeet <= 1200) truck = "20ft";
  else truck = "26ft";

  // Ensure minimum movers/hours based on cubicFeet
  if (cubicFeet > 0 && movers < 2) movers = 2;
  if (cubicFeet > 600 && movers < 3) movers = 3;
  if (cubicFeet > 1200 && movers < 4) movers = 4;

  // Minimum hours based on cubicFeet and movers
  const baseHoursPer100 = 0.5;
  const minHours = Math.max(2, (cubicFeet / 100) * baseHoursPer100 / movers);
  if (laborHours < minHours) laborHours = Math.ceil(minHours * 2) / 2; // Round to 0.5

  // Apply stairs/elevator multipliers
  if (formData.stairs === true && formData.elevator !== true) {
    laborHours = laborHours * 1.15;
  }
  if (formData.stairs === true && formData.elevator === false) {
    laborHours = laborHours * 1.10;
  }
  laborHours = Math.ceil(laborHours * 2) / 2; // Round to 0.5

  return {
    ...result,
    truck,
    movers: movers as 2 | 3 | 4,
    laborHours,
  };
}

export async function POST(request: NextRequest) {
  try {
    const { userId } = await auth();
    
    if (!userId) {
      return NextResponse.json(
        { ok: false, error: "Unauthorized" },
        { status: 401 }
      );
    }

    // Check user role
    const clerk = await clerkClient();
    const user = await clerk.users.getUser(userId);
    const role = user.publicMetadata?.role as string | undefined;
    
    if (role !== "SHIPPER") {
      return NextResponse.json(
        { ok: false, error: "SHIPPER role required" },
        { status: 403 }
      );
    }

    const body = await request.json();
    const { photoUrls, moveType, bedrooms, stairs, elevator, distanceMiles, moveDate, jobId } = body;

    if (!photoUrls || !Array.isArray(photoUrls) || photoUrls.length === 0) {
      return NextResponse.json(
        { ok: false, error: "At least one photo is required" },
        { status: 400 }
      );
    }

    // Verify photos exist (basic check - verify URLs are accessible)
    // In production, verify ownership/access here

    // Convert images to base64 for OpenAI
    const imageDataUrls = await Promise.all(
      photoUrls.slice(0, 10).map((url: string) => fetchAndConvertImage(url))
    );

    // Prepare AI input
    const formFields = {
      moveType,
      bedrooms,
      stairs,
      elevator,
      distanceMiles,
      moveDate,
    };

    const userMessage = `Form data: ${JSON.stringify(formFields)}. Analyze the ${imageDataUrls.length} provided photos and estimate the moving requirements.`;

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
    });

    const content = completion.choices[0]?.message?.content;
    if (!content) {
      throw new Error("No response from AI");
    }

    // Parse JSON response (handle markdown code blocks if present)
    let jsonStr = content.trim();
    if (jsonStr.startsWith("```")) {
      jsonStr = jsonStr.replace(/^```json\n?/, "").replace(/```$/, "").trim();
    } else if (jsonStr.startsWith("```")) {
      jsonStr = jsonStr.replace(/^```\n?/, "").replace(/```$/, "").trim();
    }

    let parsed: unknown;
    try {
      parsed = JSON.parse(jsonStr);
    } catch {
      console.error("Failed to parse AI response:", jsonStr);
      throw new Error("Invalid JSON response from AI");
    }

    // Validate with Zod schema
    const validationResult = estimateResultSchema.safeParse(parsed);
    if (!validationResult.success) {
      console.error("Validation error:", validationResult.error);
      throw new Error("AI response does not match schema");
    }

    let result = validationResult.data;

    // Apply rules clamp layer
    result = applyRulesClamp(result, formFields);

    // Persist to database
    const estimate = await prisma.estimate.create({
      data: {
        shipperId: userId,
        jobId: jobId || null,
        inputData: formFields,
        photoData: photoUrls,
        aiResult: result,
      },
    });

    return NextResponse.json({
      ok: true,
      estimateId: estimate.id,
      result,
    });

  } catch (error) {
    console.error("Estimate error:", error);
    
    if (error instanceof Error && error.message.includes("Unauthorized")) {
      return NextResponse.json(
        { ok: false, error: error.message },
        { status: 401 }
      );
    }
    
    return NextResponse.json(
      { ok: false, error: "Failed to generate estimate" },
      { status: 500 }
    );
  }
}

