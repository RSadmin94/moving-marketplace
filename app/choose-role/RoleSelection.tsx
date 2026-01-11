"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function RoleSelection() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleRoleSelection(role: "MOVER" | "SHIPPER") {
    setLoading(true);
    setError(null);

    try {
      const response = await fetch("/api/user/role", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ role })
      });

      const data = await response.json();

      if (!response.ok || !data.success) {
        throw new Error(data.error || "Failed to update role");
      }

      // Redirect based on role
      if (role === "MOVER") {
        router.push("/mover");
      } else {
        router.push("/post-job");
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to update role");
      setLoading(false);
    }
  }

  return (
    <div style={{
      maxWidth: 600,
      margin: "2rem auto",
      padding: "1.5rem",
      backgroundColor: "#f9f9f9",
      borderRadius: 8,
      border: "1px solid #e0e0e0"
    }}>
      <h1 style={{ marginTop: 0, marginBottom: "1rem" }}>Choose Your Role</h1>
      
      <p style={{ marginBottom: "1.5rem", color: "#666" }}>
        Select how you want to use the moving marketplace:
      </p>

      {error && (
        <div style={{
          marginBottom: "1rem",
          padding: "0.75rem",
          backgroundColor: "#fee",
          color: "#c00",
          borderRadius: 4,
          fontSize: "0.875rem"
        }}>
          {error}
        </div>
      )}

      <div style={{ display: "flex", gap: "1rem", flexDirection: "column" }}>
        <button
          onClick={() => handleRoleSelection("MOVER")}
          disabled={loading}
          style={{
            padding: "1rem 1.5rem",
            backgroundColor: loading ? "#ccc" : "#0070f3",
            color: "white",
            border: "none",
            borderRadius: 4,
            fontSize: "1rem",
            cursor: loading ? "not-allowed" : "pointer",
            fontWeight: "bold"
          }}
        >
          {loading ? "Processing..." : "I'm a Mover"}
        </button>

        <button
          onClick={() => handleRoleSelection("SHIPPER")}
          disabled={loading}
          style={{
            padding: "1rem 1.5rem",
            backgroundColor: loading ? "#ccc" : "#0070f3",
            color: "white",
            border: "none",
            borderRadius: 4,
            fontSize: "1rem",
            cursor: loading ? "not-allowed" : "pointer",
            fontWeight: "bold"
          }}
        >
          {loading ? "Processing..." : "I'm a Shipper"}
        </button>
      </div>

      <div style={{
        marginTop: "1.5rem",
        padding: "0.75rem",
        backgroundColor: "#fff9e6",
        border: "1px solid #ffe066",
        borderRadius: 4,
        fontSize: "0.875rem",
        color: "#666"
      }}>
        <strong>Note:</strong> You can change your role later if needed.
      </div>
    </div>
  );
}

