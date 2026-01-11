# Phase 5 - Mover Dashboard MVP

## What will change

- **New Route**: Created `/mover` page - a protected server component that shows jobs the signed-in user has expressed interest in
- **Server Component**: Uses Clerk server-side auth (`auth()` from `@clerk/nextjs/server`)
- **Prisma Query**: Queries `Interest` model with `include: { job: { select: ... } }` to get related job data
- **Empty State**: Shows message when user has no interests yet
- **Date Formatting**: Formats dates as YYYY-MM-DD or "TBD" for move dates, YYYY-MM-DD for createdAt
- **Navigation Links**: Links to Home (`/`) and Jobs (`/jobs`)

## Exact commands to run (PowerShell 5.1 compatible)

### Phase 5 Gate

```powershell
# Navigate to repo root
cd C:\Users\RODERICK\Projects\moving-marketplace

# Run Phase 5 gate (verifies files, content, build, lint)
.\scripts\PHASE5_GATE.ps1

# If gate passes, proceed to commit
```

### Commit and Push

```powershell
# Navigate to repo root (if not already there)
cd C:\Users\RODERICK\Projects\moving-marketplace

# Review changes
git status

# Stage all changes
git add .

# Commit with descriptive message
git commit -m "feat(phase5): Add Mover Dashboard MVP

- Create /mover route (protected server component)
- Query Interest model with job relation for signed-in user
- Display jobs with originZip, destinationZip, moveDate, createdAt
- Show empty state when no interests
- Add navigation links to Home and Jobs

Phase 5: Mover Dashboard MVP"

# Push to remote
git push

# Deploy to Vercel (automatic if connected to repo, or manually)
# npx vercel --prod
```

## Files to edit

### New files:
1. `app/mover/page.tsx` - Mover dashboard page (server component)
2. `scripts/PHASE5_GATE.ps1` - Phase 5 gate script
3. `PHASE5_SUMMARY.md` - This documentation

### Unchanged files:
- No existing files were modified for Phase 5

## Code patches

### app/mover/page.tsx

See the file for full implementation. Key features:
- Uses `auth()` from `@clerk/nextjs/server` to get `userId`
- Redirects to `/sign-in` if not authenticated
- Queries `prisma.interest.findMany({ where: { userId }, include: { job: { select: ... } } })`
- Formats dates safely server-side
- Shows empty state when `interests.length === 0`
- Displays jobs with required fields
- Includes navigation links

## Phase Gate checklist

### Phase 5 Gate Checklist

Run: `.\scripts\PHASE5_GATE.ps1`

**Expected outcomes:**
1. ✅ Script verifies `app/mover/page.tsx` exists
2. ✅ Script verifies mover page does NOT contain "use client"
3. ✅ Script verifies mover page uses Clerk server auth (`auth` from `@clerk/nextjs/server`)
4. ✅ Script verifies mover page queries Interest model (`prisma.interest.findMany`)
5. ✅ Script verifies mover page includes job relation (`include` with `job`)
6. ✅ Script verifies mover page displays required fields (originZip, destinationZip, moveDate, createdAt)
7. ✅ Script verifies mover page has links to Home and Jobs
8. ✅ Script runs `pnpm build` successfully
9. ✅ Script runs `pnpm lint` successfully

**All checks must pass (exit code 0)**

## Manual test steps

### Local Testing

1. **Run Phase 5 gate**:
   ```powershell
   cd C:\Users\RODERICK\Projects\moving-marketplace
   .\scripts\PHASE5_GATE.ps1
   ```
   Expected: All checks pass

2. **Start dev server**:
   ```powershell
   pnpm dev
   ```

3. **Test as signed-in user**:
   - Navigate to `http://localhost:3000/mover`
   - If not signed in, should redirect to `/sign-in`
   - Sign in with a user account
   - If user has no interests:
     - Should see empty state message: "You haven't expressed interest in any jobs yet."
     - Should see link to "Browse available jobs"
   - Navigate to `/jobs`, click on a job, click "Express Interest"
   - Navigate back to `/mover`
   - Should see the job listed with:
     - Origin ZIP → Destination ZIP (as link to job detail)
     - Move Date: YYYY-MM-DD or TBD
     - Job Posted: YYYY-MM-DD
     - Job ID: first 8 characters

4. **Test navigation**:
   - Click "Jobs" link - should navigate to `/jobs`
   - Click "Home" link - should navigate to `/`
   - Click on job link - should navigate to `/jobs/[id]`

5. **Test date formatting**:
   - Jobs with moveDate should show YYYY-MM-DD
   - Jobs without moveDate should show "TBD"
   - createdAt should always show YYYY-MM-DD

### Production Testing

1. **Deploy to Vercel** (via git push or `npx vercel --prod`)

2. **Test as signed-in user**:
   - Navigate to `https://moving-marketplace.vercel.app/mover`
   - If not signed in, should redirect to `/sign-in`
   - Sign in with a user account
   - Verify same behavior as local testing

3. **Test empty state**:
   - With a new user account that has no interests
   - Should see empty state message and link

4. **Test with interests**:
   - Express interest in a job from job detail page
   - Navigate to `/mover`
   - Verify job appears in list

5. **Test navigation**:
   - Verify all links work correctly

## Stop conditions

### If Phase 5 gate fails:

**Symptom**: Script exits with non-zero code

**Diagnostic commands:**
```powershell
# Check if mover page exists
Test-Path app\mover\page.tsx

# Check mover page content
Get-Content app\mover\page.tsx | Select-String -Pattern "use client"
Get-Content app\mover\page.tsx | Select-String -Pattern "auth|@clerk/nextjs/server"
Get-Content app\mover\page.tsx | Select-String -Pattern "prisma.interest.findMany"
Get-Content app\mover\page.tsx | Select-String -Pattern "include.*job"

# Try building manually
pnpm -s build 2>&1 | Out-File build-error.log
Get-Content build-error.log

# Try linting manually
pnpm -s lint 2>&1 | Out-File lint-error.log
Get-Content lint-error.log
```

**Fix steps:**
1. If mover page is missing, create `app/mover/page.tsx` (see Code patches section)
2. If "use client" is present, remove it (must be server component)
3. If Clerk auth is missing, add `import { auth } from "@clerk/nextjs/server"` and use `await auth()`
4. If Prisma query is missing, add `prisma.interest.findMany` with proper `include` for job relation
5. If build fails, check TypeScript errors in build output
6. If lint fails, fix linting errors shown in output (especially apostrophes - use `&apos;`)

### If production deployment fails:

**Symptom**: Vercel build fails or page doesn't work

**Diagnostic commands:**
```powershell
# Check Vercel build logs
npx vercel logs --follow

# Verify environment variables
npx vercel env ls
```

**Fix steps:**
1. Check Vercel build logs for errors
2. Verify Clerk keys are set in Vercel
3. Verify DATABASE_URL is set in Vercel (if needed for migrations)
4. Verify build command in `package.json` is correct

## Git commit message

```
feat(phase5): Add Mover Dashboard MVP

- Create /mover route (protected server component)
- Query Interest model with job relation for signed-in user
- Display jobs with originZip, destinationZip, moveDate, createdAt
- Show empty state when no interests
- Add navigation links to Home and Jobs

Phase 5: Mover Dashboard MVP
```

## Notes

- **Server Component**: The `/mover` page is a server component (no "use client") to avoid hydration issues and leverage server-side rendering.

- **Authentication**: Uses Clerk's `auth()` function server-side. Redirects to `/sign-in` if not authenticated.

- **Date Formatting**: Dates are formatted server-side using `toISOString().split('T')[0]` to get YYYY-MM-DD format. This avoids hydration mismatches.

- **Empty State**: Shows a friendly message when user has no interests, with a link to browse jobs.

- **Job Relation**: The Prisma query uses `include: { job: { select: ... } }` to fetch related job data in a single query.

- **Navigation**: Includes links to Home (`/`) and Jobs (`/jobs`) for easy navigation.

- **Lint**: Fixed apostrophes in text by using `&apos;` HTML entity to satisfy React linting rules.

