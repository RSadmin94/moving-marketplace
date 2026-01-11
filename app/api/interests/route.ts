import { NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { prisma } from "@/lib/prisma";

export async function POST(req: Request) {
  const { userId } = await auth();

  if (!userId) {
    return NextResponse.json(
      { success: false, error: "UNAUTHENTICATED" },
      { status: 401 }
    );
  }

  const body = await req.json();
  const { jobId } = body;

  if (!jobId) {
    return NextResponse.json(
      { success: false, error: "JOB_ID_REQUIRED" },
      { status: 400 }
    );
  }

  try {
    const interest = await prisma.interest.create({
      data: {
        jobId,
        userId,
      },
    });

    return NextResponse.json({ success: true, interest });
  } catch (err: unknown) {
    // ✅ Handle unique constraint explicitly
    if (err && typeof err === 'object' && 'code' in err && err.code === "P2002") {
      return NextResponse.json(
        { success: true, alreadyExists: true },
        { status: 200 }
      );
    }

    console.error("Create interest failed:", err);

    return NextResponse.json(
      { success: false, error: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}


