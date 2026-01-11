param()

$ErrorActionPreference = "Stop"

function Write-Info($msg)    { Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "[PASS]  $msg" -ForegroundColor Green }
function Write-Failure($msg) { Write-Host "[FAIL]  $msg" -ForegroundColor Red }

$passed = 0
$failed = 0
$failures = New-Object System.Collections.Generic.List[string]

function Pass($msg) { $script:passed++; Write-Success $msg }
function Fail($msg) { $script:failed++; $script:failures.Add($msg); Write-Failure $msg }

Write-Host ""
Write-Host "=== PHASE 7 GATE - ROLE-BASED ACCESS ENFORCEMENT ===" -ForegroundColor Yellow

# Change to project root (parent of /scripts)
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot
Write-Info "Project root: $projectRoot"

Write-Host ""
Write-Host "--- File Existence Checks ---" -ForegroundColor Yellow

if (Test-Path "app\mover\page.tsx" -PathType Leaf) { Pass "app/mover/page.tsx exists" } else { Fail "app/mover/page.tsx not found" }
if (Test-Path "app\post-job\page.tsx" -PathType Leaf) { Pass "app/post-job/page.tsx exists" } else { Fail "app/post-job/page.tsx not found" }

Write-Host ""
Write-Host "--- Content Validation ---" -ForegroundColor Yellow

$moverPage = (Get-Content "app\mover\page.tsx" -ErrorAction SilentlyContinue) -join "`n"

if ($null -eq $moverPage -or $moverPage.Trim().Length -eq 0) {
  Fail "Could not read app/mover/page.tsx content"
} else {
  if ($moverPage -notmatch "use client") { Pass "Mover page is server component (no use client)" } else { Fail "Mover page must NOT contain 'use client'" }
  if ($moverPage -match "auth.*@clerk/nextjs/server") { Pass "Mover page uses Clerk server auth" } else { Fail "Mover page must use Clerk server auth" }
  if ($moverPage -match "redirect.*sign-in|redirect\(`"/sign-in") { Pass "Mover page redirects to sign-in if not authenticated" } else { Fail "Mover page must redirect to sign-in if not authenticated" }
  if ($moverPage -match "clerkClient|getUser|publicMetadata.*role") { Pass "Mover page checks user role" } else { Fail "Mover page must check user role via clerkClient.getUser" }
  if ($moverPage -match "role.*MOVER|MOVER.*role") { Pass "Mover page checks for MOVER role" } else { Fail "Mover page must check role === MOVER" }
  if ($moverPage -match "redirect.*choose-role|redirect\(`"/choose-role") { Pass "Mover page redirects to choose-role if role missing" } else { Fail "Mover page must redirect to /choose-role if role missing" }
  if ($moverPage -match "redirect.*post-job|redirect\(`"/post-job") { Pass "Mover page redirects SHIPPER to /post-job" } else { Fail "Mover page must redirect SHIPPER to /post-job" }
}

$postJobPage = (Get-Content "app\post-job\page.tsx" -ErrorAction SilentlyContinue) -join "`n"

if ($null -eq $postJobPage -or $postJobPage.Trim().Length -eq 0) {
  Fail "Could not read app/post-job/page.tsx content"
} else {
  if ($postJobPage -notmatch "use client") { Pass "Post-job page is server component (no use client)" } else { Fail "Post-job page must NOT contain 'use client' (should be server wrapper)" }
  if ($postJobPage -match "auth.*@clerk/nextjs/server") { Pass "Post-job page uses Clerk server auth" } else { Fail "Post-job page must use Clerk server auth" }
  if ($postJobPage -match "redirect.*sign-in|redirect\(`"/sign-in") { Pass "Post-job page redirects to sign-in if not authenticated" } else { Fail "Post-job page must redirect to sign-in if not authenticated" }
  if ($postJobPage -match "clerkClient|getUser|publicMetadata.*role") { Pass "Post-job page checks user role" } else { Fail "Post-job page must check user role via clerkClient.getUser" }
  if ($postJobPage -match "role.*SHIPPER|SHIPPER.*role") { Pass "Post-job page checks for SHIPPER role" } else { Fail "Post-job page must check role === SHIPPER" }
  if ($postJobPage -match "redirect.*choose-role|redirect\(`"/choose-role") { Pass "Post-job page redirects to choose-role if role missing" } else { Fail "Post-job page must redirect to /choose-role if role missing" }
  if ($postJobPage -match "redirect.*mover|redirect\(`"/mover") { Pass "Post-job page redirects MOVER to /mover" } else { Fail "Post-job page must redirect MOVER to /mover" }
}

Write-Host ""
Write-Host "--- Build Gate ---" -ForegroundColor Yellow

Write-Info "Running: pnpm build"
pnpm build 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Pass "Build passed" } else { Fail "Build failed" }

Write-Host ""
Write-Host "--- Lint Gate ---" -ForegroundColor Yellow

Write-Info "Running: pnpm lint"
pnpm lint 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Pass "Lint passed" } else { 
  # Check if only warnings (non-zero but no errors)
  $lintOutput = pnpm lint 2>&1 | Out-String
  if ($lintOutput -match "error") {
    Fail "Lint failed with errors"
  } else {
    Pass "Lint passed (warnings only)"
  }
}

Write-Host ""
Write-Host "=== GATE RESULTS ===" -ForegroundColor Yellow
Write-Host ("Passed: {0}  Failed: {1}" -f $passed, $failed)

if ($failed -gt 0) {
  Write-Host ""
  Write-Host "Failures:" -ForegroundColor Red
  foreach ($f in $failures) { Write-Host (" - " + $f) -ForegroundColor Red }
  Write-Host ""
  Write-Host "PHASE 7 GATE: FAILED" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "PHASE 7 GATE: PASSED" -ForegroundColor Green
exit 0


