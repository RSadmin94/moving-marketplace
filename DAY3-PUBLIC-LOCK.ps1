Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Step($m){ Write-Host "`n==> $m" -ForegroundColor Cyan }
function Ok($m){ Write-Host "OK: $m" -ForegroundColor Green }
function Fail($m){ Write-Host "FAIL: $m" -ForegroundColor Red; throw $m }

$ProjectDir = "C:\Users\RODERICK\Projects\moving-marketplace"
Set-Location $ProjectDir

$EnvPath = Join-Path $ProjectDir ".env"
if (-not (Test-Path $EnvPath)) { Fail "Missing .env at $EnvPath" }

Step "Read current .env URLs"
$envLines = Get-Content $EnvPath
$dbLine = ($envLines | Select-String '^DATABASE_URL=' -ErrorAction SilentlyContinue).Line
$directLine = ($envLines | Select-String '^DIRECT_URL=' -ErrorAction SilentlyContinue).Line
if (-not $dbLine) { Fail "DATABASE_URL not found in .env" }
if (-not $directLine) { Fail "DIRECT_URL not found in .env" }

function Unquote([string]$s){ $s.Trim().Trim('"') }

$dbUrl = Unquote ($dbLine.Split('=',2)[1])
$directUrl = Unquote ($directLine.Split('=',2)[1])
Ok "Loaded DATABASE_URL + DIRECT_URL"

Step "Normalize .env for PUBLIC schema (pooler + direct)"
$uDirect = [Uri]$directUrl

$canonHost = $uDirect.Host
$canonUser = $uDirect.UserInfo.Split(':',2)[0]
$canonPass = $uDirect.UserInfo.Split(':',2)[1]
$canonDb   = $uDirect.AbsolutePath.TrimStart('/')

# DATABASE_URL => pooler 6543 with pgbouncer
$poolPort  = 6543
$poolQuery = "pgbouncer=true&connection_limit=1&sslmode=require"
$newDbUrl  = "postgresql://${canonUser}:${canonPass}@${canonHost}:$poolPort/${canonDb}?$poolQuery"

# DIRECT_URL => direct 5432 without pgbouncer
$directPort = 5432
$newDirectUrl = "postgresql://${canonUser}:${canonPass}@${canonHost}:$directPort/${canonDb}?sslmode=require"

@"
DATABASE_URL=""$newDbUrl""
DIRECT_URL=""$newDirectUrl""
"@ | Set-Content -Path $EnvPath -Encoding utf8

Ok "Wrote normalized .env"

Step "Show final .env"
Get-Content $EnvPath | ForEach-Object { Write-Host $_ }

Step "Prisma validate"
& pnpm exec prisma validate | Out-Host
if ($LASTEXITCODE -ne 0) { Fail "prisma validate failed" }
Ok "prisma validate OK"

Write-Host "`nNEXT:" -ForegroundColor Green
Write-Host "  pnpm exec prisma migrate deploy" -ForegroundColor Green
