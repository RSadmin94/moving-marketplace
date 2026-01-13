import { NextRequest, NextResponse } from "next/server";
import { auth, clerkClient } from "@clerk/nextjs/server";
import { prisma } from "@/lib/prisma";
import { estimateInputSchema } from "@/lib/estimateInputSchema";

export async function POST(request: NextRequest) {
  try {
    // Authentication check
    const { userId } = await auth();
    
    if (!userId) {
      return NextResponse.json(
        { ok: false, error: "Unauthorized" },
        { status: 401 }
      );
    }

    // Role check - SHIPPER only
    const clerk = await clerkClient();
    const user = await clerk.users.getUser(userId);
    const role = user.publicMetadata?.role as string | undefined;
    
    if (role !== "SHIPPER") {
      return NextResponse.json(
        { ok: false, error: "SHIPPER role required" },
        { status: 403 }
      );
    }

    // Parse and validate request body
    const body = await request.json().catch(() => {
      throw new Error("Invalid JSON in request body");
    });

    const validationResult = estimateInputSchema.safeParse(body);
    
    if (!validationResult.success) {
      return NextResponse.json(
        { 
          ok: false, 
          error: "Invalid input data",
          details: validationResult.error.issues,
        },
        { status: 400 }
      );
    }

    const { jobId, inputData, photoData, aiResult } = validationResult.data;

    // Persist estimate to database
    const estimate = await prisma.estimate.create({
      data: {
        shipperId: userId,
        jobId: jobId || null,
        inputData,
        photoData,
        aiResult,
      },
    });

    return NextResponse.json({
      ok: true,
      estimate: {
        id: estimate.id,
        shipperId: estimate.shipperId,
        jobId: estimate.jobId,
        inputData: estimate.inputData,
        photoData: estimate.photoData,
        aiResult: estimate.aiResult,
        createdAt: estimate.createdAt,
      },
    });

  } catch (error) {
    console.error("Estimate creation error:", error);
    
    // Graceful error handling - never crash
    if (error instanceof Error) {
      // Handle known errors
      if (error.message.includes("Invalid JSON")) {
        return NextResponse.json(
          { ok: false, error: "Invalid request format" },
          { status: 400 }
        );
      }
      
      if (error.message.includes("Unique constraint")) {
        return NextResponse.json(
          { ok: false, error: "Estimate already exists" },
          { status: 409 }
        );
      }
    }
    
    // Generic error response
    return NextResponse.json(
      { ok: false, error: "Failed to create estimate" },
      { status: 500 }
    );
  }
}

