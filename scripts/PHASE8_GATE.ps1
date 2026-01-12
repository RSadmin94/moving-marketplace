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
Write-Host "=== PHASE 8 GATE - SHIPPER DASHBOARD ===" -ForegroundColor Yellow

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot
Write-Info "Project root: $projectRoot"

Write-Host ""
Write-Host "--- File Existence Checks ---" -ForegroundColor Yellow

if (Test-Path "app\shipper\page.tsx" -PathType Leaf) { Pass "app/shipper/page.tsx exists" } else { Fail "app/shipper/page.tsx not found" }

# Check for job detail page (use -LiteralPath to avoid bracket interpretation)
$jobDetailPath = "app\shipper\jobs\[id]\page.tsx"
if (Test-Path -LiteralPath $jobDetailPath -PathType Leaf) { Pass "app/shipper/jobs/[id]/page.tsx exists" } else { Fail "app/shipper/jobs/[id]/page.tsx not found" }

Write-Host ""
Write-Host "--- Schema Validation ---" -ForegroundColor Yellow

$schemaContent = Get-Content "prisma\schema.prisma" -ErrorAction SilentlyContinue
$schema = $schemaContent -join "`n"

if ($null -eq $schema -or $schema.Trim().Length -eq 0) {
  Fail "Could not read prisma/schema.prisma"
} else {
  if ($schema -match "shipperId\s+String") { Pass "Job.shipperId field exists in schema" } else { Fail "Job.shipperId field missing from schema" }
  if ($schema -match 'shipper.*User.*relation.*ShipperJobs') { Pass "Job.shipper relation exists" } else { Fail "Job.shipper relation missing" }
  if ($schema -match 'shipperJobs.*Job.*relation.*ShipperJobs') { Pass "User.shipperJobs relation exists" } else { Fail "User.shipperJobs relation missing" }
}

Write-Host ""
Write-Host "--- API Validation ---" -ForegroundColor Yellow

$apiJobsContent = Get-Content "app\api\jobs\route.ts" -ErrorAction SilentlyContinue
$apiJobs = $apiJobsContent -join "`n"

if ($null -eq $apiJobs) {
  Fail "Could not read app/api/jobs/route.ts"
} else {
  if ($apiJobs -match "shipperId:\s*userId") { Pass "POST /api/jobs sets shipperId" } else { Fail "POST /api/jobs does not set shipperId" }
}

Write-Host ""
Write-Host "--- Role Enforcement Validation ---" -ForegroundColor Yellow

$shipperPageContent = Get-Content "app\shipper\page.tsx" -ErrorAction SilentlyContinue
$shipperPage = $shipperPageContent -join "`n"

if ($null -eq $shipperPage) {
  Fail "Could not read app/shipper/page.tsx"
} else {
  if ($shipperPage -match 'redirect\("/sign-in"\)') { Pass "Shipper page redirects unauthenticated users" } else { Fail "Missing auth redirect on shipper page" }
  if ($shipperPage -match 'redirect\("/choose-role"\)') { Pass "Shipper page redirects users without role" } else { Fail "Missing role check on shipper page" }
  if ($shipperPage -match 'role.*===.*"MOVER"') { Pass "Shipper page redirects MOVERs" } else { Fail "Missing MOVER redirect on shipper page" }
  if ($shipperPage -match 'shipperId:\s*userId') { Pass "Shipper page filters jobs by shipperId" } else { Fail "Shipper page missing owner filter" }
}

$shipperJobDetailContent = Get-Content -LiteralPath "app\shipper\jobs\[id]\page.tsx" -ErrorAction SilentlyContinue
$shipperJobDetail = $shipperJobDetailContent -join "`n"

if ($null -eq $shipperJobDetail) {
  Fail "Could not read app/shipper/jobs/[id]/page.tsx"
} else {
  if ($shipperJobDetail -match 'redirect\("/sign-in"\)') { Pass "Job detail page redirects unauthenticated users" } else { Fail "Missing auth redirect on job detail page" }
  if ($shipperJobDetail -match 'shipperId:\s*userId') { Pass "Job detail page verifies job ownership" } else { Fail "Job detail page missing owner verification" }
}

Write-Host ""
Write-Host "--- Build Gate ---" -ForegroundColor Yellow

Write-Info "Running: pnpm build"
pnpm build 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Pass "Build passed" } else { Fail "Build failed" }

Write-Host ""
Write-Host "--- Lint Gate ---" -ForegroundColor Yellow

Write-Info "Running: pnpm lint"
$lintOutput = pnpm lint 2>&1
$lintExitCode = $LASTEXITCODE

# Check if there are errors (not just warnings)
if ($lintExitCode -eq 0 -or ($lintOutput -match "0 errors" -and $lintOutput -notmatch "error")) {
    Pass "Lint passed (warnings allowed)"
} else {
    Fail "Lint failed with errors"
}

Write-Host ""
Write-Host "=== GATE RESULTS ===" -ForegroundColor Yellow
Write-Host ("Passed: {0}  Failed: {1}" -f $passed, $failed)

if ($failed -gt 0) {
  Write-Host ""
  Write-Host "Failures:" -ForegroundColor Red
  foreach ($f in $failures) { Write-Host (" - " + $f) -ForegroundColor Red }
  Write-Host ""
  Write-Host "PHASE 8 GATE: FAILED" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "PHASE 8 GATE: PASSED" -ForegroundColor Green
exit 0
