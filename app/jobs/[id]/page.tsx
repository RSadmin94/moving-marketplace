import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import Link from "next/link";

export default async function JobDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const job = await prisma.job.findUnique({
    where: { id: params.id }
  });

  if (!job) {
    notFound();
  }

  return (
    <div style={{ maxWidth: 800, margin: "2rem auto", padding: "0 1rem" }}>
      <div style={{ marginBottom: "1rem" }}>
        <Link href="/" style={{ color: "#0070f3" }}>← Back to home</Link>
      </div>

      <div style={{
        backgroundColor: "#f9f9f9",
        padding: "1.5rem",
        borderRadius: 8,
        border: "1px solid #e0e0e0"
      }}>
        <h1 style={{ marginTop: 0 }}>Moving Job</h1>
        
        <div style={{ 
          display: "grid", 
          gap: "1rem",
          marginBottom: "1.5rem"
        }}>
          <div>
            <strong>Status:</strong>{" "}
            <span style={{
              padding: "0.25rem 0.5rem",
              backgroundColor: "#e0f7e0",
              color: "#0a6b0a",
              borderRadius: 4,
              fontSize: "0.875rem"
            }}>
              {job.status}
            </span>
          </div>

          <div>
            <strong>Origin:</strong> ZIP {job.originZip}
          </div>

          <div>
            <strong>Destination:</strong> ZIP {job.destinationZip}
          </div>

          <div>
            <strong>Move Date:</strong>{" "}
            {new Date(job.moveDate).toLocaleDateString()}
          </div>

          {job.specialItems && (
            <div>
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
            paddingTop: "1rem"
          }}>
            <div>Job ID: {job.id}</div>
            <div>Posted: {new Date(job.createdAt).toLocaleString()}</div>
          </div>
        </div>

        <div style={{
          padding: "1rem",
          backgroundColor: "#fff9e6",
          border: "1px solid #ffe066",
          borderRadius: 4
        }}>
          ✅ Job successfully created and saved to database
        </div>
      </div>
    </div>
  );
}
