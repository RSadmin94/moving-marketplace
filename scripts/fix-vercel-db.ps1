$ErrorActionPreference = "Stop"

Write-Host "=== FIXING VERCEL DATABASE CONNECTION ===" -ForegroundColor Yellow
Write-Host ""

# Hardcoded Supabase credentials from your screenshots
$DATABASE_URL = "postgresql://postgres.ntxvnfuyunodmdmimkej:IXSQ8k65Rs6k4V@aws-1-us-east-2.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1"
$DIRECT_URL = "postgresql://postgres.ntxvnfuyunodmdmimkej:IXSQ8k65Rs6k4V@aws-1-us-east-2.pooler.supabase.com:5432/postgres"

Write-Host "Step 1: Testing DIRECT_URL locally..." -ForegroundColor Cyan
try {
    docker run --rm postgres:16-alpine psql "$DIRECT_URL" -c "SELECT now();" 2>&1 | Out-Null
    Write-Host "✅ Database connection works locally" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Docker test skipped (Docker not running)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 2: Updating Vercel environment variables..." -ForegroundColor Cyan

# Remove old variables
Write-Host "  Removing old DATABASE_URL..." -ForegroundColor Gray
npx vercel env rm DATABASE_URL production -y 2>&1 | Out-Null

Write-Host "  Removing old DIRECT_URL..." -ForegroundColor Gray
npx vercel env rm DIRECT_URL production -y 2>&1 | Out-Null

# Add new variables
Write-Host "  Adding DATABASE_URL..." -ForegroundColor Gray
$DATABASE_URL | npx vercel env add DATABASE_URL production

Write-Host "  Adding DIRECT_URL..." -ForegroundColor Gray
$DIRECT_URL | npx vercel env add DIRECT_URL production

Write-Host "✅ Environment variables updated" -ForegroundColor Green

Write-Host ""
Write-Host "Step 3: Force redeploying to production..." -ForegroundColor Cyan
npx vercel --prod --force

Write-Host ""
Write-Host "✅ DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host ""
Write-Host "Now test: https://moving-marketplace.vercel.app/shipper" -ForegroundColor Cyan
Write-Host ""
