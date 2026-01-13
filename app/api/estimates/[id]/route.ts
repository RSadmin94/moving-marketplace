import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { prisma } from "@/lib/prisma";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { userId } = await auth();
    
    if (!userId) {
      return NextResponse.json(
        { ok: false, error: "Unauthorized" },
        { status: 401 }
      );
    }

    const { id } = await params;

    const estimate = await prisma.estimate.findUnique({
      where: { id },
    });

    if (!estimate) {
      return NextResponse.json(
        { ok: false, error: "Estimate not found" },
        { status: 404 }
      );
    }

    // Verify ownership
    if (estimate.shipperId !== userId) {
      return NextResponse.json(
        { ok: false, error: "Forbidden" },
        { status: 403 }
      );
    }

    return NextResponse.json({
      ok: true,
      estimate,
    });

  } catch (error) {
    console.error("Get estimate error:", error);
    return NextResponse.json(
      { ok: false, error: "Failed to fetch estimate" },
      { status: 500 }
    );
  }
}

