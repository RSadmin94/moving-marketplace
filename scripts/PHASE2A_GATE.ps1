# Phase 2A Gate: Local env and connectivity
# Verifies .env.local contains required keys and build/lint/test pass

$ErrorActionPreference = "Stop"

function Fail {
    param([string]$msg)
    Write-Host "❌ FAIL: $msg" -ForegroundColor Red
    exit 1
}

function Ok {
    param([string]$msg)
    Write-Host "✅ $msg" -ForegroundColor Green
}

function Step {
    param([string]$msg)
    Write-Host "`n📋 $msg" -ForegroundColor Cyan
}

# Step 1: Ensure we are in repo root
Step "Verifying repo root"
$repoRoot = "C:\Users\RODERICK\Projects\moving-marketplace"
Set-Location $repoRoot
if (-not (Test-Path ".git")) {
    Fail ".git directory not found. Not in repo root."
}
Ok "In repo root: $repoRoot"

# Step 2: Verify .env.local exists
Step "Checking .env.local exists"
$envPath = Join-Path $repoRoot ".env.local"
if (-not (Test-Path $envPath)) {
    Fail ".env.local not found at $envPath"
}
Ok ".env.local found"

# Step 3: Verify required keys exist WITHOUT printing secrets
Step "Verifying required environment keys (without printing values)"
$envContent = Get-Content $envPath -Raw
$envLines = Get-Content $envPath

$hasClerkPublishable = $false
$hasClerkSecret = $false
$hasDatabaseUrl = $false
$hasDatabasePgbouncer = $false
$hasDirectUrl = $false

foreach ($line in $envLines) {
    $trimmed = $line.Trim()
    if ($trimmed -match '^NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=') {
        $hasClerkPublishable = $true
    }
    if ($trimmed -match '^CLERK_SECRET_KEY=') {
        $hasClerkSecret = $true
    }
    if ($trimmed -match '^DATABASE_URL=') {
        $hasDatabaseUrl = $true
        $dbLine = ($trimmed -split '=', 2)[1]
        if ($dbLine -match 'pgbouncer=true') {
            $hasDatabasePgbouncer = $true
        }
    }
    if ($trimmed -match '^DIRECT_URL=') {
        $hasDirectUrl = $true
    }
}

if (-not $hasClerkPublishable) {
    Fail "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY not found in .env.local"
}
Ok "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY exists"

if (-not $hasClerkSecret) {
    Fail "CLERK_SECRET_KEY not found in .env.local"
}
Ok "CLERK_SECRET_KEY exists"

if (-not $hasDatabaseUrl) {
    Fail "DATABASE_URL not found in .env.local"
}
Ok "DATABASE_URL exists"

if (-not $hasDatabasePgbouncer) {
    Fail "DATABASE_URL must include pgbouncer=true (for Supabase connection pooling)"
}
Ok "DATABASE_URL includes pgbouncer=true"

if (-not $hasDirectUrl) {
    Write-Host "⚠️  DIRECT_URL not found (optional for migrations, but recommended for Supabase)" -ForegroundColor Yellow
} else {
    Ok "DIRECT_URL exists"
}

# Step 4: Verify Prisma schema exists
Step "Verifying Prisma schema"
$schemaPath = Join-Path $repoRoot "prisma\schema.prisma"
if (-not (Test-Path $schemaPath)) {
    Fail "prisma/schema.prisma not found"
}
Ok "Prisma schema exists"

# Step 5: Generate Prisma client (ensures schema is valid)
Step "Generating Prisma client"
try {
    & pnpm prisma generate
    if ($LASTEXITCODE -ne 0) {
        Fail "prisma generate failed with exit code $LASTEXITCODE"
    }
    Ok "Prisma client generated successfully"
} catch {
    Fail "prisma generate failed: $_"
}

# Step 6: Run build
Step "Running build"
try {
    & pnpm -s build
    if ($LASTEXITCODE -ne 0) {
        Fail "Build failed with exit code $LASTEXITCODE"
    }
    Ok "Build succeeded"
} catch {
    Fail "Build failed: $_"
}

# Step 7: Run lint (if configured)
Step "Checking if lint is configured"
$packageJson = Get-Content "package.json" | ConvertFrom-Json
if ($packageJson.scripts.lint) {
    Step "Running lint"
    try {
        & pnpm -s lint
        if ($LASTEXITCODE -ne 0) {
            Fail "Lint failed with exit code $LASTEXITCODE"
        }
        Ok "Lint passed"
    } catch {
        Fail "Lint failed: $_"
    }
} else {
    Ok "Lint script not configured, skipping"
}

# Step 8: Run test (if configured)
Step "Checking if test is configured"
if ($packageJson.scripts.test) {
    Step "Running tests"
    try {
        & pnpm -s test
        if ($LASTEXITCODE -ne 0) {
            Fail "Tests failed with exit code $LASTEXITCODE"
        }
        Ok "Tests passed"
    } catch {
        Fail "Tests failed: $_"
    }
} else {
    Ok "Test script not configured, skipping"
}

Write-Host "`n✅ PHASE 2A GATE PASSED" -ForegroundColor Green
Write-Host "All checks passed. Ready for Phase 2B (DB migration)." -ForegroundColor Green

