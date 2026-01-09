# Fix-PrismaSchema-Force.ps1 
Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop" 
 
$ProjectDir = "C:\Users\RODERICK\Projects\moving-marketplace" 
$SchemaPath = Join-Path $ProjectDir "prisma\schema.prisma" 
 
if (-not (Test-Path $SchemaPath)) { throw "schema.prisma not found: $SchemaPath" } 
 
$schema = Get-Content $SchemaPath -Raw 
 
# Extract Job block 
$jobMatch = [regex]::Match($schema, '(?ms)model\s+Job\s*\{.*?\n\}') 
if (-not $jobMatch.Success) { throw "Could not find model Job { } block." } 
 
$jobText = $jobMatch.Value 
 
# Ensure the back-relation exists 
$needed = "  inventoryItems InventoryItem[]" 
if ($jobText -notmatch '(?m)^\s*inventoryItems\s+InventoryItem\[\]\s*$') { 
  # Insert after scopeVersions if present, otherwise after photos, otherwise before closing brace 
  if ($jobText -match '(?m)^\s*scopeVersions\s+ScopeVersion\[\]\s*$') { 
    $jobText = [regex]::Replace($jobText, '(?m)^(\s*scopeVersions\s+ScopeVersion\[\]\s*)$', "`$1`r`n$needed", 1) 
  } elseif ($jobText -match '(?m)^\s*photos\s+Photo\[\]\s*$') { 
    $jobText = [regex]::Replace($jobText, '(?m)^(\s*photos\s+Photo\[\]\s*)$', "`$1`r`n$needed", 1) 
  } else { 
    $jobText = [regex]::Replace($jobText, '(?ms)\n\}\s*$', "`r`n$needed`r`n}", 1) 
  } 
 
  # Replace in full schema 
  $schema = $schema.Substring(0, $jobMatch.Index) + $jobText + $schema.Substring($jobMatch.Index + $jobMatch.Length) 
  Write-Host "OK: Inserted Job.inventoryItems back-relation." -ForegroundColor Green 
} else { 
  Write-Host "OK: Job.inventoryItems back-relation already present." -ForegroundColor Green 
} 
 
# Write schema UTF-8 NO-BOM 
$utf8NoBom = New-Object System.Text.UTF8Encoding($false) 
[System.IO.File]::WriteAllText($SchemaPath, $schema, $utf8NoBom) 
 
# Show BOM proof + show Job block (this is the truth Prisma will read) 
$bytes = [System.IO.File]::ReadAllBytes($SchemaPath) 
$first3 = "{0:X2} {1:X2} {2:X2}" -f $bytes[0], $bytes[1], $bytes[2] 
Write-Host "schema.prisma first 3 bytes: $first3 (should NOT be EF BB BF)" -ForegroundColor Cyan 
 
Write-Host "`n=== CURRENT model Job { } BLOCK ===" -ForegroundColor Yellow 
$jobNow = [regex]::Match((Get-Content $SchemaPath -Raw), '(?ms)model\s+Job\s*\{.*?\n\}').Value 
Write-Host $jobNow 
 
Set-Location $ProjectDir 
 
Write-Host "`n==> prisma format" -ForegroundColor Cyan 
pnpm exec prisma format 
 
Write-Host "`n==> prisma generate" -ForegroundColor Cyan 
pnpm exec prisma generate 
 
Write-Host "`n==> prisma migrate dev --name init" -ForegroundColor Cyan 
pnpm exec prisma migrate dev --name init 