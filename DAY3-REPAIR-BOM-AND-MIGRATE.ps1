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

$SchemaPath = Join-Path $ProjectDir "prisma\schema.prisma"
$MigrationsDir = Join-Path $ProjectDir "prisma\migrations"
$EnvPath = Join-Path $ProjectDir ".env"

Step "Preflight"
if (-not (Test-Path $SchemaPath)) { Fail "Missing prisma/schema.prisma" }
if (-not (Test-Path $EnvPath)) { Fail "Missing .env" }
Ok "Found schema + .env"

Step "Load DIRECT_URL"
$envLines = Get-Content $EnvPath
$directUrl = ($envLines | Select-String '^DIRECT_URL=').Line.Split('=',2)[1].Trim().Trim('"')
if ([string]::IsNullOrWhiteSpace($directUrl)) { Fail "DIRECT_URL is empty in .env" }
Ok "DIRECT_URL loaded"

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

Step "Clean schema.prisma (remove BOM/zero-width, write UTF-8 no-BOM)"
$schema = Get-Content $SchemaPath -Raw
$schema2 = Strip-BomAndZeroWidth $schema
Write-Utf8NoBom $SchemaPath $schema2
$bytes = [System.IO.File]::ReadAllBytes($SchemaPath)
Write-Host ("schema.prisma first 3 bytes: {0:X2} {1:X2} {2:X2} (should NOT be EF BB BF)" -f $bytes[0],$bytes[1],$bytes[2]) -ForegroundColor Yellow
Ok "schema.prisma cleaned"

if (Test-Path $MigrationsDir) {
  Step "Clean ALL migration.sql files (remove BOM/zero-width, write UTF-8 no-BOM)"
  $files = @(Get-ChildItem -Path $MigrationsDir -Recurse -Filter "migration.sql" -ErrorAction SilentlyContinue)

  if ($files.Count -eq 0) {
    Ok "No migration.sql files found (prisma/migrations empty)"
  } else {
    foreach ($f in $files) {
      $raw = Get-Content $f.FullName -Raw
      $clean = Strip-BomAndZeroWidth $raw
      Write-Utf8NoBom $f.FullName $clean
    }
    Ok ("Cleaned {0} migration.sql file(s)" -f $files.Count)
  }
} else {
  Ok "No prisma/migrations folder yet"
}

Step "Ensure schema app exists (DIRECT_URL)"
$sql = "create schema if not exists app;"
$env:PRISMA_DB_EXEC_URL = $directUrl
$sql | & pnpm exec prisma db execute --url $env:PRISMA_DB_EXEC_URL --stdin
if ($LASTEXITCODE -ne 0) { Fail "prisma db execute failed ($LASTEXITCODE)" }
Ok "Schema app exists"

Step "Format + Generate"
Run "pnpm exec prisma format"
Run "pnpm exec prisma generate"
Ok "Format + generate OK"

Step "Migrate"
Run "pnpm exec prisma migrate dev --name init"

Ok "DONE: migrate dev succeeded"
Write-Host "`nNEXT: pnpm exec prisma studio" -ForegroundColor Green
