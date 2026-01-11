"use client";

import { useState, useEffect } from "react";
import Link from "next/link";

type Job = {
  id: string;
  originZip: string;
  destinationZip: string;
  moveDate: string | null;
  createdAt: string;
};

export default function JobsPage() {
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    async function loadJobs() {
      try {
        const response = await fetch("/api/jobs", { cache: "no-store" });
        const result = await response.json();
        
        if (result.success) {
          setJobs(result.jobs);
        } else {
          setError("Failed to load jobs");
        }
      } catch (_err) {
        setError("Network error");
      } finally {
        setLoading(false);
      }
    }

    loadJobs();
  }, []);

  return (
    <main style={{ padding: "2rem", fontFamily: "system-ui" }}>
      <div style={{ display: "flex", gap: "1rem", alignItems: "center" }}>
        <h1 style={{ margin: 0 }}>Jobs</h1>
        <Link href="/post-job">Post a job</Link>
        <Link href="/">Home</Link>
      </div>

      <p style={{ marginTop: "0.5rem" }}>Recent job postings.</p>

      {loading && <p>Loading jobs...</p>}
      
      {error && <p style={{ color: "red" }}>{error}</p>}

      {!loading && !error && jobs.length === 0 && (
        <p>No jobs yet. <Link href="/post-job">Post the first one</Link>.</p>
      )}

      {!loading && !error && jobs.length > 0 && (
        <ul style={{ marginTop: "1rem", lineHeight: 1.8, listStyle: "none", padding: 0 }}>
          {jobs.map((job) => {
            let moveDateLabel = "TBD";
            if (job.moveDate) {
              try {
                moveDateLabel = job.moveDate.split('T')[0];
              } catch {
                moveDateLabel = "TBD";
              }
            }

            return (
              <li key={job.id} style={{ marginBottom: "0.5rem" }}>
                <Link href={`/jobs/${job.id}`} style={{ color: "#0070f3" }}>
                  ZIP {job.originZip} → ZIP {job.destinationZip} (Move: {moveDateLabel})
                </Link>
              </li>
            );
          })}
        </ul>
      )}
    </main>
  );
}
