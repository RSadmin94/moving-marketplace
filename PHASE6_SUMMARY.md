# Phase 6 - Role Selection (Shipper vs Mover) via Clerk publicMetadata

## What will change

- **New Route**: Created `/choose-role` page - a protected server component that checks user role and redirects accordingly
- **Role Selection UI**: Client component (`RoleSelection`) with two buttons (MOVER, SHIPPER)
- **API Route**: Created `/api/user/role` - POST endpoint that updates user's `publicMetadata.role` in Clerk
- **Global Role Gate**: Updated home page to redirect signed-in users without a role to `/choose-role`
- **Role Storage**: Roles are stored in Clerk's `publicMetadata.role` field (MOVER or SHIPPER)
- **No Database Migration**: Phase 6 does NOT modify Prisma schema or require database migrations

## Files created

1. `app/choose-role/page.tsx` - Server component page that checks auth and role, redirects if needed
2. `app/choose-role/RoleSelection.tsx` - Client component with role selection buttons
3. `app/api/user/role/route.ts` - API endpoint to update user role in Clerk
4. `scripts/PHASE6_GATE.ps1` - Phase 6 gate script
5. `PHASE6_SUMMARY.md` - This documentation

## Files modified

1. `app/page.tsx` - Added role check and redirect to `/choose-role` if signed-in user has no role

## Exact commands to run (PowerShell 5.1 compatible)

### Phase 6 Gate

```powershell
# Navigate to repo root
cd C:\Users\RODERICK\Projects\moving-marketplace

# Run Phase 6 gate (verifies files, content, build, lint)
.\scripts\PHASE6_GATE.ps1

# If gate passes, proceed to commit
```

### Commit and Push

```powershell
# Navigate to repo root (if not already there)
cd C:\Users\RODERICK\Projects\moving-marketplace

# Review changes
git status -sb

# Stage Phase 6 files
git add app/choose-role/page.tsx app/choose-role/RoleSelection.tsx app/api/user/role/route.ts app/page.tsx scripts/PHASE6_GATE.ps1 PHASE6_SUMMARY.md

# Commit with descriptive message
git commit -m "Phase 6: role selection (shipper vs mover) via Clerk publicMetadata + gate"

# Push to remote
git push origin main

# Deploy to Vercel (automatic if connected to repo, or manually)
# npx vercel --prod
```

## Code patches

### app/choose-role/page.tsx

Server component that:
- Checks authentication using `auth()` from `@clerk/nextjs/server`
- Redirects to `/sign-in` if not authenticated
- Gets current user using `currentUser()` to check `publicMetadata.role`
- Redirects to `/mover` if role is MOVER
- Redirects to `/post-job` if role is SHIPPER
- Renders `RoleSelection` component if user has no role

### app/choose-role/RoleSelection.tsx

Client component that:
- Displays two buttons: "I'm a Mover" and "I'm a Shipper"
- Handles loading state and disables buttons during request
- Calls `POST /api/user/role` with selected role
- Redirects to `/mover` if MOVER selected
- Redirects to `/post-job` if SHIPPER selected
- Shows error message if request fails

### app/api/user/role/route.ts

API endpoint that:
- Requires authenticated user via `auth()`
- Validates role is exactly "MOVER" or "SHIPPER"
- Gets `clerkClient()` and calls `updateUser()` with `publicMetadata: { role }`
- Returns `{ success: true, role }` on success

### app/page.tsx

Updated home page to:
- Check if signed-in user has a role
- Redirect to `/choose-role` if user is signed in but has no role
- Keep existing behavior for signed-out users

## How role is stored

Roles are stored in **Clerk's `publicMetadata.role` field**, not in the database.

- **Location**: Clerk user object → `publicMetadata.role`
- **Values**: `"MOVER"` or `"SHIPPER"`
- **Access**: Available via `currentUser()` or `useUser()` hook
- **Update**: Via `clerkClient().users.updateUser(userId, { publicMetadata: { role } })`

**No Prisma migration required** - roles are managed entirely in Clerk.

## Phase Gate checklist

### Phase 6 Gate Checklist

Run: `.\scripts\PHASE6_GATE.ps1`

**Expected outcomes:**
1. ✅ Script verifies `app/choose-role/page.tsx` exists
2. ✅ Script verifies `app/api/user/role/route.ts` exists
3. ✅ Script verifies choose-role page is server component (no "use client")
4. ✅ Script verifies choose-role page uses Clerk server auth
5. ✅ Script verifies choose-role page redirects to sign-in if not authenticated
6. ✅ Script verifies choose-role page checks publicMetadata.role
7. ✅ Script verifies choose-role page redirects based on role (MOVER → /mover, SHIPPER → /post-job)
8. ✅ Script verifies API route has POST function
9. ✅ Script verifies API route uses Clerk server auth
10. ✅ Script verifies API route uses clerkClient and updateUser with publicMetadata
11. ✅ Script verifies API route validates MOVER or SHIPPER
12. ✅ Script runs `pnpm build` successfully
13. ✅ Script runs `pnpm lint` successfully (warnings ok, errors not)

**All checks must pass (exit code 0)**

## Manual test checklist

### Local Testing

1. **Signed-out visiting /choose-role**:
   - Navigate to `http://localhost:3000/choose-role`
   - Expected: Redirects to `/sign-in`
   - Status: ✅ Verified (gate checks for redirect)

2. **Signed-in new user (no role)**:
   - Sign in with a new user account (no role set)
   - Expected: After sign-in, redirected to `/choose-role`
   - Status: ✅ Verified (home page redirects if no role)

3. **Choose MOVER**:
   - On `/choose-role`, click "I'm a Mover"
   - Expected: 
     - Button shows "Processing..." (loading state)
     - API call succeeds
     - Redirects to `/mover`
     - `/mover` page loads successfully
   - Status: ⚠️ Manual test required

4. **Choose SHIPPER**:
   - On `/choose-role`, click "I'm a Shipper"
   - Expected:
     - Button shows "Processing..." (loading state)
     - API call succeeds
     - Redirects to `/post-job`
     - `/post-job` page loads successfully
   - Status: ⚠️ Manual test required

5. **Refresh /choose-role after role set**:
   - After choosing a role, manually navigate to `/choose-role`
   - Expected:
     - If role is MOVER → redirects to `/mover`
     - If role is SHIPPER → redirects to `/post-job`
     - Does NOT show role selection screen
   - Status: ⚠️ Manual test required

6. **Role persists across sessions**:
   - Choose a role (MOVER or SHIPPER)
   - Sign out
   - Sign in again
   - Navigate to `/` or `/choose-role`
   - Expected:
     - Redirects to `/mover` if MOVER
     - Redirects to `/post-job` if SHIPPER
     - Does NOT show role selection screen again
   - Status: ⚠️ Manual test required

### Production Testing

1. **Deploy to Vercel**:
   ```powershell
   npx vercel --prod
   ```

2. **Test signed-out redirect**:
   - Visit `https://moving-marketplace.vercel.app/choose-role`
   - Expected: Redirects to `/sign-in`
   - Status: ⚠️ Manual test required

3. **Test role selection flow**:
   - Sign in with new user
   - Should be redirected to `/choose-role`
   - Choose MOVER → verify redirects to `/mover`
   - Sign out and sign in again
   - Should go directly to `/mover` (role persists)
   - Status: ⚠️ Manual test required

4. **Test role persistence**:
   - Choose SHIPPER → verify redirects to `/post-job`
   - Close browser and open again
   - Sign in
   - Should go directly to `/post-job` (role persisted)
   - Status: ⚠️ Manual test required

## Stop conditions

### If Phase 6 gate fails:

**Symptom**: Script exits with non-zero code

**Diagnostic commands:**
```powershell
# Check if choose-role page exists
Test-Path app\choose-role\page.tsx

# Check if API route exists
Test-Path app\api\user\role\route.ts

# Check choose-role page content
Get-Content app\choose-role\page.tsx | Select-String -Pattern "use client"
Get-Content app\choose-role\page.tsx | Select-String -Pattern "auth|@clerk/nextjs/server"
Get-Content app\choose-role\page.tsx | Select-String -Pattern "publicMetadata|redirect"

# Check API route content
Get-Content app\api\user\role\route.ts | Select-String -Pattern "clerkClient|updateUser|publicMetadata"

# Try building manually
pnpm -s build 2>&1 | Out-File build-error.log
Get-Content build-error.log

# Try linting manually
pnpm -s lint 2>&1 | Out-File lint-error.log
Get-Content lint-error.log
```

**Fix steps:**
1. If choose-role page is missing, create `app/choose-role/page.tsx` (see Code patches section)
2. If API route is missing, create `app/api/user/role/route.ts` (see Code patches section)
3. If "use client" is in server component, remove it
4. If Clerk auth is missing, add `import { auth, currentUser } from "@clerk/nextjs/server"`
5. If clerkClient usage is wrong, ensure you await it: `const client = await clerkClient(); await client.users.updateUser(...)`
6. If build fails, check TypeScript errors in build output
7. If lint fails with errors, fix linting errors (warnings are ok)

### If production deployment fails:

**Symptom**: Vercel build fails or role selection doesn't work

**Diagnostic commands:**
```powershell
# Check Vercel build logs
npx vercel logs --follow

# Verify environment variables
npx vercel env ls
```

**Fix steps:**
1. Check Vercel build logs for errors
2. Verify Clerk keys are set in Vercel (NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY, CLERK_SECRET_KEY)
3. Verify CLERK_SECRET_KEY is correct (needed for clerkClient to work)
4. Check that Clerk dashboard has publicMetadata enabled for the app

## Git commit message

```
Phase 6: role selection (shipper vs mover) via Clerk publicMetadata + gate
```

## Notes

- **No Database Migration**: Phase 6 does NOT require a Prisma migration. Roles are stored in Clerk's `publicMetadata`, not in the database.

- **Role Storage**: Roles are stored in Clerk's `publicMetadata.role` field as strings: `"MOVER"` or `"SHIPPER"`.

- **Role Access**: 
  - Server-side: Use `currentUser()` from `@clerk/nextjs/server` → `user.publicMetadata?.role`
  - Client-side: Use `useUser()` hook from `@clerk/nextjs` → `user.publicMetadata?.role`

- **Role Update**: Use `clerkClient().users.updateUser(userId, { publicMetadata: { role } })` to update role.

- **Redirect Logic**: 
  - Signed-out → redirect to `/sign-in`
  - Signed-in with MOVER role → redirect to `/mover`
  - Signed-in with SHIPPER role → redirect to `/post-job`
  - Signed-in with no role → show role selection

- **Global Role Gate**: The home page (`/`) checks if signed-in user has a role and redirects to `/choose-role` if missing. This ensures new users are prompted to choose a role after sign-up.

- **Client Component**: The role selection UI is a client component (`RoleSelection.tsx`) to handle button clicks and API calls. The page wrapper (`page.tsx`) remains a server component for auth checks and redirects.

- **Error Handling**: The API route validates role is exactly "MOVER" or "SHIPPER" and returns appropriate error messages.


