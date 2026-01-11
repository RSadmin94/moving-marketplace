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
Write-Host "=== PHASE 4 GATE - EXPRESS INTEREST ===" -ForegroundColor Yellow

# Change to project root (parent of /scripts)
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot
Write-Info "Project root: $projectRoot"

Write-Host ""
Write-Host "--- File Existence Checks ---" -ForegroundColor Yellow

if (Test-Path "app\api\interests\route.ts" -PathType Leaf) { Pass "app/api/interests/route.ts exists" } else { Fail "app/api/interests/route.ts not found" }
if (Test-Path -LiteralPath "app\jobs\[id]\ExpressInterestButton.tsx" -PathType Leaf) { Pass "app/jobs/[id]/ExpressInterestButton.tsx exists" } else { Fail "app/jobs/[id]/ExpressInterestButton.tsx not found" }

Write-Host ""
Write-Host "--- Schema Validation ---" -ForegroundColor Yellow

$schemaPath = "prisma\schema.prisma"
if (Test-Path $schemaPath -PathType Leaf) {
  $schemaContent = (Get-Content $schemaPath -ErrorAction SilentlyContinue) -join "`n"
  if ($null -eq $schemaContent -or $schemaContent.Trim().Length -eq 0) {
    Fail "Could not read prisma/schema.prisma content"
  } else {
    if ($schemaContent -match "model Interest") { Pass "Interest model found in schema" } else { Fail "Interest model not found in schema" }
    if ($schemaContent -match "jobId\s+String") { Pass "Interest model has jobId field" } else { Fail "Interest model missing jobId field" }
    if ($schemaContent -match "userId\s+String") { Pass "Interest model has userId field" } else { Fail "Interest model missing userId field" }
    if ($schemaContent -match "@@unique.*jobId.*userId") { Pass "Interest model has unique constraint on [jobId, userId]" } else { Fail "Interest model missing unique constraint on [jobId, userId]" }
  }
} else {
  Fail "prisma/schema.prisma not found"
}

Write-Host ""
Write-Host "--- API Route Validation ---" -ForegroundColor Yellow

$apiRoutePath = "app\api\interests\route.ts"
if (Test-Path $apiRoutePath -PathType Leaf) {
  $routeContent = (Get-Content $apiRoutePath -ErrorAction SilentlyContinue) -join "`n"
  if ($null -eq $routeContent -or $routeContent.Trim().Length -eq 0) {
    Fail "Could not read app/api/interests/route.ts content"
  } else {
    if ($routeContent -match "export async function POST") { Pass "POST function found in API route" } else { Fail "POST function not found in API route" }
    if ($routeContent -match "export async function GET") { Pass "GET function found in API route" } else { Fail "GET function not found in API route" }
  }
}

Write-Host ""
Write-Host "--- UI Component Validation ---" -ForegroundColor Yellow

$jobDetailPagePath = "app\jobs\[id]\page.tsx"
if (Test-Path -LiteralPath $jobDetailPagePath -PathType Leaf) {
  try {
    $pageContent = (Get-Content -LiteralPath $jobDetailPagePath -ErrorAction Stop) -join "`n"
    if ($pageContent -match "ExpressInterestButton") { Pass "Job detail page uses ExpressInterestButton" } else { Fail "Job detail page does not use ExpressInterestButton" }
  } catch {
    Fail "Could not read app/jobs/[id]/page.tsx content: $_"
  }
} else {
  Fail "app/jobs/[id]/page.tsx not found"
}

Write-Host ""
Write-Host "--- Prisma Client Generation ---" -ForegroundColor Yellow

Write-Info "Running: pnpm prisma generate"
pnpm prisma generate
if ($LASTEXITCODE -eq 0) { Pass "Prisma client generated" } else { Fail "Prisma client generation failed" }

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
  Write-Host "PHASE 4 GATE: FAILED" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "PHASE 4 GATE: PASSED" -ForegroundColor Green
exit 0
