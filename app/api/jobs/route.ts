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

    if (!originZip || !destinationZip || !moveDate) {
      return NextResponse.json(
        { success: false, error: "Missing required fields" },
        { status: 400 }
      );
    }

    const job = await prisma.job.create({
      data: {
        customerId: customer.id,
        originAddressFull: `ZIP: ${originZip}`,
        originCity: "",
        originState: "",
        originZip: originZip,
        originLat: 0,
        originLng: 0,
        destinationAddressFull: `ZIP: ${destinationZip}`,
        destinationCity: "",
        destinationState: "",
        destinationZip: destinationZip,
        destinationLat: 0,
        destinationLng: 0,
        moveDate: new Date(moveDate),
        isFlexibleDate: false,
        specialItems: description || "",
        status: "ACTIVE",
        totalVolumeCuft: 0,
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
