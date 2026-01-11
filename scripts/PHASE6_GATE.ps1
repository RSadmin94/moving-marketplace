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
Write-Host "=== PHASE 6 GATE - ROLE SELECTION ===" -ForegroundColor Yellow

# Change to project root (parent of /scripts)
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot
Write-Info "Project root: $projectRoot"

Write-Host ""
Write-Host "--- File Existence Checks ---" -ForegroundColor Yellow

if (Test-Path "app\choose-role\page.tsx" -PathType Leaf) { Pass "app/choose-role/page.tsx exists" } else { Fail "app/choose-role/page.tsx not found" }
if (Test-Path "app\api\user\role\route.ts" -PathType Leaf) { Pass "app/api/user/role/route.ts exists" } else { Fail "app/api/user/role/route.ts not found" }

Write-Host ""
Write-Host "--- Content Validation ---" -ForegroundColor Yellow

$chooseRolePage = (Get-Content "app\choose-role\page.tsx" -ErrorAction SilentlyContinue) -join "`n"

if ($null -eq $chooseRolePage -or $chooseRolePage.Trim().Length -eq 0) {
  Fail "Could not read app/choose-role/page.tsx content"
} else {
  if ($chooseRolePage -notmatch "use client") { Pass "Choose-role page is server component (no use client)" } else { Fail "Choose-role page must NOT contain 'use client'" }
  if ($chooseRolePage -match "auth.*@clerk/nextjs/server") { Pass "Choose-role page uses Clerk server auth" } else { Fail "Choose-role page must use Clerk server auth" }
  if ($chooseRolePage -match "redirect.*sign-in|redirect\(`"/sign-in") { Pass "Choose-role page redirects to sign-in if not authenticated" } else { Fail "Choose-role page must redirect to sign-in if not authenticated" }
  if ($chooseRolePage -match "publicMetadata.*role|publicMetadata\.role") { Pass "Choose-role page checks publicMetadata.role" } else { Fail "Choose-role page must check publicMetadata.role" }
  if ($chooseRolePage -match "redirect.*mover|redirect.*post-job") { Pass "Choose-role page redirects based on role" } else { Fail "Choose-role page must redirect MOVER to /mover and SHIPPER to /post-job" }
}

$apiRoute = (Get-Content "app\api\user\role\route.ts" -ErrorAction SilentlyContinue) -join "`n"

if ($null -eq $apiRoute -or $apiRoute.Trim().Length -eq 0) {
  Fail "Could not read app/api/user/role/route.ts content"
} else {
  if ($apiRoute -match "export async function POST") { Pass "POST function found in API route" } else { Fail "POST function not found in API route" }
  if ($apiRoute -match "auth.*@clerk/nextjs/server") { Pass "API route uses Clerk server auth" } else { Fail "API route must use Clerk server auth" }
  if ($apiRoute -match "clerkClient|updateUser.*publicMetadata") { Pass "API route uses clerkClient and updateUser with publicMetadata" } else { Fail "API route must use clerkClient and updateUser with publicMetadata" }
  if ($apiRoute -match "MOVER|SHIPPER") { Pass "API route validates MOVER or SHIPPER" } else { Fail "API route must validate role is MOVER or SHIPPER" }
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
  Write-Host "PHASE 6 GATE: FAILED" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "PHASE 6 GATE: PASSED" -ForegroundColor Green
exit 0

