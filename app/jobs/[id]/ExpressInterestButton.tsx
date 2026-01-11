"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { SignedIn, SignedOut } from "@clerk/nextjs";

interface ExpressInterestButtonProps {
  jobId: string;
}

function ExpressInterestButtonContent({ jobId }: ExpressInterestButtonProps) {
  const [isInterested, setIsInterested] = useState<boolean>(false);
  const [isLoading, setIsLoading] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isChecking, setIsChecking] = useState(true);

  // Check initial interest status
  useEffect(() => {
    async function checkInterest() {
      try {
        const response = await fetch(`/api/interests?jobId=${encodeURIComponent(jobId)}`);
        const data = await response.json();
        if (data.success) {
          setIsInterested(data.isInterested);
        }
      } catch (err) {
        console.error("Failed to check interest status:", err);
      } finally {
        setIsChecking(false);
      }
    }
    checkInterest();
  }, [jobId]);

  async function handleExpressInterest() {
    setIsLoading(true);
    setError(null);
    setShowSuccess(false);

    try {
      const response = await fetch("/api/interests", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ jobId })
      });

      const data = await response.json();

      if (!response.ok || !data.success) {
        if (response.status === 401) {
          window.location.href = `/sign-in?redirect_url=${encodeURIComponent(window.location.pathname)}`;
          return;
        }
        throw new Error(data.error || "Failed to express interest");
      }

      setIsInterested(true);
      setShowSuccess(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to express interest");
    } finally {
      setIsLoading(false);
    }
  }

  if (isChecking) {
    return (
      <div style={{ marginTop: "1.5rem", paddingTop: "1.5rem", borderTop: "1px solid #e0e0e0" }}>
        <button
          disabled
          style={{
            padding: "0.75rem 1.5rem",
            backgroundColor: "#ccc",
            color: "#666",
            border: "none",
            borderRadius: 4,
            fontSize: "1rem",
            cursor: "not-allowed"
          }}
        >
          Loading...
        </button>
      </div>
    );
  }

  if (isInterested) {
    return (
      <div style={{ marginTop: "1.5rem", paddingTop: "1.5rem", borderTop: "1px solid #e0e0e0" }}>
        <button
          disabled
          style={{
            padding: "0.75rem 1.5rem",
            backgroundColor: "#ccc",
            color: "#666",
            border: "none",
            borderRadius: 4,
            fontSize: "1rem",
            cursor: "not-allowed"
          }}
        >
          ✓ Interested
        </button>
        {showSuccess && (
          <div style={{
            marginTop: "0.5rem",
            padding: "0.5rem",
            backgroundColor: "#e0f7e0",
            color: "#0a6b0a",
            borderRadius: 4,
            fontSize: "0.875rem"
          }}>
            Interest expressed successfully!
          </div>
        )}
      </div>
    );
  }

  return (
    <div style={{ marginTop: "1.5rem", paddingTop: "1.5rem", borderTop: "1px solid #e0e0e0" }}>
      {error && (
        <div style={{
          marginBottom: "0.5rem",
          padding: "0.5rem",
          backgroundColor: "#fee",
          color: "#c00",
          borderRadius: 4,
          fontSize: "0.875rem"
        }}>
          {error}
        </div>
      )}
      {showSuccess && (
        <div style={{
          marginBottom: "0.5rem",
          padding: "0.5rem",
          backgroundColor: "#e0f7e0",
          color: "#0a6b0a",
          borderRadius: 4,
          fontSize: "0.875rem"
        }}>
          Interest expressed successfully!
        </div>
      )}
      <button
        onClick={handleExpressInterest}
        disabled={isLoading}
        style={{
          padding: "0.75rem 1.5rem",
          backgroundColor: isLoading ? "#ccc" : "#0070f3",
          color: "white",
          border: "none",
          borderRadius: 4,
          fontSize: "1rem",
          cursor: isLoading ? "not-allowed" : "pointer"
        }}
      >
        {isLoading ? "Processing..." : "Express Interest"}
      </button>
    </div>
  );
}

export default function ExpressInterestButton({ jobId }: ExpressInterestButtonProps) {
  return (
    <>
      <SignedIn>
        <ExpressInterestButtonContent jobId={jobId} />
      </SignedIn>
      <SignedOut>
        <div style={{ marginTop: "1.5rem", paddingTop: "1.5rem", borderTop: "1px solid #e0e0e0" }}>
          <Link
            href={`/sign-in?redirect_url=${encodeURIComponent(`/jobs/${jobId}`)}`}
            style={{
              display: "inline-block",
              padding: "0.75rem 1.5rem",
              backgroundColor: "#0070f3",
              color: "white",
              textDecoration: "none",
              borderRadius: 4,
              fontSize: "1rem"
            }}
          >
            Sign in to Express Interest
          </Link>
        </div>
      </SignedOut>
    </>
  );
}

