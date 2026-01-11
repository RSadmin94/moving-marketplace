# Phase 7 - Role-Based Route Enforcement

## What will change

- **Role Enforcement**: Added server-side role checks to `/mover` and `/post-job` pages
- **Access Control**: 
  - `/mover` requires `role === "MOVER"`
  - `/post-job` requires `role === "SHIPPER"`
- **Redirect Logic**: 
  - Not signed in → redirect to `/sign-in`
  - Signed in but no role → redirect to `/choose-role`
  - Wrong role → redirect to appropriate page (MOVER → /mover, SHIPPER → /post-job)
- **No Middleware Changes**: All checks done in server components, no middleware modifications
- **Post-Job Refactoring**: Converted `/post-job` to server component wrapper with client form component

## Files created

1. `app/post-job/PostJobForm.tsx` - Client component with job posting form (extracted from page.tsx)
2. `scripts/PHASE7_GATE.ps1` - Phase 7 gate script
3. `PHASE7_SUMMARY.md` - This documentation

## Files modified

1. `app/mover/page.tsx` - Added role check (requires MOVER role)
2. `app/post-job/page.tsx` - Converted to server component with role check (requires SHIPPER role)

## Exact commands to run (PowerShell 5.1 compatible)

### Phase 7 Gate

```powershell
# Navigate to repo root
cd C:\Users\RODERICK\Projects\moving-marketplace

# Run Phase 7 gate (verifies files, role checks, build, lint)
.\scripts\PHASE7_GATE.ps1

# If gate passes, proceed to commit
```

### Commit and Push

```powershell
# Navigate to repo root (if not already there)
cd C:\Users\RODERICK\Projects\moving-marketplace

# Review changes
git status -sb

# Stage Phase 7 files
git add app/mover/page.tsx app/post-job/page.tsx app/post-job/PostJobForm.tsx scripts/PHASE7_GATE.ps1 PHASE7_SUMMARY.md

# Commit with descriptive message
git commit -m "Phase 7: enforce role-based access on mover + post-job + gate"

# Push to remote
git push origin main

# Deploy to Vercel (automatic if connected to repo, or manually)
# npx vercel --prod
```

## Code patches

### app/mover/page.tsx

Added role check after auth check:
```typescript
// Check user role - MOVER required for this page
const client = await clerkClient();
const user = await client.users.getUser(userId);
const role = user.publicMetadata?.role as string | undefined;

if (!role) {
  redirect("/choose-role");
}

if (role !== "MOVER") {
  // If role is SHIPPER, redirect to /post-job
  redirect("/post-job");
}
```

### app/post-job/page.tsx

Converted to server component with role check:
```typescript
import { auth, clerkClient } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import PostJobForm from "./PostJobForm";

export default async function PostJobPage() {
  const { userId } = await auth();

  if (!userId) {
    redirect("/sign-in");
  }

  // Check user role - SHIPPER required for this page
  const client = await clerkClient();
  const user = await client.users.getUser(userId);
  const role = user.publicMetadata?.role as string | undefined;

  if (!role) {
    redirect("/choose-role");
  }

  if (role !== "SHIPPER") {
    // If role is MOVER, redirect to /mover
    redirect("/mover");
  }

  // User has SHIPPER role, render the form
  return <PostJobForm />;
}
```

### app/post-job/PostJobForm.tsx

Extracted client component from original page.tsx:
- Contains all form logic and UI
- No role checks (handled by server wrapper)
- Remains a client component for interactivity

## Phase Gate checklist

### Phase 7 Gate Checklist

Run: `.\scripts\PHASE7_GATE.ps1`

**Expected outcomes:**
1. ✅ Script verifies `app/mover/page.tsx` exists
2. ✅ Script verifies `app/post-job/page.tsx` exists
3. ✅ Script verifies mover page is server component (no "use client")
4. ✅ Script verifies mover page uses Clerk server auth
5. ✅ Script verifies mover page redirects to sign-in if not authenticated
6. ✅ Script verifies mover page checks user role via clerkClient.getUser
7. ✅ Script verifies mover page checks for MOVER role
8. ✅ Script verifies mover page redirects to /choose-role if role missing
9. ✅ Script verifies mover page redirects SHIPPER to /post-job
10. ✅ Script verifies post-job page is server component (no "use client")
11. ✅ Script verifies post-job page uses Clerk server auth
12. ✅ Script verifies post-job page redirects to sign-in if not authenticated
13. ✅ Script verifies post-job page checks user role via clerkClient.getUser
14. ✅ Script verifies post-job page checks for SHIPPER role
15. ✅ Script verifies post-job page redirects to /choose-role if role missing
16. ✅ Script verifies post-job page redirects MOVER to /mover
17. ✅ Script runs `pnpm build` successfully
18. ✅ Script runs `pnpm lint` successfully (warnings ok, errors not)

**All checks must pass (exit code 0)**

## Manual test checklist

### Local Testing

1. **Signed-out visiting /mover**:
   - Navigate to `http://localhost:3000/mover`
   - Expected: Redirects to `/sign-in`
   - Status: ⚠️ Manual test required

2. **Signed-out visiting /post-job**:
   - Navigate to `http://localhost:3000/post-job`
   - Expected: Redirects to `/sign-in`
   - Status: ⚠️ Manual test required

3. **Signed-in user with no role**:
   - Sign in with a user that has no role set
   - Navigate to `/mover`
   - Expected: Redirects to `/choose-role`
   - Navigate to `/post-job`
   - Expected: Redirects to `/choose-role`
   - Status: ⚠️ Manual test required

4. **Signed-in SHIPPER accessing /mover**:
   - Sign in with a SHIPPER role
   - Navigate to `/mover`
   - Expected: Redirects to `/post-job` (wrong role)
   - Status: ⚠️ Manual test required

5. **Signed-in SHIPPER accessing /post-job**:
   - Sign in with a SHIPPER role
   - Navigate to `/post-job`
   - Expected: Page loads successfully (correct role)
   - Status: ⚠️ Manual test required

6. **Signed-in MOVER accessing /post-job**:
   - Sign in with a MOVER role
   - Navigate to `/post-job`
   - Expected: Redirects to `/mover` (wrong role)
   - Status: ⚠️ Manual test required

7. **Signed-in MOVER accessing /mover**:
   - Sign in with a MOVER role
   - Navigate to `/mover`
   - Expected: Page loads successfully (correct role)
   - Status: ⚠️ Manual test required

### Production Testing

1. **Deploy to Vercel**:
   ```powershell
   npx vercel --prod
   ```

2. **Test signed-out redirects**:
   - Visit `https://moving-marketplace.vercel.app/mover`
   - Expected: Redirects to `/sign-in`
   - Visit `https://moving-marketplace.vercel.app/post-job`
   - Expected: Redirects to `/sign-in`
   - Status: ⚠️ Manual test required

3. **Test role-based access**:
   - Sign in with SHIPPER role
   - Visit `/mover` → should redirect to `/post-job`
   - Visit `/post-job` → should load successfully
   - Sign in with MOVER role
   - Visit `/post-job` → should redirect to `/mover`
   - Visit `/mover` → should load successfully
   - Status: ⚠️ Manual test required

4. **Test no-role redirect**:
   - Sign in with user that has no role
   - Visit `/mover` → should redirect to `/choose-role`
   - Visit `/post-job` → should redirect to `/choose-role`
   - Status: ⚠️ Manual test required

## Stop conditions

### If Phase 7 gate fails:

**Symptom**: Script exits with non-zero code

**Diagnostic commands:**
```powershell
# Check if mover page exists and has role check
Test-Path app\mover\page.tsx
Get-Content app\mover\page.tsx | Select-String -Pattern "clerkClient|getUser|MOVER|redirect"

# Check if post-job page exists and has role check
Test-Path app\post-job\page.tsx
Get-Content app\post-job\page.tsx | Select-String -Pattern "clerkClient|getUser|SHIPPER|redirect"

# Check if PostJobForm component exists
Test-Path app\post-job\PostJobForm.tsx

# Try building manually
pnpm -s build 2>&1 | Out-File build-error.log
Get-Content build-error.log

# Try linting manually
pnpm -s lint 2>&1 | Out-File lint-error.log
Get-Content lint-error.log
```

**Fix steps:**
1. If mover page missing role check, add `clerkClient().getUser()` check for MOVER role
2. If post-job page missing role check, ensure it's a server component with SHIPPER role check
3. If PostJobForm is missing, ensure form component was extracted to separate file
4. If build fails, check TypeScript errors in build output
5. If lint fails with errors, fix linting errors (warnings are ok)

### If production deployment fails:

**Symptom**: Vercel build fails or role enforcement doesn't work

**Diagnostic commands:**
```powershell
# Check Vercel build logs
npx vercel logs --follow

# Verify environment variables
npx vercel env ls
```

**Fix steps:**
1. Check Vercel build logs for errors
2. Verify Clerk keys are set in Vercel (CLERK_SECRET_KEY needed for clerkClient)
3. Verify CLERK_SECRET_KEY is correct
4. Test role enforcement manually after deployment

## Git commit message

```
Phase 7: enforce role-based access on mover + post-job + gate
```

## Notes

- **Server-Side Checks**: All role checks are done server-side in server components using `clerkClient().getUser()` to read `publicMetadata.role`.

- **No Middleware Changes**: Phase 7 does NOT modify middleware. All checks are in page components.

- **Redirect Flow**:
  - Not authenticated → `/sign-in`
  - Authenticated but no role → `/choose-role`
  - Wrong role:
    - MOVER accessing `/post-job` → redirect to `/mover`
    - SHIPPER accessing `/mover` → redirect to `/post-job`

- **Post-Job Refactoring**: The `/post-job` page was converted from a client component to a server component wrapper that checks role, then renders the client form component (`PostJobForm.tsx`). This maintains existing form functionality while adding server-side role enforcement.

- **Mover Page**: Already was a server component, so role check was simply added after auth check.

- **Existing Behavior**: `/jobs` and `/jobs/[id]` routes are NOT modified - they remain accessible as before (Phase 4/5 behavior preserved).

- **Role Storage**: Roles are still stored in Clerk's `publicMetadata.role` (no database changes).

- **Performance**: Role checks use `clerkClient().getUser()` which is a server-side API call. This is acceptable for protected routes that require auth anyway.


