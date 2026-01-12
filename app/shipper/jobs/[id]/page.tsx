import { auth, clerkClient } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import Link from "next/link";
import { prisma } from "@/lib/prisma";

export default async function ShipperJobDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
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

  // Get job ID from params
  const { id } = await params;

  // Fetch job with owner verification
  const job = await prisma.job.findFirst({
    where: {
      id,
      shipperId: userId, // CRITICAL: Only show if shipper owns this job
    },
    select: {
      id: true,
      originZip: true,
      destinationZip: true,
      moveDate: true,
      specialItems: true,
      createdAt: true,
      interests: {
        orderBy: {
          createdAt: "desc",
        },
        select: {
          userId: true,
          createdAt: true,
        },
      },
    },
  });

  // Not found or not owned by this shipper
  if (!job) {
    return (
      <main style={{ padding: "2rem", fontFamily: "system-ui", maxWidth: "800px", margin: "0 auto" }}>
        <h1>Job Not Found</h1>
        <p>This job does not exist or you do not have permission to view it.</p>
        <Link href="/shipper" style={{ color: "#0070f3" }}>
          ← Back to Dashboard
        </Link>
      </main>
    );
  }

  // Format move date
  let moveDateLabel = "TBD";
  if (job.moveDate) {
    try {
      moveDateLabel = new Date(job.moveDate).toISOString().split('T')[0];
    } catch {
      moveDateLabel = "TBD";
    }
  }

  return (
    <main style={{ padding: "2rem", fontFamily: "system-ui", maxWidth: "800px", margin: "0 auto" }}>
      <div style={{ marginBottom: "2rem" }}>
        <Link href="/shipper" style={{ color: "#0070f3", fontSize: "0.875rem" }}>
          ← Back to Dashboard
        </Link>
      </div>

      <h1 style={{ marginBottom: "0.5rem" }}>Job Details</h1>
      <div style={{ fontSize: "0.875rem", color: "#666", marginBottom: "2rem" }}>
        Job ID: {job.id.slice(0, 8)}
      </div>

      {/* Job Summary */}
      <div
        style={{
          padding: "1.5rem",
          backgroundColor: "#f9f9f9",
          border: "1px solid #e0e0e0",
          borderRadius: "8px",
          marginBottom: "2rem",
        }}
      >
        <h2 style={{ marginTop: 0, marginBottom: "1rem", fontSize: "1.25rem" }}>
          Job Summary
        </h2>
        <div style={{ display: "grid", gap: "0.5rem" }}>
          <div>
            <strong>Route:</strong> ZIP {job.originZip} → ZIP {job.destinationZip}
          </div>
          <div>
            <strong>Move Date:</strong> {moveDateLabel}
          </div>
          {job.specialItems && (
            <div>
              <strong>Description:</strong> {job.specialItems}
            </div>
          )}
          <div style={{ fontSize: "0.875rem", color: "#666", marginTop: "0.5rem" }}>
            Posted: {new Date(job.createdAt).toLocaleDateString()}
          </div>
        </div>
      </div>

      {/* Interests */}
      <h2 style={{ marginBottom: "1rem" }}>
        Interested Movers ({job.interests.length})
      </h2>

      {job.interests.length === 0 ? (
        <div
          style={{
            padding: "2rem",
            backgroundColor: "#f5f5f5",
            borderRadius: "8px",
            textAlign: "center",
          }}
        >
          <p style={{ margin: 0, color: "#666" }}>
            No movers have expressed interest in this job yet.
          </p>
        </div>
      ) : (
        <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
          {job.interests.map((interest) => (
            <div
              key={interest.userId}
              style={{
                padding: "1rem",
                backgroundColor: "#fff",
                border: "1px solid #e0e0e0",
                borderRadius: "8px",
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div>
                  <div style={{ fontWeight: "bold", marginBottom: "0.25rem" }}>
                    Mover ID: {interest.userId.slice(0, 12)}...
                  </div>
                  <div style={{ fontSize: "0.875rem", color: "#666" }}>
                    Expressed interest: {new Date(interest.createdAt).toISOString().split('T')[0]}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </main>
  );
}
