import { NextRequest, NextResponse } from "next/server";
import { auth, clerkClient } from "@clerk/nextjs/server";
import { prisma } from "@/lib/prisma";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
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

    // Get estimate ID from params
    const { id } = await params;

    if (!id || typeof id !== "string") {
      return NextResponse.json(
        { ok: false, error: "Invalid estimate ID" },
        { status: 400 }
      );
    }

    // Fetch estimate from database
    const estimate = await prisma.estimate.findUnique({
      where: { id },
    });

    if (!estimate) {
      return NextResponse.json(
        { ok: false, error: "Estimate not found" },
        { status: 404 }
      );
    }

    // Verify ownership - only the shipper who created it can access it
    if (estimate.shipperId !== userId) {
      return NextResponse.json(
        { ok: false, error: "Forbidden - Estimate belongs to another shipper" },
        { status: 403 }
      );
    }

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
    console.error("Get estimate error:", error);
    
    // Graceful error handling - never crash
    return NextResponse.json(
      { ok: false, error: "Failed to fetch estimate" },
      { status: 500 }
    );
  }
}

