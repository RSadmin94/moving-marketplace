-- Rollback: Drop Estimate table and indexes
-- Run this to reverse the migration

-- DropIndex
DROP INDEX IF EXISTS "Estimate_jobId_idx";
DROP INDEX IF EXISTS "Estimate_shipperId_idx";

-- DropTable
DROP TABLE IF EXISTS "Estimate";

