$ErrorActionPreference = "Stop"

Write-Host "=== SETTING VERCEL DATABASE CREDENTIALS ===" -ForegroundColor Yellow
Write-Host ""

# Your Supabase credentials
$env:DATABASE_URL = "postgresql://postgres.ntxvnfuyunodmdmimkej:IXSQ8k65Rs6k4V@aws-1-us-east-2.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1"
$env:DIRECT_URL = "postgresql://postgres.ntxvnfuyunodmdmimkej:IXSQ8k65Rs6k4V@aws-1-us-east-2.pooler.supabase.com:5432/postgres"

Write-Host "Adding DATABASE_URL to Vercel..." -ForegroundColor Cyan
Write-Output $env:DATABASE_URL | npx vercel env add DATABASE_URL production

Write-Host "Adding DIRECT_URL to Vercel..." -ForegroundColor Cyan  
Write-Output $env:DIRECT_URL | npx vercel env add DIRECT_URL production

Write-Host ""
Write-Host "Redeploying..." -ForegroundColor Cyan
npx vercel --prod --force

Write-Host ""
Write-Host "✅ DONE! Test: https://moving-marketplace.vercel.app/shipper" -ForegroundColor Green
