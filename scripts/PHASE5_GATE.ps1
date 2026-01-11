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
Write-Host "=== PHASE 5 GATE - MOVER DASHBOARD ===" -ForegroundColor Yellow

# Change to project root (parent of /scripts)
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot
Write-Info "Project root: $projectRoot"

Write-Host ""
Write-Host "--- File Existence Checks ---" -ForegroundColor Yellow

if (Test-Path "app\mover\page.tsx" -PathType Leaf) { Pass "app/mover/page.tsx exists" } else { Fail "app/mover/page.tsx not found" }

Write-Host ""
Write-Host "--- Content Validation ---" -ForegroundColor Yellow

$moverPage = (Get-Content "app\mover\page.tsx" -ErrorAction SilentlyContinue) -join "`n"

if ($null -eq $moverPage -or $moverPage.Trim().Length -eq 0) {
  Fail "Could not read app/mover/page.tsx content"
} else {
  if ($moverPage -notmatch "use client") { Pass "Mover page is server component (no use client)" } else { Fail "Mover page must NOT contain 'use client'" }
  if ($moverPage -match "auth.*@clerk/nextjs/server") { Pass "Mover page uses Clerk server auth" } else { Fail "Mover page must use Clerk server auth" }
  if ($moverPage -match "prisma\.interest\.findMany") { Pass "Mover page queries Interest model" } else { Fail "Mover page must query Interest model" }
  if ($moverPage -match "include|job.*select|job.*true") { Pass "Mover page includes job relation" } else { Fail "Mover page must include job relation in query" }
  if ($moverPage -match "originZip|destinationZip|moveDate|createdAt") { Pass "Mover page displays required job fields" } else { Fail "Mover page must display originZip, destinationZip, moveDate, createdAt" }
  if ($moverPage -match "/jobs|href=`"/`"") { Pass "Mover page has links to Home and Jobs" } else { Fail "Mover page must have links to Home and Jobs" }
}

Write-Host ""
Write-Host "--- Build Gate ---" -ForegroundColor Yellow

Write-Info "Running: pnpm build"
pnpm build
if ($LASTEXITCODE -eq 0) { Pass "Build passed" } else { Fail "Build failed" }

Write-Host ""
Write-Host "--- Lint Gate ---" -ForegroundColor Yellow

Write-Info "Running: pnpm lint"
pnpm lint
if ($LASTEXITCODE -eq 0) { Pass "Lint passed" } else { Fail "Lint failed" }

Write-Host ""
Write-Host "=== GATE RESULTS ===" -ForegroundColor Yellow
Write-Host ("Passed: {0}  Failed: {1}" -f $passed, $failed)

if ($failed -gt 0) {
  Write-Host ""
  Write-Host "Failures:" -ForegroundColor Red
  foreach ($f in $failures) { Write-Host (" - " + $f) -ForegroundColor Red }
  Write-Host ""
  Write-Host "PHASE 5 GATE: FAILED" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "PHASE 5 GATE: PASSED" -ForegroundColor Green
exit 0
