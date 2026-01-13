"use client";

import { useState, useRef } from "react";
import Link from "next/link";

type EstimateResult = {
  cubicFeet: number;
  truck: "10ft" | "16ft" | "20ft" | "26ft";
  movers: 2 | 3 | 4;
  laborHours: number;
  packingMaterials: {
    boxes?: number;
    tape?: number;
    bubbleWrap?: number;
    furniturePads?: number;
  };
  confidence: "low" | "medium" | "high";
  explanationBullets?: string[];
};

type PhotoPreview = {
  id: string;
  file: File;
  preview: string;
};

const MAX_PHOTOS = 12;
const MAX_FILE_SIZE = 8 * 1024 * 1024; // 8MB

export default function EstimateForm() {
  const [moveType, setMoveType] = useState<string>("");
  const [bedrooms, setBedrooms] = useState<string>("");
  const [stairs, setStairs] = useState<boolean>(false);
  const [elevator, setElevator] = useState<boolean>(false);
  const [distanceMiles, setDistanceMiles] = useState<string>("");
  const [moveDate, setMoveDate] = useState<string>("");
  const [photos, setPhotos] = useState<PhotoPreview[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadingProgress, setLoadingProgress] = useState<string>("");
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<EstimateResult | null>(null);
  const [estimateId, setEstimateId] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Convert file to base64 data URL
  const fileToBase64 = (file: File): Promise<string> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result as string);
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  };

  const handlePhotoChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return;

    const files = Array.from(e.target.files);
    
    // Check total count
    if (photos.length + files.length > MAX_PHOTOS) {
      setError(`Maximum ${MAX_PHOTOS} photos allowed. You can add ${MAX_PHOTOS - photos.length} more.`);
      return;
    }

    // Validate and create previews
    const newPhotos: PhotoPreview[] = [];
    for (const file of files) {
      // Validate file type
      if (!file.type.startsWith("image/")) {
        setError(`File ${file.name} is not an image`);
        continue;
      }

      // Validate file size
      if (file.size > MAX_FILE_SIZE) {
        setError(`File ${file.name} exceeds ${MAX_FILE_SIZE / 1024 / 1024}MB limit`);
        continue;
      }

      // Create preview
      const preview = await fileToBase64(file);
      newPhotos.push({
        id: `${Date.now()}-${Math.random()}`,
        file,
        preview,
      });
    }

    setPhotos([...photos, ...newPhotos]);
    setError(null);
    
    // Reset file input
    if (fileInputRef.current) {
      fileInputRef.current.value = "";
    }
  };

  const removePhoto = (id: string) => {
    setPhotos(photos.filter((p) => p.id !== id));
    setError(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setResult(null);
    setLoadingProgress("Preparing photos...");

    try {
      // Validate at least one photo
      if (photos.length === 0) {
        throw new Error("Please upload at least one photo");
      }

      // Convert photos to base64 data URLs
      setLoadingProgress("Processing photos...");
      const photoUrls = photos.map((photo) => photo.preview);

      // Submit estimate request
      setLoadingProgress("Generating estimate with AI...");
      const response = await fetch("/api/estimates", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          photoUrls,
          moveType: moveType || null,
          bedrooms: bedrooms ? parseInt(bedrooms) : null,
          stairs,
          elevator,
          distanceMiles: distanceMiles ? parseInt(distanceMiles) : null,
          moveDate: moveDate || null,
        }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || "Failed to generate estimate");
      }

      setLoadingProgress("Finalizing...");
      const data = await response.json();
      setResult(data.result);
      setEstimateId(data.estimateId);
    } catch (err) {
      setError(err instanceof Error ? err.message : "An error occurred");
    } finally {
      setLoading(false);
      setLoadingProgress("");
    }
  };

  const resetForm = () => {
    setResult(null);
    setEstimateId(null);
    setPhotos([]);
    setMoveType("");
    setBedrooms("");
    setStairs(false);
    setElevator(false);
    setDistanceMiles("");
    setMoveDate("");
    setError(null);
  };

  return (
    <main style={{ padding: "2rem", fontFamily: "system-ui", maxWidth: "1200px", margin: "0 auto" }}>
      <div style={{ display: "flex", gap: "1rem", alignItems: "center", marginBottom: "2rem", flexWrap: "wrap" }}>
        <h1 style={{ margin: 0 }}>AI Moving Estimate</h1>
        <div style={{ display: "flex", gap: "1rem", marginLeft: "auto" }}>
          <Link 
            href="/shipper" 
            style={{ 
              color: "#0070f3", 
              textDecoration: "none",
              padding: "0.5rem 1rem",
              border: "1px solid #0070f3",
              borderRadius: "4px"
            }}
          >
            Shipper Dashboard
          </Link>
          <Link 
            href="/" 
            style={{ 
              color: "#0070f3", 
              textDecoration: "none",
              padding: "0.5rem 1rem",
              border: "1px solid #0070f3",
              borderRadius: "4px"
            }}
          >
            Home
          </Link>
        </div>
      </div>

      {/* Error State */}
      {error && (
        <div
          style={{
            padding: "1rem 1.5rem",
            backgroundColor: "#fee",
            border: "2px solid #fcc",
            borderRadius: "8px",
            marginBottom: "2rem",
            color: "#c33",
            display: "flex",
            alignItems: "center",
            gap: "0.75rem",
          }}
        >
          <span style={{ fontSize: "1.25rem" }}>⚠️</span>
          <div>
            <strong style={{ display: "block", marginBottom: "0.25rem" }}>Error</strong>
            <span>{error}</span>
          </div>
        </div>
      )}

      {/* Loading State */}
      {loading && (
        <div
          style={{
            padding: "2rem",
            backgroundColor: "#f0f7ff",
            border: "2px solid #0070f3",
            borderRadius: "8px",
            marginBottom: "2rem",
            textAlign: "center",
          }}
        >
          <div style={{ fontSize: "2rem", marginBottom: "1rem" }}>⏳</div>
          <div style={{ fontSize: "1.125rem", fontWeight: "bold", marginBottom: "0.5rem", color: "#0070f3" }}>
            Generating Estimate...
          </div>
          {loadingProgress && (
            <div style={{ fontSize: "0.875rem", color: "#666" }}>{loadingProgress}</div>
          )}
          <div style={{ marginTop: "1rem", fontSize: "0.875rem", color: "#666" }}>
            This may take 30-60 seconds
          </div>
        </div>
      )}

      {/* Success State */}
      {result ? (
        <div>
          <div
            style={{
              padding: "1rem 1.5rem",
              backgroundColor: "#efe",
              border: "2px solid #cfc",
              borderRadius: "8px",
              marginBottom: "2rem",
              color: "#3c3",
              display: "flex",
              alignItems: "center",
              gap: "0.75rem",
            }}
          >
            <span style={{ fontSize: "1.25rem" }}>✅</span>
            <div>
              <strong>Estimate Generated Successfully!</strong>
            </div>
          </div>

          <h2 style={{ marginBottom: "1.5rem", fontSize: "1.5rem" }}>Estimate Result</h2>
          <div
            style={{
              padding: "2rem",
              backgroundColor: "#f9f9f9",
              borderRadius: "12px",
              border: "1px solid #e0e0e0",
              boxShadow: "0 2px 8px rgba(0,0,0,0.1)",
            }}
          >
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(250px, 1fr))", gap: "1.5rem", marginBottom: "2rem" }}>
              <div style={{ padding: "1rem", backgroundColor: "white", borderRadius: "8px", border: "1px solid #e0e0e0" }}>
                <div style={{ fontSize: "0.875rem", color: "#666", marginBottom: "0.5rem" }}>Volume</div>
                <div style={{ fontSize: "1.5rem", fontWeight: "bold" }}>{result.cubicFeet.toLocaleString()}</div>
                <div style={{ fontSize: "0.875rem", color: "#666" }}>cubic feet</div>
              </div>
              <div style={{ padding: "1rem", backgroundColor: "white", borderRadius: "8px", border: "1px solid #e0e0e0" }}>
                <div style={{ fontSize: "0.875rem", color: "#666", marginBottom: "0.5rem" }}>Truck Size</div>
                <div style={{ fontSize: "1.5rem", fontWeight: "bold" }}>{result.truck}</div>
              </div>
              <div style={{ padding: "1rem", backgroundColor: "white", borderRadius: "8px", border: "1px solid #e0e0e0" }}>
                <div style={{ fontSize: "0.875rem", color: "#666", marginBottom: "0.5rem" }}>Movers</div>
                <div style={{ fontSize: "1.5rem", fontWeight: "bold" }}>{result.movers}</div>
              </div>
              <div style={{ padding: "1rem", backgroundColor: "white", borderRadius: "8px", border: "1px solid #e0e0e0" }}>
                <div style={{ fontSize: "0.875rem", color: "#666", marginBottom: "0.5rem" }}>Labor Hours</div>
                <div style={{ fontSize: "1.5rem", fontWeight: "bold" }}>{result.laborHours}</div>
              </div>
            </div>

            <div style={{ marginBottom: "1.5rem", padding: "1rem", backgroundColor: "white", borderRadius: "8px", border: "1px solid #e0e0e0" }}>
              <div style={{ fontSize: "0.875rem", color: "#666", marginBottom: "0.5rem" }}>Confidence Level</div>
              <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                <div
                  style={{
                    padding: "0.25rem 0.75rem",
                    borderRadius: "12px",
                    fontSize: "0.875rem",
                    fontWeight: "bold",
                    backgroundColor:
                      result.confidence === "high"
                        ? "#cfc"
                        : result.confidence === "medium"
                        ? "#ffc"
                        : "#fcc",
                    color:
                      result.confidence === "high"
                        ? "#3c3"
                        : result.confidence === "medium"
                        ? "#cc3"
                        : "#c33",
                    textTransform: "uppercase",
                  }}
                >
                  {result.confidence}
                </div>
              </div>
            </div>

            {result.packingMaterials && Object.keys(result.packingMaterials).length > 0 && (
              <div style={{ marginBottom: "1.5rem", padding: "1rem", backgroundColor: "white", borderRadius: "8px", border: "1px solid #e0e0e0" }}>
                <div style={{ fontSize: "1rem", fontWeight: "bold", marginBottom: "1rem" }}>Packing Materials</div>
                <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(150px, 1fr))", gap: "1rem" }}>
                  {result.packingMaterials.boxes && (
                    <div>
                      <div style={{ fontSize: "0.875rem", color: "#666" }}>Boxes</div>
                      <div style={{ fontSize: "1.25rem", fontWeight: "bold" }}>{result.packingMaterials.boxes}</div>
                    </div>
                  )}
                  {result.packingMaterials.tape && (
                    <div>
                      <div style={{ fontSize: "0.875rem", color: "#666" }}>Tape (rolls)</div>
                      <div style={{ fontSize: "1.25rem", fontWeight: "bold" }}>{result.packingMaterials.tape}</div>
                    </div>
                  )}
                  {result.packingMaterials.bubbleWrap && (
                    <div>
                      <div style={{ fontSize: "0.875rem", color: "#666" }}>Bubble Wrap (sq ft)</div>
                      <div style={{ fontSize: "1.25rem", fontWeight: "bold" }}>{result.packingMaterials.bubbleWrap}</div>
                    </div>
                  )}
                  {result.packingMaterials.furniturePads && (
                    <div>
                      <div style={{ fontSize: "0.875rem", color: "#666" }}>Furniture Pads</div>
                      <div style={{ fontSize: "1.25rem", fontWeight: "bold" }}>{result.packingMaterials.furniturePads}</div>
                    </div>
                  )}
                </div>
              </div>
            )}

            {result.explanationBullets && result.explanationBullets.length > 0 && (
              <div style={{ marginBottom: "1.5rem", padding: "1rem", backgroundColor: "white", borderRadius: "8px", border: "1px solid #e0e0e0" }}>
                <div style={{ fontSize: "1rem", fontWeight: "bold", marginBottom: "1rem" }}>Notes</div>
                <ul style={{ margin: 0, paddingLeft: "1.5rem", listStyle: "disc" }}>
                  {result.explanationBullets.map((bullet, i) => (
                    <li key={i} style={{ marginBottom: "0.5rem", lineHeight: "1.5" }}>
                      {bullet}
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {estimateId && (
              <div style={{ marginTop: "1rem", padding: "0.75rem", backgroundColor: "#f5f5f5", borderRadius: "6px", fontSize: "0.875rem", color: "#666" }}>
                <strong>Estimate ID:</strong> {estimateId}
              </div>
            )}
          </div>

          <div style={{ marginTop: "2rem", display: "flex", gap: "1rem" }}>
            <button
              onClick={resetForm}
              style={{
                padding: "0.75rem 1.5rem",
                backgroundColor: "#0070f3",
                color: "white",
                border: "none",
                borderRadius: "6px",
                cursor: "pointer",
                fontSize: "1rem",
                fontWeight: "bold",
              }}
            >
              Create New Estimate
            </button>
            <Link
              href="/shipper"
              style={{
                padding: "0.75rem 1.5rem",
                backgroundColor: "transparent",
                color: "#0070f3",
                border: "2px solid #0070f3",
                borderRadius: "6px",
                textDecoration: "none",
                fontSize: "1rem",
                fontWeight: "bold",
                display: "inline-block",
              }}
            >
              Back to Dashboard
            </Link>
          </div>
        </div>
      ) : (
        /* Form State */
        <form onSubmit={handleSubmit}>
          <div style={{ display: "flex", flexDirection: "column", gap: "1.5rem" }}>
            {/* Photo Upload Section */}
            <div
              style={{
                padding: "2rem",
                backgroundColor: "#f9f9f9",
                borderRadius: "12px",
                border: "2px dashed #ccc",
              }}
            >
              <label style={{ display: "block", marginBottom: "1rem", fontWeight: "bold", fontSize: "1.125rem" }}>
                Photos <span style={{ color: "#c33" }}>*</span>
                <span style={{ fontSize: "0.875rem", fontWeight: "normal", color: "#666", marginLeft: "0.5rem" }}>
                  (up to {MAX_PHOTOS}, max {MAX_FILE_SIZE / 1024 / 1024}MB each)
                </span>
              </label>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/jpeg,image/png,image/webp,image/jpg"
                multiple
                onChange={handlePhotoChange}
                disabled={loading || photos.length >= MAX_PHOTOS}
                style={{
                  width: "100%",
                  padding: "0.75rem",
                  borderRadius: "6px",
                  border: "1px solid #ccc",
                  backgroundColor: loading || photos.length >= MAX_PHOTOS ? "#f0f0f0" : "white",
                  cursor: loading || photos.length >= MAX_PHOTOS ? "not-allowed" : "pointer",
                }}
              />
              {photos.length > 0 && (
                <div style={{ marginTop: "1.5rem" }}>
                  <div style={{ fontSize: "0.875rem", color: "#666", marginBottom: "1rem" }}>
                    {photos.length} of {MAX_PHOTOS} photos selected
                  </div>
                  <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(120px, 1fr))", gap: "1rem" }}>
                    {photos.map((photo) => (
                      <div
                        key={photo.id}
                        style={{
                          position: "relative",
                          aspectRatio: "1",
                          borderRadius: "8px",
                          overflow: "hidden",
                          border: "2px solid #e0e0e0",
                        }}
                      >
                        <img
                          src={photo.preview}
                          alt={photo.file.name}
                          style={{
                            width: "100%",
                            height: "100%",
                            objectFit: "cover",
                          }}
                        />
                        <button
                          type="button"
                          onClick={() => removePhoto(photo.id)}
                          disabled={loading}
                          style={{
                            position: "absolute",
                            top: "0.25rem",
                            right: "0.25rem",
                            background: "rgba(0,0,0,0.7)",
                            color: "white",
                            border: "none",
                            borderRadius: "50%",
                            width: "24px",
                            height: "24px",
                            cursor: loading ? "not-allowed" : "pointer",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            fontSize: "1.25rem",
                            lineHeight: "1",
                          }}
                        >
                          ×
                        </button>
                        <div
                          style={{
                            position: "absolute",
                            bottom: 0,
                            left: 0,
                            right: 0,
                            background: "rgba(0,0,0,0.7)",
                            color: "white",
                            padding: "0.25rem",
                            fontSize: "0.75rem",
                            overflow: "hidden",
                            textOverflow: "ellipsis",
                            whiteSpace: "nowrap",
                          }}
                        >
                          {photo.file.name}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Form Fields */}
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(300px, 1fr))", gap: "1.5rem" }}>
              <div>
                <label style={{ display: "block", marginBottom: "0.5rem", fontWeight: "bold" }}>
                  Move Type
                </label>
                <select
                  value={moveType}
                  onChange={(e) => setMoveType(e.target.value)}
                  disabled={loading}
                  style={{
                    width: "100%",
                    padding: "0.75rem",
                    borderRadius: "6px",
                    border: "1px solid #ccc",
                    backgroundColor: loading ? "#f0f0f0" : "white",
                    cursor: loading ? "not-allowed" : "pointer",
                  }}
                >
                  <option value="">Select...</option>
                  <option value="APT">Apartment</option>
                  <option value="HOUSE">House</option>
                  <option value="OFFICE">Office</option>
                </select>
              </div>

              <div>
                <label style={{ display: "block", marginBottom: "0.5rem", fontWeight: "bold" }}>
                  Bedrooms
                </label>
                <input
                  type="number"
                  value={bedrooms}
                  onChange={(e) => setBedrooms(e.target.value)}
                  min="0"
                  disabled={loading}
                  style={{
                    width: "100%",
                    padding: "0.75rem",
                    borderRadius: "6px",
                    border: "1px solid #ccc",
                    backgroundColor: loading ? "#f0f0f0" : "white",
                  }}
                />
              </div>

              <div>
                <label style={{ display: "block", marginBottom: "0.5rem", fontWeight: "bold" }}>
                  Distance (Miles)
                </label>
                <input
                  type="number"
                  value={distanceMiles}
                  onChange={(e) => setDistanceMiles(e.target.value)}
                  min="0"
                  disabled={loading}
                  style={{
                    width: "100%",
                    padding: "0.75rem",
                    borderRadius: "6px",
                    border: "1px solid #ccc",
                    backgroundColor: loading ? "#f0f0f0" : "white",
                  }}
                />
              </div>

              <div>
                <label style={{ display: "block", marginBottom: "0.5rem", fontWeight: "bold" }}>
                  Move Date
                </label>
                <input
                  type="date"
                  value={moveDate}
                  onChange={(e) => setMoveDate(e.target.value)}
                  disabled={loading}
                  style={{
                    width: "100%",
                    padding: "0.75rem",
                    borderRadius: "6px",
                    border: "1px solid #ccc",
                    backgroundColor: loading ? "#f0f0f0" : "white",
                  }}
                />
              </div>
            </div>

            <div style={{ display: "flex", gap: "1rem", flexWrap: "wrap" }}>
              <label
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "0.5rem",
                  padding: "0.75rem",
                  backgroundColor: "#f9f9f9",
                  borderRadius: "6px",
                  cursor: loading ? "not-allowed" : "pointer",
                }}
              >
                <input
                  type="checkbox"
                  checked={stairs}
                  onChange={(e) => setStairs(e.target.checked)}
                  disabled={loading}
                  style={{ cursor: loading ? "not-allowed" : "pointer" }}
                />
                <span>Stairs</span>
              </label>

              <label
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "0.5rem",
                  padding: "0.75rem",
                  backgroundColor: "#f9f9f9",
                  borderRadius: "6px",
                  cursor: loading ? "not-allowed" : "pointer",
                }}
              >
                <input
                  type="checkbox"
                  checked={elevator}
                  onChange={(e) => setElevator(e.target.checked)}
                  disabled={loading}
                  style={{ cursor: loading ? "not-allowed" : "pointer" }}
                />
                <span>Elevator Available</span>
              </label>
            </div>

            <button
              type="submit"
              disabled={loading || photos.length === 0}
              style={{
                padding: "1rem 2rem",
                backgroundColor: loading || photos.length === 0 ? "#ccc" : "#0070f3",
                color: "white",
                border: "none",
                borderRadius: "6px",
                cursor: loading || photos.length === 0 ? "not-allowed" : "pointer",
                fontSize: "1.125rem",
                fontWeight: "bold",
                transition: "background-color 0.2s",
              }}
            >
              {loading ? "Generating Estimate..." : "Generate Estimate"}
            </button>
          </div>
        </form>
      )}
    </main>
  );
}

