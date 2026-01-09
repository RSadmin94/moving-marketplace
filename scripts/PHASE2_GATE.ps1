# PHASE2_GATE.ps1
# Deterministic Phase 2 Gate – no guessing, no partial state

$ErrorActionPreference = "Stop"

Write-Host "`n=== PHASE 2 GATE START ===`n" -ForegroundColor Cyan

# 0) Sanity: must be in repo root
if (-not (Test-Path ".git")) {
  throw "Not in git repo root. STOP."
}

# 1) Git must be clean
$gitStatus = git status --porcelain
if ($gitStatus) {
  Write-Host "❌ Git working tree not clean:" -ForegroundColor Red
  git status
  throw "Clean or stash changes before running Phase 2 Gate."
}
Write-Host "✔ Git working tree clean"

# 2) Ensure required directories
New-Item -ItemType Directory -Force "app\sign-in\[[...sign-in]]" | Out-Null
New-Item -ItemType Directory -Force "app\sign-up\[[...sign-up]]" | Out-Null

# 3) Write sign-in page
$signIn = @'
import { SignIn } from "@clerk/nextjs";

export default function Page() {
  return <SignIn />;
}
'@
[System.IO.File]::WriteAllText(
  "app\sign-in\[[...sign-in]]\page.tsx",
  $signIn,
  New-Object System.Text.UTF8Encoding($false)
)

# 4) Write sign-up page
$signUp = @'
import { SignUp } from "@clerk/nextjs";

export default function Page() {
  return <SignUp />;
}
'@
[System.IO.File]::WriteAllText(
  "app\sign-up\[[...sign-up]]\page.tsx",
  $signUp,
  New-Object System.Text.UTF8Encoding($false)
)

# 5) Write middleware (public auth routes)
$middleware = @'
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isPublicRoute = createRouteMatcher([
  "/",
  "/sign-in(.*)",
  "/sign-up(.*)",
  "/api/health",
  "/api/webhooks/clerk",
]);

export default clerkMiddleware(() => {});

export const config = {
  matcher: ["/((?!.*\\..*|_next).*)", "/", "/(api|trpc)(.*)"],
};
'@
[System.IO.File]::WriteAllText(
  "middleware.ts",
  $middleware,
  New-Object System.Text.UTF8Encoding($false)
)

# 6) Ensure Prisma generates on Vercel
$pkg = Get-Content package.json -Raw | ConvertFrom-Json
if (-not $pkg.scripts.postinstall) {
  Write-Host "Adding postinstall: prisma generate"
  $pkg.scripts | Add-Member -NotePropertyName postinstall -NotePropertyValue "prisma generate"
  ($pkg | ConvertTo-Json -Depth 10) | Set-Content package.json -Encoding UTF8
}

# 7) Local build MUST pass
Write-Host "`nRunning pnpm build (gate)..." -ForegroundColor Cyan
pnpm build
if ($LASTEXITCODE -ne 0) {
  throw "❌ pnpm build failed. NOTHING committed."
}

# 8) Commit + push
git add middleware.ts app\sign-in app\sign-up app\layout.tsx package.json
git commit -m "Phase 2 gate: canonical Clerk auth + Prisma generate"
git push origin main

Write-Host "`n✅ PHASE 2 GATE COMPLETE" -ForegroundColor Green
Write-Host "Next: wait for Vercel deploy, then test /sign-up" -ForegroundColor Cyan
