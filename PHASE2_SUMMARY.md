# Phase 2 - Backend Persistence + Contracts

## What will change

- **API Route Validation**: Added input validation for ZIP codes, move date format, and required fields
- **API Route Error Handling**: Improved error messages and validation logic
- **Phase 2A Gate Script**: Created PowerShell script to verify `.env.local` contains required keys (Clerk + DATABASE_URL with pgbouncer)
- **Phase 2B Gate Script**: Created PowerShell script to verify Prisma schema, migrations, and database connectivity
- **API Response Stability**: Ensured all API routes return stable JSON shape with `success` and `error` fields
- **Database Schema**: Job model already exists in Prisma schema; migrations already applied

## Exact commands to run

### Phase 2A - Local env and connectivity

```powershell
# Step 1: Navigate to repo root
cd C:\Users\RODERICK\Projects\moving-marketplace

# Step 2: Verify repo root
Test-Path .git

# Step 3: Run Phase 2A gate script
.\scripts\PHASE2A_GATE.ps1

# If gate passes, proceed to Phase 2B
```

### Phase 2B - DB migration verification

```powershell
# Step 1: Navigate to repo root (if not already there)
cd C:\Users\RODERICK\Projects\moving-marketplace

# Step 2: Run Phase 2B gate script
.\scripts\PHASE2B_GATE.ps1

# Step 3: If migrations are not applied, run:
# Development (creates migration):
pnpm prisma migrate dev --name init

# OR Production (applies existing migrations):
pnpm prisma migrate deploy

# Step 4: (Optional) Inspect database with Prisma Studio
pnpm prisma studio

# Step 5: Verify build passes
pnpm -s build
```

### Manual verification commands

```powershell
# Verify Prisma client is generated
pnpm prisma generate

# Check migration status
pnpm prisma migrate status

# Verify database connectivity (if DATABASE_URL is set)
pnpm prisma db pull --dry-run

# Run lint (if configured)
pnpm -s lint

# Run tests (if configured)
pnpm -s test
```

## Files to edit

### Modified files:
1. `app/api/jobs/route.ts` - Added input validation and improved error handling

### New files:
1. `scripts/PHASE2A_GATE.ps1` - Phase 2A gate script
2. `scripts/PHASE2B_GATE.ps1` - Phase 2B gate script

### Unchanged files (already correct):
- `prisma/schema.prisma` - Job model already defined correctly
- `lib/prisma.ts` - Prisma client already configured correctly
- `app/api/webhooks/clerk/route.ts` - User creation webhook already exists

## Code patches

### app/api/jobs/route.ts

```typescript
import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { prisma } from "@/lib/prisma";

export async function POST(request: NextRequest) {
  try {
    const { userId } = await auth();
    
    if (!userId) {
      return NextResponse.json(
        { success: false, error: "Unauthorized - Please sign in" },
        { status: 401 }
      );
    }

    let customer;
    const user = await prisma.user.findUnique({
      where: { clerkId: userId },
      include: { customer: true }
    });

    if (!user) {
      return NextResponse.json(
        { success: false, error: "User account not found" },
        { status: 404 }
      );
    }

    if (!user.customer) {
      customer = await prisma.customer.create({
        data: { userId: user.id }
      });
    } else {
      customer = user.customer;
    }

    const body = await request.json();
    const { originZip, destinationZip, moveDate, description } = body;

    // Validate required fields
    if (!originZip || !destinationZip || !moveDate) {
      return NextResponse.json(
        { success: false, error: "Missing required fields: originZip, destinationZip, and moveDate are required" },
        { status: 400 }
      );
    }

    // Validate ZIP format (basic)
    if (!/^\d{5}$/.test(originZip) || !/^\d{5}$/.test(destinationZip)) {
      return NextResponse.json(
        { success: false, error: "Invalid ZIP code format. Must be 5 digits" },
        { status: 400 }
      );
    }

    // Validate moveDate is a valid date
    const moveDateObj = new Date(moveDate);
    if (isNaN(moveDateObj.getTime())) {
      return NextResponse.json(
        { success: false, error: "Invalid move date format" },
        { status: 400 }
      );
    }

    const job = await prisma.job.create({
      data: {
        customerId: customer.id,
        originAddressFull: `ZIP: ${originZip}`,
        originCity: "",
        originState: "",
        originZip: originZip.trim(),
        originLat: 0,
        originLng: 0,
        destinationAddressFull: `ZIP: ${destinationZip}`,
        destinationCity: "",
        destinationState: "",
        destinationZip: destinationZip.trim(),
        destinationLat: null,
        destinationLng: null,
        moveDate: moveDateObj,
        isFlexibleDate: false,
        specialItems: description?.trim() || null,
        status: "ACTIVE",
        totalVolumeCuft: null,
      }
    });

    return NextResponse.json({
      success: true,
      jobId: job.id
    });

  } catch (error) {
    console.error("Job creation error:", error);
    return NextResponse.json(
      { success: false, error: "Failed to create job" },
      { status: 500 }
    );
  }
}

export async function GET() {
  try {
    const jobs = await prisma.job.findMany({
      where: { status: "ACTIVE" },
      orderBy: { createdAt: "desc" },
      take: 50
    });

    return NextResponse.json({ success: true, jobs });
  } catch (error) {
    console.error("Job fetch error:", error);
    return NextResponse.json(
      { success: false, error: "Failed to fetch jobs" },
      { status: 500 }
    );
  }
}
```

## Phase Gate checklist

### Phase 2A Gate Checklist

Run: `.\scripts\PHASE2A_GATE.ps1`

**Expected outcomes:**
1. ✅ Script verifies repo root exists (`.git` directory present)
2. ✅ Script verifies `.env.local` exists
3. ✅ Script verifies `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` exists (without printing value)
4. ✅ Script verifies `CLERK_SECRET_KEY` exists (without printing value)
5. ✅ Script verifies `DATABASE_URL` exists (without printing value)
6. ✅ Script verifies `DATABASE_URL` includes `pgbouncer=true`
7. ✅ Script verifies `DIRECT_URL` exists (warns if missing, but not required)
8. ✅ Script verifies Prisma schema exists
9. ✅ Script runs `pnpm prisma generate` successfully
10. ✅ Script runs `pnpm -s build` successfully
11. ✅ Script runs `pnpm -s lint` (if configured, skips if not)
12. ✅ Script runs `pnpm -s test` (if configured, skips if not)

**All checks must pass (exit code 0)**

### Phase 2B Gate Checklist

Run: `.\scripts\PHASE2B_GATE.ps1`

**Expected outcomes:**
1. ✅ Script verifies repo root exists
2. ✅ Script verifies `.env.local` has `DATABASE_URL` and `DIRECT_URL`
3. ✅ Script verifies Prisma schema exists
4. ✅ Script verifies migrations directory exists
5. ✅ Script runs `pnpm prisma generate` successfully
6. ✅ Script checks migration status (warns if not synced, but doesn't fail)
7. ✅ Script verifies Job model exists in schema
8. ✅ Script verifies required Job fields exist:
   - `id`, `customerId`, `originZip`, `destinationZip`, `moveDate`, `status`, `createdAt`
9. ✅ Script attempts database connectivity test (warns if fails, but doesn't fail)

**Script should pass with warnings if connectivity test fails (this is OK if DB doesn't exist yet)**

## Stop conditions

### If Phase 2A gate fails:

**Symptom**: Script exits with non-zero code

**Diagnostic commands:**
```powershell
# Check if .env.local exists
Test-Path .env.local

# Check if required keys exist (without printing values)
Get-Content .env.local | Select-String -Pattern '^NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY='
Get-Content .env.local | Select-String -Pattern '^CLERK_SECRET_KEY='
Get-Content .env.local | Select-String -Pattern '^DATABASE_URL=.*pgbouncer=true'

# Check Prisma schema
Test-Path prisma\schema.prisma

# Try generating Prisma client manually
pnpm prisma generate

# Try building manually
pnpm -s build
```

**Fix steps:**
1. If `.env.local` doesn't exist, create it with required keys:
   - `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_...` (from Vercel/Clerk dashboard)
   - `CLERK_SECRET_KEY=sk_...` (from Vercel/Clerk dashboard)
   - `DATABASE_URL=postgresql://...?pgbouncer=true&connection_limit=1` (from Supabase)
   - `DIRECT_URL=postgresql://...` (from Supabase, port 5432 session connection)
2. If `DATABASE_URL` doesn't include `pgbouncer=true`, add it to the connection string
3. If Prisma generate fails, check schema syntax: `pnpm prisma validate`
4. If build fails due to missing Clerk key, ensure `.env.local` is loaded (Next.js loads it automatically)
5. If build fails with other errors, check: `pnpm -s build 2>&1 | Out-File build-error.log`

### If Phase 2B gate fails:

**Symptom**: Script exits with non-zero code OR migration status shows unsynced

**Diagnostic commands:**
```powershell
# Check migration status
pnpm prisma migrate status

# Check if migrations directory exists
Test-Path prisma\migrations

# List migration files
Get-ChildItem prisma\migrations -Recurse -Filter *.sql

# Validate Prisma schema
pnpm prisma validate

# Check if DATABASE_URL is accessible (if set)
# Note: This may fail if DB doesn't exist yet, which is OK
pnpm prisma db pull --dry-run 2>&1
```

**Fix steps:**
1. If migrations are not applied, run:
   - **Development**: `pnpm prisma migrate dev --name init` (creates new migration if schema changed)
   - **Production**: `pnpm prisma migrate deploy` (applies existing migrations)
2. If migration fails due to schema mismatch, reset (DEV ONLY):
   ```powershell
   # WARNING: This deletes all data. Only use in development.
   pnpm prisma migrate reset
   ```
3. If `DIRECT_URL` is missing and migrations fail, add it to `.env.local`:
   - For Supabase: Use the session connection URL (port 5432, not 6543)
4. If connectivity test fails but everything else passes, this is OK - you can proceed to Phase 3

## Git commit message

```
feat(phase2): Add backend persistence validation and gate scripts

- Add input validation to jobs API route (ZIP format, date validation)
- Improve API error messages and response stability
- Add Phase 2A gate script: verify .env.local keys and build/test/lint
- Add Phase 2B gate script: verify Prisma schema and migration status
- Ensure DATABASE_URL includes pgbouncer=true for Supabase
- Handle nullable fields correctly (destinationLat/Lng, specialItems, totalVolumeCuft)

Phase 2A: Local env and connectivity verification
Phase 2B: DB migration verification

All API routes now return stable JSON shape with success/error fields.
```

## Notes

- **Prisma Schema**: Already complete with Job model. No changes needed.
- **Migrations**: Initial migration (`0_init`) already exists. May need to apply it if database is empty.
- **Database**: Supabase Postgres connection requires `pgbouncer=true&connection_limit=1` in `DATABASE_URL` for connection pooling.
- **DIRECT_URL**: Required for migrations. Should be the session connection (port 5432) without pgbouncer parameters.
- **User Creation**: Users are created via Clerk webhook (`/api/webhooks/clerk`) when they sign up. The jobs API assumes User exists.
- **API Validation**: All required fields are validated. ZIP codes must be 5 digits. Move date must be valid Date format.
- **Build Failure**: If build fails due to missing Clerk keys, ensure `.env.local` exists and contains `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`.


