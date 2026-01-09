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

function Write-Utf8NoBom([string]$path, [string]$content){
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

function Strip-BomAndZeroWidth([string]$s){
  if ($null -eq $s) { return $s }
  $s = $s -replace [char]0xFEFF, ''   # BOM / ZWNBSP
  $s = $s -replace [char]0x200B, ''   # zero width space
  $s = $s -replace [char]0x200C, ''   # zero width non-joiner
  $s = $s -replace [char]0x200D, ''   # zero width joiner
  return $s
}

$ProjectDir = "C:\Users\RODERICK\Projects\moving-marketplace"
Set-Location $ProjectDir

$SchemaPath = Join-Path $ProjectDir "prisma\schema.prisma"
$EnvPath    = Join-Path $ProjectDir ".env"
$MigrationsDir = Join-Path $ProjectDir "prisma\migrations"
$LockPath   = Join-Path $MigrationsDir "migration_lock.toml"

Step "Preflight"
if (-not (Test-Path $SchemaPath)) { Fail "Missing prisma/schema.prisma" }
if (-not (Test-Path $EnvPath)) { Fail "Missing .env" }
Ok "Found schema + .env"

Step "Load DIRECT_URL from .env (must be the 5432 session URL)"
$envLines = Get-Content $EnvPath
$directUrl = ($envLines | Select-String '^DIRECT_URL=' | Select-Object -First 1).Line.Split('=',2)[1].Trim().Trim('"')
if ([string]::IsNullOrWhiteSpace($directUrl)) { Fail "DIRECT_URL missing/empty in .env" }
Ok "DIRECT_URL loaded"

Step "Clean schema.prisma (remove BOM/zero-width, force UTF-8 no-BOM)"
$schemaRaw = Get-Content $SchemaPath -Raw
$schemaClean = Strip-BomAndZeroWidth $schemaRaw

# IMPORTANT: Keep SINGLE schema mode. Remove any datasource 'schemas = [...]' line if present.
$schemaClean = $schemaClean -replace '(?m)^\s*schemas\s*=\s*\[[^\]]*\]\s*$', ''

# Also remove any @@schema("...") attributes if they were added during multi-schema attempts.
$schemaClean = $schemaClean -replace '(?m)^\s*@@schema\(".*?"\)\s*$', ''

Write-Utf8NoBom $SchemaPath $schemaClean
$bytes = [System.IO.File]::ReadAllBytes($SchemaPath)
Write-Host ("schema.prisma first 3 bytes: {0:X2} {1:X2} {2:X2} (should NOT be EF BB BF)" -f $bytes[0],$bytes[1],$bytes[2]) -ForegroundColor Yellow
Ok "schema.prisma cleaned + forced to single-schema mode"

Step "Ensure migrations folder + lock file exist"
if (-not (Test-Path $MigrationsDir)) { New-Item -ItemType Directory -Path $MigrationsDir | Out-Null }
if (-not (Test-Path $LockPath)) {
  Write-Utf8NoBom $LockPath "provider = `"postgresql`"`n"
  Ok "Created migration_lock.toml"
} else {
  Ok "migration_lock.toml already exists"
}

Step "Create offline migration SQL from EMPTY -> current schema (no DB, no Docker)"
# Create a deterministic folder name
$initDir = Join-Path $MigrationsDir "0_init"
if (-not (Test-Path $initDir)) { New-Item -ItemType Directory -Path $initDir | Out-Null }
$migrationSqlPath = Join-Path $initDir "migration.sql"

# prisma migrate diff prints SQL to stdout with --script
# We capture it and write UTF-8 no-BOM.
$sql = & pnpm exec prisma migrate diff --from-empty --to-schema-datamodel $SchemaPath --script
if ($LASTEXITCODE -ne 0) { Fail "prisma migrate diff failed ($LASTEXITCODE)" }
$sql = Strip-BomAndZeroWidth ($sql -join "`n")

# Safety: ensure it actually produced CREATE TABLE statements
if ($sql -notmatch '(?i)create\s+table') { Fail "Generated SQL does not contain CREATE TABLE. Something is wrong." }

Write-Utf8NoBom $migrationSqlPath $sql
Ok "Wrote prisma/migrations/0_init/migration.sql (UTF-8 no-BOM)"

Step "Format + Generate (should now pass, no @@schema requirement)"
Run "pnpm exec prisma format"
Run "pnpm exec prisma generate"
Ok "format + generate OK"

Step "Deploy migrations to Supabase using DIRECT_URL (NO shadow DB)"
# We DO NOT run migrate dev here.
# We temporarily point DATABASE_URL at DIRECT_URL to avoid pgbouncer args during migrations.
$oldDbUrl = $env:DATABASE_URL
$oldDirect = $env:DIRECT_URL

try {
  $env:DATABASE_URL = $directUrl
  $env:DIRECT_URL   = $directUrl
  Run "pnpm exec prisma migrate deploy"
  Ok "migrate deploy OK"
}
finally {
  $env:DATABASE_URL = $oldDbUrl
  $env:DIRECT_URL   = $oldDirect
}

Write-Host "`nDONE." -ForegroundColor Green
Write-Host "NEXT: pnpm exec prisma studio" -ForegroundColor Green
