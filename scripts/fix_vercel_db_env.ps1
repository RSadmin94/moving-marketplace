cd C:\Users\RODERICK\Projects\moving-marketplace
$ErrorActionPreference="Stop"

# Hardcoded password (will rotate after)
$pwd = "IXSQ8k65Rs6k4V"

# Build CORRECT URLs
# DATABASE_URL: pooler connection with full username
$dbUrl = "postgresql://postgres.ntxvnfuyunodmdmimkej:$pwd@aws-1-us-east-2.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1&sslmode=require"

# DIRECT_URL: direct connection with simple 'postgres' username and direct host
$directUrl = "postgresql://postgres:$pwd@db.ntxvnfuyunodmdmimkej.supabase.co:5432/postgres?sslmode=require"

Write-Host "=== Setting DATABASE_URL (Production) ===" -ForegroundColor Cyan
# Feed answers to prompts: sensitive? yes, then value
@"
yes
$dbUrl
"@ | npx vercel env add DATABASE_URL production

Write-Host "=== Setting DIRECT_URL (Production) ===" -ForegroundColor Cyan
@"
yes
$directUrl
"@ | npx vercel env add DIRECT_URL production

Write-Host "=== Listing env vars (names only) ===" -ForegroundColor Cyan
npx vercel env ls

Write-Host "=== Force redeploy (no cache) ===" -ForegroundColor Cyan
npx vercel --prod --force

Write-Host "=== Verify /shipper (GET no redirects) ===" -ForegroundColor Cyan
try {
  $r = Invoke-WebRequest https://moving-marketplace.vercel.app/shipper -Method Get -MaximumRedirection 0 -UseBasicParsing
  Write-Host ("StatusCode: " + $r.StatusCode) -ForegroundColor Green
} catch {
  if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
    Write-Host ("StatusCode: " + [int]$_.Exception.Response.StatusCode) -ForegroundColor Yellow
  } else {
    throw
  }
}

Write-Host ""
Write-Host "⚠️  CRITICAL: Rotate your Supabase password NOW!" -ForegroundColor Red
Write-Host "   Go to: Supabase → Project Settings → Database → Reset Database Password" -ForegroundColor Yellow
Write-Host ""
