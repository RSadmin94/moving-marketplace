import { auth, clerkClient } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import PostJobForm from "./PostJobForm";

// Force dynamic rendering
export const dynamic = 'force-dynamic';

export default async function PostJobPage() {
  const { userId } = await auth();

  if (!userId) {
    redirect("/sign-in");
  }

  // Check user role - SHIPPER required for this page
  const client = await clerkClient();
  const user = await client.users.getUser(userId);
  const role = user.publicMetadata?.role as string | undefined;

  if (!role) {
    redirect("/choose-role");
  }

  if (role !== "SHIPPER") {
    // If role is MOVER, redirect to /mover
    redirect("/mover");
  }

  // User has SHIPPER role, render the form
  return <PostJobForm />;
}
