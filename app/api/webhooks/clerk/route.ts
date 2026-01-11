export const runtime = "nodejs";

import { headers } from "next/headers";
import { Webhook } from "svix";
import { prisma } from "@/lib/prisma";

type ClerkUserCreatedEvent = {
  type: "user.created";
  data: {
    id: string;
    email_addresses: Array<{ email_address: string }>;
  };
};

export async function POST(req: Request) {
  const payload = await req.text();

  const h = await Promise.resolve(headers());

  const svixId = h.get("svix-id");
  const svixTimestamp = h.get("svix-timestamp");
  const svixSignature = h.get("svix-signature");

  if (!svixId || !svixTimestamp || !svixSignature) {
    return new Response("Missing Svix headers", { status: 400 });
  }

  const secret = process.env.CLERK_WEBHOOK_SECRET;
  if (!secret) {
    console.error("Missing CLERK_WEBHOOK_SECRET");
    return new Response("Server misconfigured", { status: 500 });
  }

  const wh = new Webhook(secret);

  let evt: unknown;
  try {
    evt = wh.verify(payload, {
      "svix-id": svixId,
      "svix-timestamp": svixTimestamp,
      "svix-signature": svixSignature,
    });
  } catch (err) {
    console.error("Webhook verification failed:", err);
    return new Response("Invalid signature", { status: 400 });
  }

  // Type guard after verification
  const event = evt as { type?: string; data?: unknown };

  if (event?.type === "user.created") {
    const userEvent = event as ClerkUserCreatedEvent;

    const clerkId = userEvent.data?.id;
    const email = userEvent.data?.email_addresses?.[0]?.email_address;

    if (!clerkId || !email) {
      console.error("Missing clerkId or email in webhook payload", event.data);
      return new Response("Missing clerkId/email", { status: 400 });
    }

    // IDEMPOTENT: safe for Clerk webhook retries
    await prisma.user.upsert({
      where: { clerkId },
      update: { email },
      create: {
        clerkId,
        email,
        role: "CUSTOMER",
      },
    });

    console.log(`User synced to DB: ${email} (${clerkId})`);
  }

  return new Response("OK", { status: 200 });
}

