import Link from "next/link";
import { auth, clerkClient } from "@clerk/nextjs/server";
import { prisma } from "@/lib/prisma";
import ExpressInterestButton from "./ExpressInterestButton";

// Force dynamic rendering
export const dynamic = 'force-dynamic';

type Job = {
  id: string;
  originZip: string;
  destinationZip: string;
  moveDate: Date | null;
  specialItems: string | null;
  createdAt: Date;
  shipperId: string | null;
};

async function fetchJob(id: string): Promise<Job | null> {
  try {
    const job = await prisma.job.findUnique({
      where: { id },
      select: {
        id: true,
        originZip: true,
        destinationZip: true,
        moveDate: true,
        specialItems: true,
        createdAt: true,
        shipperId: true
      }
    });
    
    return job;
  } catch (error) {
    console.error("Failed to fetch job:", error);
    return null;
  }
}

export default async function JobDetailPage({
  params
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const job = await fetchJob(id);
  const { userId } = await auth();

  // Get user role
  let userRole: string | undefined;
  if (userId) {
    const clerk = await clerkClient();
    const user = await clerk.users.getUser(userId);
    userRole = user.publicMetadata.role as string | undefined;
  }

  if (!job) {
    return (
      <main style={{ padding: "2rem", fontFamily: "system-ui" }}>
        <h1>Job not found</h1>
        <p>This job does not exist or was removed.</p>
        <p><Link href="/jobs" style={{ color: "#0070f3" }}>Back to jobs</Link></p>
      </main>
    );
  }

  // Safe date formatting
  let moveDateLabel = "TBD";
  if (job.moveDate) {
    try {
      const date = new Date(job.moveDate);
      moveDateLabel = date.toISOString().split('T')[0];
    } catch {
      moveDateLabel = "TBD";
    }
  }

  return (
    <main style={{ padding: "2rem", fontFamily: "system-ui" }}>
      <div style={{ display: "flex", gap: "1rem", alignItems: "center", marginBottom: "1rem" }}>
        <h1 style={{ margin: 0 }}>Job {job.id.slice(0, 8)}</h1>
        <Link href="/jobs" style={{ color: "#0070f3" }}>Back to jobs</Link>
        <Link href="/" style={{ color: "#0070f3" }}>Home</Link>
      </div>

      <div style={{
        backgroundColor: "#f9f9f9",
        padding: "1.5rem",
        borderRadius: 8,
        border: "1px solid #e0e0e0"
      }}>
        <div style={{ lineHeight: 1.8 }}>
          <div><strong>Origin ZIP:</strong> {job.originZip}</div>
          <div><strong>Destination ZIP:</strong> {job.destinationZip}</div>
          <div><strong>Move Date:</strong> {moveDateLabel}</div>

          {job.specialItems && (
            <div style={{ marginTop: "1rem" }}>
              <strong>Description:</strong>
              <p style={{ 
                marginTop: "0.5rem",
                padding: "0.75rem",
                backgroundColor: "white",
                borderRadius: 4,
                border: "1px solid #e0e0e0"
              }}>
                {job.specialItems}
              </p>
            </div>
          )}

          <div style={{ 
            fontSize: "0.875rem",
            color: "#666",
            borderTop: "1px solid #e0e0e0",
            paddingTop: "1rem",
            marginTop: "1rem"
          }}>
            <div>Job ID: {job.id}</div>
            <div>Posted: {new Date(job.createdAt).toISOString()}</div>
          </div>
        </div>

        {/* Show Express Interest ONLY for MOVERs */}
        {userRole === "MOVER" && <ExpressInterestButton jobId={job.id} />}
        
        {/* Show shipper dashboard link if user is a SHIPPER and owns this job */}
        {userRole === "SHIPPER" && userId === job.shipperId && (
          <div style={{ marginTop: "1.5rem" }}>
            <Link
              href="/shipper"
              style={{
                display: "inline-block",
                padding: "0.75rem 1.5rem",
                backgroundColor: "#0070f3",
                color: "white",
                borderRadius: "6px",
                textDecoration: "none",
                fontWeight: "bold"
              }}
            >
              View Your Dashboard →
            </Link>
          </div>
        )}
      </div>
    </main>
  );
}
