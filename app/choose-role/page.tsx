import { auth, currentUser } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import RoleSelection from "./RoleSelection";

// Force dynamic rendering
export const dynamic = 'force-dynamic';

export default async function ChooseRolePage() {
  const { userId } = await auth();

  if (!userId) {
    redirect("/sign-in");
  }

  // Get current user to check publicMetadata
  const user = await currentUser();

  if (!user) {
    redirect("/sign-in");
  }

  // Check if user already has a role
  const role = user.publicMetadata?.role as string | undefined;

  if (role === "MOVER") {
    redirect("/mover");
  }

  if (role === "SHIPPER") {
    redirect("/post-job");
  }

  // User doesn't have a role yet, show selection
  return (
    <main style={{ padding: "2rem", fontFamily: "system-ui" }}>
      <RoleSelection />
    </main>
  );
}


