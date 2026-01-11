import Link from "next/link";
import { auth } from "@clerk/nextjs/server";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";

// Force dynamic rendering
export const dynamic = 'force-dynamic';

type InterestWithJob = {
  id: string;
  createdAt: Date;
  job: {
    id: string;
    originZip: string;
    destinationZip: string;
    moveDate: Date | null;
    createdAt: Date;
  };
};

async function fetchInterests(userId: string): Promise<InterestWithJob[]> {
  try {
    const interests = await prisma.interest.findMany({
      where: { userId },
      include: {
        job: {
          select: {
            id: true,
            originZip: true,
            destinationZip: true,
            moveDate: true,
            createdAt: true
          }
        }
      },
      orderBy: { createdAt: "desc" }
    });
    return interests;
  } catch (error) {
    console.error("Failed to fetch interests:", error);
    return [];
  }
}

export default async function MoverPage() {
  const { userId } = await auth();

  if (!userId) {
    redirect("/sign-in");
  }

  const interests = await fetchInterests(userId);

  // Safe date formatting helper
  function formatDate(date: Date | null): string {
    if (!date) return "TBD";
    try {
      return new Date(date).toISOString().split('T')[0];
    } catch {
      return "TBD";
    }
  }

  return (
    <main style={{ padding: "2rem", fontFamily: "system-ui" }}>
      <div style={{ display: "flex", gap: "1rem", alignItems: "center", marginBottom: "1rem" }}>
        <h1 style={{ margin: 0 }}>Mover Dashboard</h1>
        <Link href="/jobs" style={{ color: "#0070f3" }}>Jobs</Link>
        <Link href="/" style={{ color: "#0070f3" }}>Home</Link>
      </div>

          <p style={{ marginTop: "0.5rem" }}>Jobs you&apos;ve expressed interest in.</p>

      {interests.length === 0 && (
        <div style={{
          marginTop: "2rem",
          padding: "2rem",
          backgroundColor: "#f9f9f9",
          borderRadius: 8,
          border: "1px solid #e0e0e0",
          textAlign: "center"
        }}>
          <p>You haven&apos;t expressed interest in any jobs yet.</p>
          <p><Link href="/jobs" style={{ color: "#0070f3" }}>Browse available jobs</Link></p>
        </div>
      )}

      {interests.length > 0 && (
        <ul style={{ marginTop: "1rem", lineHeight: 1.8, listStyle: "none", padding: 0 }}>
          {interests.map((interest) => {
            const moveDateLabel = formatDate(interest.job.moveDate);
            const createdAtLabel = formatDate(interest.job.createdAt);

            return (
              <li
                key={interest.id}
                style={{
                  marginBottom: "1rem",
                  padding: "1.5rem",
                  backgroundColor: "#f9f9f9",
                  borderRadius: 8,
                  border: "1px solid #e0e0e0"
                }}
              >
                <div style={{ marginBottom: "0.5rem" }}>
                  <Link
                    href={`/jobs/${interest.job.id}`}
                    style={{ color: "#0070f3", fontSize: "1.125rem", fontWeight: "bold" }}
                  >
                    ZIP {interest.job.originZip} → ZIP {interest.job.destinationZip}
                  </Link>
                  </div>
                <div style={{ fontSize: "0.875rem", color: "#666" }}>
                  <div><strong>Move Date:</strong> {moveDateLabel}</div>
                  <div><strong>Job Posted:</strong> {createdAtLabel}</div>
                  <div><strong>Job ID:</strong> {interest.job.id.slice(0, 8)}</div>
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </main>
  );
}

