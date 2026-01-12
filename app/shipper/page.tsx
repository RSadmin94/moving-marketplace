import { auth, clerkClient } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import Link from "next/link";
import { prisma } from "@/lib/prisma";

export default async function ShipperDashboardPage() {
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

  // Fetch shipper's jobs with interest counts
  const jobs = await prisma.job.findMany({
    where: {
      shipperId: userId,
      status: "ACTIVE",
    },
    orderBy: {
      createdAt: "desc",
    },
    select: {
      id: true,
      originZip: true,
      destinationZip: true,
      moveDate: true,
      createdAt: true,
      _count: {
        select: {
          interests: true,
        },
      },
    },
  });

  return (
    <main style={{ padding: "2rem", fontFamily: "system-ui", maxWidth: "1200px", margin: "0 auto" }}>
      <div style={{ display: "flex", gap: "1rem", alignItems: "center", marginBottom: "2rem" }}>
        <h1 style={{ margin: 0 }}>Shipper Dashboard</h1>
        <Link href="/" style={{ color: "#0070f3" }}>Home</Link>
        <Link href="/jobs" style={{ color: "#0070f3" }}>All Jobs</Link>
        <Link href="/post-job" style={{ color: "#0070f3" }}>Post a Job</Link>
      </div>

      <h2 style={{ marginTop: "2rem", marginBottom: "1rem" }}>Your Posted Jobs</h2>

      {jobs.length === 0 ? (
        <div style={{ 
          padding: "2rem", 
          backgroundColor: "#f5f5f5", 
          borderRadius: "8px",
          textAlign: "center" 
        }}>
          <p style={{ margin: "0 0 1rem 0" }}>You haven&apos;t posted any jobs yet.</p>
          <Link 
            href="/post-job" 
            style={{ 
              color: "#0070f3",
              fontWeight: "bold"
            }}
          >
            Post your first job →
          </Link>
        </div>
      ) : (
        <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
          {jobs.map((job) => {
            const interestCount = job._count.interests;
            let moveDateLabel = "TBD";
            if (job.moveDate) {
              try {
                moveDateLabel = new Date(job.moveDate).toISOString().split('T')[0];
              } catch {
                moveDateLabel = "TBD";
              }
            }

            return (
              <div
                key={job.id}
                style={{
                  padding: "1.5rem",
                  backgroundColor: "#fff",
                  border: "1px solid #e0e0e0",
                  borderRadius: "8px",
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                }}
              >
                <div>
                  <div style={{ fontSize: "1.125rem", fontWeight: "bold", marginBottom: "0.5rem" }}>
                    ZIP {job.originZip} → ZIP {job.destinationZip}
                  </div>
                  <div style={{ fontSize: "0.875rem", color: "#666" }}>
                    Move Date: {moveDateLabel}
                  </div>
                  <div style={{ fontSize: "0.875rem", color: "#666", marginTop: "0.25rem" }}>
                    Posted: {new Date(job.createdAt).toLocaleDateString()}
                  </div>
                </div>

                <div style={{ display: "flex", alignItems: "center", gap: "1.5rem" }}>
                  <div style={{ textAlign: "center" }}>
                    <div style={{ 
                      fontSize: "2rem", 
                      fontWeight: "bold", 
                      color: interestCount > 0 ? "#0070f3" : "#999" 
                    }}>
                      {interestCount}
                    </div>
                    <div style={{ fontSize: "0.875rem", color: "#666" }}>
                      {interestCount === 1 ? "Interest" : "Interests"}
                    </div>
                  </div>

                  <Link
                    href={`/shipper/jobs/${job.id}`}
                    style={{
                      padding: "0.5rem 1rem",
                      backgroundColor: "#0070f3",
                      color: "white",
                      borderRadius: "4px",
                      textDecoration: "none",
                      fontSize: "0.875rem",
                      fontWeight: "bold",
                    }}
                  >
                    View Details →
                  </Link>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </main>
  );
}
