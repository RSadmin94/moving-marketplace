Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Step($m){ Write-Host "`n==> $m" -ForegroundColor Cyan }
function Ok($m){ Write-Host "OK: $m" -ForegroundColor Green }
function Fail($m){ Write-Host "FAIL: $m" -ForegroundColor Red; throw $m }
function Run($cmd){
  Write-Host ("`n$ " + $cmd) -ForegroundColor DarkGray
  iex $cmd
  if ($LASTEXITCODE -ne 0) { Fail "Command failed ($LASTEXITCODE): $cmd" }
}

$ProjectDir = "C:\Users\RODERICK\Projects\moving-marketplace"
Set-Location $ProjectDir

$EnvPath = Join-Path $ProjectDir ".env"
if (-not (Test-Path $EnvPath)) { Fail "Missing .env" }

Step "Load DIRECT_URL from .env (should be 5432 session URL)"
$envLines = Get-Content $EnvPath
$directUrl = ($envLines | Select-String '^DIRECT_URL=' | Select-Object -First 1).Line.Split('=',2)[1].Trim().Trim('"')
if ([string]::IsNullOrWhiteSpace($directUrl)) { Fail "DIRECT_URL missing/empty in .env" }
Ok "DIRECT_URL loaded"

Step "Temporarily force DATABASE_URL to DIRECT_URL for migration commands"
$oldDbUrl = $env:DATABASE_URL
$oldDirect = $env:DIRECT_URL

try {
  $env:DATABASE_URL = $directUrl
  $env:DIRECT_URL   = $directUrl

  Step "Resolve failed migration record (mark 0_init as rolled back)"
  Run "pnpm exec prisma migrate resolve --rolled-back 0_init"

  Step "Deploy migrations"
  Run "pnpm exec prisma migrate deploy"

  Ok "DONE: migrate deploy succeeded"
}
finally {
  $env:DATABASE_URL = $oldDbUrl
  $env:DIRECT_URL   = $oldDirect
}

Write-Host "`nNEXT: pnpm exec prisma studio" -ForegroundColor Green
