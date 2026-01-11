import { NextRequest, NextResponse } from "next/server";
import { auth, clerkClient } from "@clerk/nextjs/server";

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
    const { role } = body;

    if (!role || (role !== "MOVER" && role !== "SHIPPER")) {
      return NextResponse.json(
        { success: false, error: "Invalid role. Must be MOVER or SHIPPER" },
        { status: 400 }
      );
    }

    // Update user's publicMetadata with role
    const client = await clerkClient();
    await client.users.updateUser(userId, {
      publicMetadata: {
        role: role
      }
    });

    return NextResponse.json({
      success: true,
      role: role
    });

  } catch (error) {
    console.error("Role update error:", error);
    return NextResponse.json(
      { success: false, error: "Failed to update role" },
      { status: 500 }
    );
  }
}

