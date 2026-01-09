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
if (-not (Test-Path $EnvPath)) { Fail "Missing .env at $EnvPath" }

Step "Read Supabase URLs from .env"
$envLines = Get-Content $EnvPath

function Get-EnvValue([string]$name){
  $line = ($envLines | Select-String ("^{0}=" -f [regex]::Escape($name)) | Select-Object -First 1).Line
  if (-not $line) { return $null }
  return $line.Split("=",2)[1].Trim().Trim('"')
}

# Your .env currently has:
# DATABASE_URL = pooled (6543) sometimes, DIRECT_URL = session (5432) sometimes.
# For DEPLOY we MUST use the session URL (5432). We'll prefer DIRECT_URL for deploy.
$supabaseDirect = Get-EnvValue "DIRECT_URL"
if ([string]::IsNullOrWhiteSpace($supabaseDirect)) { Fail "DIRECT_URL missing/empty in .env" }
Ok "Loaded DIRECT_URL (Supabase session URL)"

Step "Start local Postgres+PostGIS (Docker)"
# Requirements: Docker Desktop running
$container = "mm-postgis-local"
$localPort = 54321
$localUser = "postgres"
$localPass = "postgres"
$localDb   = "prisma_dev"

# If container exists, start it; else run it
$exists = (docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq $container }) -ne $null
if (-not $exists) {
  Run "docker run -d --name $container -e POSTGRES_PASSWORD=$localPass -e POSTGRES_DB=$localDb -p ${localPort}:5432 postgis/postgis:16-3.4"
} else {
  Run "docker start $container"
}

# Wait until DB is ready
Step "Wait for local DB to accept connections"
$localUrl = "postgresql://${localUser}:${localPass}@localhost:${localPort}/${localDb}?schema=public"
$max = 60
for ($i=1; $i -le $max; $i++){
  try {
    # quick readiness check inside container
    docker exec $container pg_isready -U $localUser -d $localDb | Out-Null
    if ($LASTEXITCODE -eq 0) { break }
  } catch {}
  Start-Sleep -Seconds 1
  if ($i -eq $max) { Fail "Local Postgres did not become ready" }
}
Ok "Local Postgres ready"

Step "Ensure PostGIS enabled locally"
# Enable postgis extension in local dev DB (safe if already enabled)
Run "docker exec $container psql -U $localUser -d $localDb -c `"CREATE EXTENSION IF NOT EXISTS postgis;`""

Ok "Local PostGIS enabled"

Step "Generate migrations LOCALLY (this avoids Supabase shadow DB permissions)"
# Save current env so we restore after
$oldDbUrl = $env:DATABASE_URL
$oldDirectUrl = $env:DIRECT_URL

try {
  # Point Prisma at local DB for migration generation
  $env:DATABASE_URL = $localUrl
  $env:DIRECT_URL   = $localUrl

  Run "pnpm exec prisma format"
  Run "pnpm exec prisma generate"

  # Create/apply migrations locally (creates prisma/migrations/*)
  Run "pnpm exec prisma migrate dev --name init"
  Ok "Local migrate dev succeeded (migration files created)"
}
finally {
  $env:DATABASE_URL = $oldDbUrl
  $env:DIRECT_URL   = $oldDirectUrl
}

Step "Deploy migrations to Supabase (NO shadow DB)"
# For deploy, we must use Supabase session connection (5432) = DIRECT_URL
$env:DATABASE_URL = $supabaseDirect
$env:DIRECT_URL   = $supabaseDirect

Run "pnpm exec prisma migrate deploy"
Ok "Supabase migrate deploy succeeded"

Step "Generate client for app runtime"
Run "pnpm exec prisma generate"
Ok "Client generated"

Write-Host "`nDONE." -ForegroundColor Green
Write-Host "NEXT: pnpm exec prisma studio" -ForegroundColor Green
