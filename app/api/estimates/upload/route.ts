import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import sharp from "sharp";

const MAX_FILE_SIZE = 8 * 1024 * 1024; // 8MB
const MAX_FILES = 12;
const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp"];
const TARGET_LONG_EDGE = 1600;

export async function POST(request: NextRequest) {
  try {
    const { userId } = await auth();
    
    if (!userId) {
      return NextResponse.json(
        { ok: false, error: "Unauthorized" },
        { status: 401 }
      );
    }

    const formData = await request.formData();
    const files = formData.getAll("photos") as File[];
    
    if (files.length === 0) {
      return NextResponse.json(
        { ok: false, error: "No photos provided" },
        { status: 400 }
      );
    }

    if (files.length > MAX_FILES) {
      return NextResponse.json(
        { ok: false, error: `Maximum ${MAX_FILES} photos allowed` },
        { status: 400 }
      );
    }

    const processedPhotos: Array<{ url: string; width: number; height: number }> = [];

    for (const file of files) {
      // Validate file type
      if (!ALLOWED_TYPES.includes(file.type)) {
        return NextResponse.json(
          { ok: false, error: `Invalid file type: ${file.type}. Allowed: jpeg, png, webp` },
          { status: 400 }
        );
      }

      // Validate file size
      if (file.size > MAX_FILE_SIZE) {
        return NextResponse.json(
          { ok: false, error: `File ${file.name} exceeds ${MAX_FILE_SIZE / 1024 / 1024}MB limit` },
          { status: 400 }
        );
      }

      // Read file buffer
      const arrayBuffer = await file.arrayBuffer();
      const buffer = Buffer.from(arrayBuffer);

      // Process image with sharp
      const image = sharp(buffer);
      const metadata = await image.metadata();
      
      let processedBuffer: Buffer = buffer;
      let width = metadata.width || 0;
      let height = metadata.height || 0;

      // Resize if needed
      if (width > TARGET_LONG_EDGE || height > TARGET_LONG_EDGE) {
        const resized = image.resize(TARGET_LONG_EDGE, TARGET_LONG_EDGE, {
          fit: "inside",
          withoutEnlargement: true,
        });
        const resizedBuffer = await resized.toBuffer();
        processedBuffer = Buffer.from(resizedBuffer);
        const resizedMetadata = await sharp(processedBuffer).metadata();
        width = resizedMetadata.width || 0;
        height = resizedMetadata.height || 0;
      }

      // Strip EXIF and convert to JPEG
      const jpegBuffer = await sharp(processedBuffer)
        .jpeg({ quality: 85 })
        .toBuffer();

      // Convert to base64 data URL for MVP (can be upgraded to Supabase Storage)
      const base64 = jpegBuffer.toString("base64");
      const dataUrl = `data:image/jpeg;base64,${base64}`;

      processedPhotos.push({
        url: dataUrl,
        width,
        height,
      });
    }

    return NextResponse.json({
      ok: true,
      photos: processedPhotos,
    });

  } catch (error) {
    console.error("Upload error:", error);
    return NextResponse.json(
      { ok: false, error: "Failed to process photos" },
      { status: 500 }
    );
  }
}

