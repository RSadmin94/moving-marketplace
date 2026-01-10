"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function PostJobPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setLoading(true);
    setError("");

    const formData = new FormData(e.currentTarget);
    const data = {
      originZip: formData.get("originZip") as string,
      destinationZip: formData.get("destinationZip") as string,
      moveDate: formData.get("moveDate") as string,
      description: formData.get("description") as string,
    };

    try {
      const response = await fetch("/api/jobs", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });

      const result = await response.json();

      if (result.success) {
        router.push(`/jobs/${result.jobId}`);
      } else {
        setError(result.error || "Failed to create job");
        setLoading(false);
      }
    } catch (err) {
      setError("Network error. Please try again.");
      setLoading(false);
    }
  }

  return (
    <div style={{ maxWidth: 600, margin: "2rem auto", padding: "0 1rem" }}>
      <h1>Post a Moving Job</h1>
      
      {error && (
        <div style={{ 
          padding: "1rem", 
          backgroundColor: "#fee", 
          border: "1px solid #fcc",
          borderRadius: 4,
          marginBottom: "1rem"
        }}>
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div style={{ marginBottom: "1rem" }}>
          <label htmlFor="originZip" style={{ display: "block", marginBottom: "0.5rem" }}>
            Origin ZIP Code *
          </label>
          <input
            type="text"
            id="originZip"
            name="originZip"
            required
            pattern="[0-9]{5}"
            placeholder="12345"
            style={{
              width: "100%",
              padding: "0.5rem",
              fontSize: "1rem",
              border: "1px solid #ccc",
              borderRadius: 4
            }}
          />
        </div>

        <div style={{ marginBottom: "1rem" }}>
          <label htmlFor="destinationZip" style={{ display: "block", marginBottom: "0.5rem" }}>
            Destination ZIP Code *
          </label>
          <input
            type="text"
            id="destinationZip"
            name="destinationZip"
            required
            pattern="[0-9]{5}"
            placeholder="67890"
            style={{
              width: "100%",
              padding: "0.5rem",
              fontSize: "1rem",
              border: "1px solid #ccc",
              borderRadius: 4
            }}
          />
        </div>

        <div style={{ marginBottom: "1rem" }}>
          <label htmlFor="moveDate" style={{ display: "block", marginBottom: "0.5rem" }}>
            Move Date *
          </label>
          <input
            type="date"
            id="moveDate"
            name="moveDate"
            required
            min={new Date().toISOString().split('T')[0]}
            style={{
              width: "100%",
              padding: "0.5rem",
              fontSize: "1rem",
              border: "1px solid #ccc",
              borderRadius: 4
            }}
          />
        </div>

        <div style={{ marginBottom: "1rem" }}>
          <label htmlFor="description" style={{ display: "block", marginBottom: "0.5rem" }}>
            Description
          </label>
          <textarea
            id="description"
            name="description"
            rows={4}
            placeholder="Tell us about your move..."
            style={{
              width: "100%",
              padding: "0.5rem",
              fontSize: "1rem",
              border: "1px solid #ccc",
              borderRadius: 4,
              fontFamily: "inherit"
            }}
          />
        </div>

        <button
          type="submit"
          disabled={loading}
          style={{
            width: "100%",
            padding: "0.75rem",
            fontSize: "1rem",
            backgroundColor: loading ? "#ccc" : "#0070f3",
            color: "white",
            border: "none",
            borderRadius: 4,
            cursor: loading ? "not-allowed" : "pointer"
          }}
        >
          {loading ? "Creating..." : "Post Job"}
        </button>
      </form>
    </div>
  );
}
