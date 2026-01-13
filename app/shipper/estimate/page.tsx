import { auth, clerkClient } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import EstimateForm from "./EstimateForm";

export default async function EstimatePage() {
  const { userId } = await auth();

  // Auth check: Must be signed in
  if (!userId) {
    redirect("/sign-in");
  }

  // Get user and role
  const clerk = await clerkClient();
  const user = await clerk.users.getUser(userId);
  const role = user.publicMetadata.role as string | undefined;

  // Role enforcement
  if (!role) {
    redirect("/choose-role");
  }

  if (role === "MOVER") {
    redirect("/mover");
  }

  if (role !== "SHIPPER") {
    redirect("/");
  }

  return <EstimateForm />;
}
