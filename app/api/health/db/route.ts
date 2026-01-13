// app/api/health/db/route.ts
import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  try {
    // Lightweight connectivity check
    await prisma.$queryRaw`SELECT 1`;

    return NextResponse.json({ ok: true }, { status: 200 });
  } catch (err) {
    // Log only the message (avoid dumping full error object / stack)
    const message =
      err instanceof Error ? err.message : "Unknown database error";
    console.error(`[health/db] ${message}`);

    return NextResponse.json({ ok: false }, { status: 200 });
  }
}
