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

    let customer;
    const user = await prisma.user.findUnique({
      where: { clerkId: userId },
      include: { customer: true }
    });

    if (!user) {
      return NextResponse.json(
        { success: false, error: "User account not found" },
        { status: 404 }
      );
    }

    if (!user.customer) {
      customer = await prisma.customer.create({
        data: { userId: user.id }
      });
    } else {
      customer = user.customer;
    }

    const body = await request.json();
    const { originZip, destinationZip, moveDate, description } = body;

    // Validate required fields
    if (!originZip || !destinationZip || !moveDate) {
      return NextResponse.json(
        { success: false, error: "Missing required fields: originZip, destinationZip, and moveDate are required" },
        { status: 400 }
      );
    }

    // Validate ZIP format (basic)
    if (!/^\d{5}$/.test(originZip) || !/^\d{5}$/.test(destinationZip)) {
      return NextResponse.json(
        { success: false, error: "Invalid ZIP code format. Must be 5 digits" },
        { status: 400 }
      );
    }

    // Validate moveDate is a valid date
    const moveDateObj = new Date(moveDate);
    if (isNaN(moveDateObj.getTime())) {
      return NextResponse.json(
        { success: false, error: "Invalid move date format" },
        { status: 400 }
      );
    }

    const job = await prisma.job.create({
      data: {
        customerId: customer.id,
        shipperId: userId,
        originAddressFull: `ZIP: ${originZip}`,
        originCity: "",
        originState: "",
        originZip: originZip.trim(),
        originLat: 0,
        originLng: 0,
        destinationAddressFull: `ZIP: ${destinationZip}`,
        destinationCity: "",
        destinationState: "",
        destinationZip: destinationZip.trim(),
        destinationLat: null,
        destinationLng: null,
        moveDate: moveDateObj,
        isFlexibleDate: false,
        specialItems: description?.trim() || null,
        status: "ACTIVE",
        totalVolumeCuft: null,
      }
    });

    return NextResponse.json({
      success: true,
      jobId: job.id
    });

  } catch (error) {
    console.error("Job creation error:", error);
    return NextResponse.json(
      { success: false, error: "Failed to create job" },
      { status: 500 }
    );
  }
}

export async function GET() {
  try {
    const jobs = await prisma.job.findMany({
      where: { status: "ACTIVE" },
      orderBy: { createdAt: "desc" },
      take: 50
    });

    return NextResponse.json({ success: true, jobs });
  } catch (error) {
    console.error("Job fetch error:", error);
    return NextResponse.json(
      { success: false, error: "Failed to fetch jobs" },
      { status: 500 }
    );
  }
}
