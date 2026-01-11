# Phase 4 - Express Interest Feature

## What will change

- **Prisma Schema**: Added `Interest` model with `id`, `jobId`, `userId`, `createdAt` and unique constraint on `[jobId, userId]`
- **API Route**: Created `/api/interests` route with POST (create interest) and GET (check interest status) endpoints
- **UI Component**: Added `ExpressInterestButton` client component to job detail page
- **Job Detail Page**: Updated to include Express Interest button
- **Authorization**: Only signed-in users can express interest (uses Clerk `SignedIn`/`SignedOut` components)

## Exact commands to run (PowerShell 5.1 compatible)

### Phase 4 Gate

```powershell
# Navigate to repo root
cd C:\Users\RODERICK\Projects\moving-marketplace

# Run Phase 4 gate script
.\scripts\PHASE4_GATE.ps1

# If gate passes, proceed with migration
```

### Create Migration (Local Development)

```powershell
# Navigate to repo root (if not already there)
cd C:\Users\RODERICK\Projects\moving-marketplace

# Create migration (this will create migration files)
pnpm prisma migrate dev --name add_interest_model

# Verify migration was created
Get-ChildItem prisma\migrations -Recurse -Filter migration.sql | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content

# Generate Prisma client (should be automatic, but verify)
pnpm prisma generate

# Test build
pnpm -s build

# Test lint
pnpm -s lint
```

### Apply Migration in Production (Vercel)

```powershell
# Migration will be applied automatically on Vercel via:
# - postinstall script: prisma generate
# - Build command: prisma migrate deploy (if configured)
# OR manually via Vercel CLI:

# Option 1: Via Vercel CLI (if configured)
npx vercel env pull .env.local
# Then in production environment:
npx vercel --prod
# Vercel will run prisma migrate deploy automatically if configured

# Option 2: Manual production migration (if needed)
# Connect to production database and run:
pnpm prisma migrate deploy
```

### Commit and Push

```powershell
# Navigate to repo root
cd C:\Users\RODERICK\Projects\moving-marketplace

# Review changes
git status

# Stage all changes
git add .

# Commit with descriptive message
git commit -m "feat(phase4): Add Express Interest feature

- Add Interest model to Prisma schema (jobId, userId, unique constraint)
- Create /api/interests route (POST and GET)
- Add ExpressInterestButton component to job detail page
- Only signed-in users can express interest
- Show success message and disable button if already interested

Phase 4: Express Interest (minimal marketplace interaction)"

# Push to remote
git push

# Deploy to Vercel (will happen automatically if Vercel is connected to repo)
# OR deploy manually:
npx vercel --prod
```

## Files to edit

### Modified files:
1. `prisma/schema.prisma` - Added `Interest` model and relation to `Job`
2. `app/jobs/[id]/page.tsx` - Added import and usage of `ExpressInterestButton`

### New files:
1. `app/api/interests/route.ts` - API route for creating and querying interests
2. `app/jobs/[id]/ExpressInterestButton.tsx` - Client component for Express Interest button

## Code patches

### prisma/schema.prisma

```prisma
model Job {
  // ... existing fields ...
  interests      Interest[]
  // ... rest of model ...
}

model Interest {
  id        String   @id @default(cuid())
  jobId     String
  userId    String
  createdAt DateTime @default(now())

  job Job @relation(fields: [jobId], references: [id], onDelete: Cascade)

  @@unique([jobId, userId])
  @@index([jobId])
  @@index([userId])
}
```

### app/api/interests/route.ts

See file for full implementation. Key features:
- POST: Requires auth, validates jobId, checks job is ACTIVE, enforces uniqueness
- GET: Returns count and whether current user is interested

### app/jobs/[id]/ExpressInterestButton.tsx

See file for full implementation. Key features:
- Uses Clerk `SignedIn`/`SignedOut` components
- Fetches interest status on mount
- Handles click, shows success message, disables if already interested
- Shows "Sign in to Express Interest" link if not signed in

### app/jobs/[id]/page.tsx

Added:
```tsx
import ExpressInterestButton from "./ExpressInterestButton";
// ...
<ExpressInterestButton jobId={job.id} />
```

## Phase Gate checklist

### Phase 4 Gate Checklist

Run: `.\scripts\PHASE4_GATE.ps1`

**Expected outcomes:**
1. ✅ Script verifies repo root exists (`.git` directory present)
2. ✅ Script verifies `Interest` model exists in `prisma/schema.prisma`
3. ✅ Script verifies `Interest` model has required fields: `id`, `jobId`, `userId`, `createdAt`
4. ✅ Script verifies `Interest` model has unique constraint on `[jobId, userId]`
5. ✅ Script verifies `app/api/interests/route.ts` exists
6. ✅ Script verifies POST and GET functions exist in API route
7. ✅ Script verifies `app/jobs/[id]/ExpressInterestButton.tsx` exists
8. ✅ Script verifies job detail page imports and uses `ExpressInterestButton`
9. ✅ Script runs `pnpm prisma generate` successfully
10. ✅ Script runs `pnpm -s build` successfully
11. ✅ Script runs `pnpm -s lint` successfully (if configured)
12. ✅ Script prints summary: Passed X, Failed Y

**All checks must pass (exit code 0)**

## Stop conditions

### If Phase 4 gate fails:

**Symptom**: Script exits with non-zero code

**Diagnostic commands:**
```powershell
# Check if Interest model exists
Get-Content prisma\schema.prisma | Select-String -Pattern "model Interest"

# Check if API route exists
Test-Path app\api\interests\route.ts

# Check if button component exists
Test-Path "app\jobs\[id]\ExpressInterestButton.tsx"

# Check if job detail page uses the component
Get-Content "app\jobs\[id]\page.tsx" | Select-String -Pattern "ExpressInterestButton"

# Try generating Prisma client manually
pnpm prisma generate

# Try building manually
pnpm -s build 2>&1 | Out-File build-error.log
Get-Content build-error.log

# Try linting manually
pnpm -s lint 2>&1 | Out-File lint-error.log
Get-Content lint-error.log
```

**Fix steps:**
1. If Interest model is missing, add it to `prisma/schema.prisma` (see Code patches section)
2. If API route is missing, create `app/api/interests/route.ts` (see Code patches section)
3. If button component is missing, create `app/jobs/[id]/ExpressInterestButton.tsx` (see Code patches section)
4. If job detail page doesn't use component, add import and usage (see Code patches section)
5. If Prisma generate fails, check schema syntax: `pnpm prisma validate`
6. If build fails, check for TypeScript errors in the build output
7. If lint fails, fix linting errors shown in output

### If migration fails:

**Symptom**: `pnpm prisma migrate dev --name add_interest_model` fails

**Diagnostic commands:**
```powershell
# Check Prisma schema is valid
pnpm prisma validate

# Check if database is accessible
pnpm prisma db pull --dry-run

# Check migration status
pnpm prisma migrate status

# List existing migrations
Get-ChildItem prisma\migrations -Recurse -Filter migration.sql
```

**Fix steps:**
1. If schema is invalid, fix syntax errors shown by `pnpm prisma validate`
2. If database is not accessible, check `.env.local` has correct `DATABASE_URL` and `DIRECT_URL`
3. If migration conflicts exist, resolve conflicts or reset migrations (DEV ONLY):
   ```powershell
   # WARNING: This deletes all data. Only use in development.
   pnpm prisma migrate reset
   ```

### If production migration fails:

**Symptom**: Vercel build fails or migration doesn't apply

**Diagnostic commands:**
```powershell
# Check Vercel environment variables
npx vercel env ls

# Check Vercel build logs
npx vercel logs --follow

# Verify DATABASE_URL is set in Vercel
npx vercel env pull .env.local
Get-Content .env.local | Select-String -Pattern "DATABASE_URL"
```

**Fix steps:**
1. If DATABASE_URL is missing in Vercel, add it via Vercel dashboard or CLI:
   ```powershell
   npx vercel env add DATABASE_URL production
   npx vercel env add DIRECT_URL production
   ```
2. If migration fails on Vercel, check build logs for errors
3. If needed, manually apply migration:
   - Connect to production database
   - Run: `pnpm prisma migrate deploy`

## Testing checklist

### Local Testing

- [ ] Run Phase 4 gate: `.\scripts\PHASE4_GATE.ps1` passes
- [ ] Create migration: `pnpm prisma migrate dev --name add_interest_model` succeeds
- [ ] Build passes: `pnpm -s build` succeeds
- [ ] Lint passes: `pnpm -s lint` succeeds (if configured)
- [ ] Start dev server: `pnpm dev`
- [ ] Sign in to the app
- [ ] Navigate to a job detail page (`/jobs/[id]`)
- [ ] Click "Express Interest" button
- [ ] Verify success message appears
- [ ] Refresh page
- [ ] Verify button shows "✓ Interested" (disabled)
- [ ] Sign out
- [ ] Navigate to job detail page
- [ ] Verify "Sign in to Express Interest" link appears
- [ ] Click link, sign in, verify redirected back to job detail

### Production Testing

- [ ] Deploy to Vercel (via git push or `npx vercel --prod`)
- [ ] Verify deployment succeeds
- [ ] Sign in to production app
- [ ] Navigate to a job detail page
- [ ] Click "Express Interest" button
- [ ] Verify success message appears
- [ ] Refresh page
- [ ] Verify button shows "✓ Interested" (disabled)
- [ ] Sign out
- [ ] Navigate to job detail page
- [ ] Verify "Sign in to Express Interest" link appears

## Rollback procedure

If Phase 4 needs to be rolled back:

### Rollback steps:

1. **Revert code changes** (if not yet in production):
   ```powershell
   git revert HEAD
   git push
   ```

2. **Rollback database migration** (if applied):
   ```powershell
   # WARNING: This requires creating a new migration that drops the Interest table
   # Only do this if absolutely necessary and you understand the consequences
   
   # Create a rollback migration:
   # Edit prisma/schema.prisma to remove Interest model
   pnpm prisma migrate dev --name rollback_interest_model
   
   # OR manually drop table in database (if safe):
   # DROP TABLE IF EXISTS "Interest";
   ```

3. **Remove Vercel environment variables** (if added for migration):
   ```powershell
   npx vercel env rm DATABASE_URL production
   npx vercel env rm DIRECT_URL production
   ```

**Note**: Rolling back a database migration is destructive and should only be done if absolutely necessary. Consider backing up the database first.

## Git commit message

```
feat(phase4): Add Express Interest feature

- Add Interest model to Prisma schema (jobId, userId, unique constraint)
- Create /api/interests route (POST and GET)
- Add ExpressInterestButton component to job detail page
- Only signed-in users can express interest
- Show success message and disable button if already interested

Phase 4: Express Interest (minimal marketplace interaction)
```

## Notes

- **Database Migration**: The migration will be created locally with `pnpm prisma migrate dev --name add_interest_model`. Production migration happens automatically on Vercel if `prisma migrate deploy` is configured in build command, or manually via Vercel CLI.

- **User ID Storage**: The `Interest` model stores `userId` as a string (Clerk user ID). This is simpler than creating a FK to User table, but could be changed in the future if needed.

- **Uniqueness**: The unique constraint on `[jobId, userId]` ensures a user can only express interest once per job.

- **Authorization**: The Express Interest button uses Clerk's `SignedIn`/`SignedOut` components to show/hide the button based on authentication status.

- **UI Pattern**: The button is a minimal client component that handles its own state. It fetches interest status on mount and handles clicks with loading/error/success states.

- **API Pattern**: The API follows the same pattern as `/api/jobs` route: returns `{ success: boolean, ... }` JSON responses with proper error handling.


