-- CreateTable
CREATE TABLE "Estimate" (
    "id" TEXT NOT NULL,
    "shipperId" TEXT NOT NULL,
    "jobId" TEXT,
    "inputData" JSONB NOT NULL,
    "photoData" JSONB NOT NULL,
    "aiResult" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Estimate_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Estimate_shipperId_idx" ON "Estimate"("shipperId");

-- CreateIndex
CREATE INDEX "Estimate_jobId_idx" ON "Estimate"("jobId");

