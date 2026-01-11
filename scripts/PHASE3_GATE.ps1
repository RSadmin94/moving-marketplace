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
Write-Host "=== PHASE 3 GATE - JOBS LISTING ===" -ForegroundColor Yellow

# Change to project root (parent of /scripts)
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot
Write-Info "Project root: $projectRoot"

Write-Host ""
Write-Host "--- File Existence Checks ---" -ForegroundColor Yellow

if (Test-Path "app\jobs\page.tsx" -PathType Leaf) { Pass "app/jobs/page.tsx exists" } else { Fail "app/jobs/page.tsx not found" }
if (Get-ChildItem -Path "app\jobs" -Recurse -Filter "page.tsx" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match "\\app\\jobs\\\[\w+\]\\page\.tsx$" }) { Pass "app/jobs/[id]/page.tsx exists" } else { Fail "app/jobs/[id]/page.tsx not found" }
if (Test-Path "app\post-job\page.tsx" -PathType Leaf) { Pass "app/post-job/page.tsx exists" } else { Fail "app/post-job/page.tsx not found" }

Write-Host ""
Write-Host "--- Content Validation ---" -ForegroundColor Yellow

$jobsPage = Get-Content "app\jobs\page.tsx" -Raw -ErrorAction SilentlyContinue

if ($null -eq $jobsPage -or $jobsPage.Trim().Length -eq 0) {
  Fail "Could not read app/jobs/page.tsx content"
} else {
  if ($jobsPage -match "prisma\.job\.findMany") { Pass "Jobs page uses Prisma findMany" } else { Fail "Jobs page should use prisma.job.findMany" }
  if ($jobsPage -notmatch "use client") { Pass "Jobs page is server component (no use client)" } else { Fail "Jobs page must NOT contain 'use client'" }
  if ($jobsPage -match "jobs\.length\s*===\s*0") { Pass "Jobs page handles empty state" } else { Fail "Jobs page should handle empty state (jobs.length === 0)" }
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
  Write-Host "PHASE 3 GATE: FAILED" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "PHASE 3 GATE: PASSED" -ForegroundColor Green
exit 0
