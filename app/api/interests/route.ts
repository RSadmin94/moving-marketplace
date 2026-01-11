import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { prisma } from "@/lib/prisma";

export async function POST(request: NextRequest) {
  try {
    const { userId } = await auth();
    
    if (!userId) {
      return NextResponse.json(
        { success: false, error: "Unauthorized - Please sign in" },
        { status: 401 }
      );
    }

    const body = await request.json();
    const { jobId } = body;

    if (!jobId || typeof jobId !== "string") {
      return NextResponse.json(
        { success: false, error: "Missing or invalid jobId" },
        { status: 400 }
      );
    }

    // Verify job exists and is ACTIVE
    const job = await prisma.job.findUnique({
      where: { id: jobId },
      select: { id: true, status: true }
    });

    if (!job) {
      return NextResponse.json(
        { success: false, error: "Job not found" },
        { status: 404 }
      );
    }

    if (job.status !== "ACTIVE") {
      return NextResponse.json(
        { success: false, error: "Job is not active" },
        { status: 400 }
      );
    }

    // Check if interest already exists
    const existingInterest = await prisma.interest.findUnique({
      where: {
        jobId_userId: {
          jobId: jobId,
          userId: userId
        }
      }
    });

    if (existingInterest) {
      return NextResponse.json({
        success: true,
        alreadyExists: true,
        interestId: existingInterest.id
      });
    }

    // Create interest
    const interest = await prisma.interest.create({
      data: {
        jobId: jobId,
        userId: userId
      }
    });

    return NextResponse.json({
      success: true,
      interestId: interest.id
    });

  } catch (error) {
    console.error("Interest creation error:", error);
    return NextResponse.json(
      { success: false, error: "Failed to create interest" },
      { status: 500 }
    );
  }
}

export async function GET(request: NextRequest) {
  try {
    const { userId } = await auth();
    const { searchParams } = new URL(request.url);
    const jobId = searchParams.get("jobId");

    if (!jobId) {
      return NextResponse.json(
        { success: false, error: "Missing jobId query parameter" },
        { status: 400 }
      );
    }

    // Get count of interests for this job
    const count = await prisma.interest.count({
      where: { jobId: jobId }
    });

    // Check if current user is interested (if signed in)
    let isInterested = false;
    if (userId) {
      const userInterest = await prisma.interest.findUnique({
        where: {
          jobId_userId: {
            jobId: jobId,
            userId: userId
          }
        }
      });
      isInterested = !!userInterest;
    }

    return NextResponse.json({
      success: true,
      count,
      isInterested
    });

  } catch (error) {
    console.error("Interest fetch error:", error);
    return NextResponse.json(
      { success: false, error: "Failed to fetch interests" },
      { status: 500 }
    );
  }
}

