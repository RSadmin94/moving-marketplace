Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectDir = "C:\Users\RODERICK\Projects\moving-marketplace"
$SchemaPath = Join-Path $ProjectDir "prisma\schema.prisma"

if (-not (Test-Path $SchemaPath)) {
  throw "schema.prisma not found at: $SchemaPath"
}

# Read schema as raw text
$schema = Get-Content $SchemaPath -Raw

# Quick sanity: ensure Job model exists
if ($schema -notmatch '(?ms)model\s+Job\s*\{.*?\n\}') {
  throw "Could not find 'model Job { ... }' block in schema.prisma"
}

# If already fixed, just re-save NO-BOM and exit clean
if ($schema -match '(?m)^\s*inventoryItems\s+InventoryItem\[\]\s*$') {
  Write-Host "OK: Job.inventoryItems already present. Rewriting schema as UTF-8 NO-BOM anyway..." -ForegroundColor Green
} else {
  # Insert "inventoryItems InventoryItem[]" into model Job { } block
  # Best spot: right after "scopeVersions  ScopeVersion[]", otherwise after "photos Photo[]", otherwise near first relation array field.
  $jobBlock = [regex]::Match($schema, '(?ms)model\s+Job\s*\{.*?\n\}')
  $jobText  = $jobBlock.Value

  $insertLine = "  inventoryItems InventoryItem[]"

  if ($jobText -match '(?m)^\s*scopeVersions\s+ScopeVersion\[\]\s*$') {
    $jobText2 = [regex]::Replace(
      $jobText,
      '(?m)^(\s*scopeVersions\s+ScopeVersion\[\]\s*)$',
      "`$1`r`n$insertLine",
      1
    )
  }
  elseif ($jobText -match '(?m)^\s*photos\s+Photo\[\]\s*$') {
    $jobText2 = [regex]::Replace(
      $jobText,
      '(?m)^(\s*photos\s+Photo\[\]\s*)$',
      "`$1`r`n$insertLine",
      1
    )
  }
  else {
    # Fallback: insert right before closing brace of Job
    $jobText2 = [regex]::Replace(
      $jobText,
      '(?ms)\n\}\s*$',
      "`r`n$insertLine`r`n}",
      1
    )
  }

  # Replace the Job block in the full schema
  $schema = $schema.Substring(0, $jobBlock.Index) + $jobText2 + $schema.Substring($jobBlock.Index + $jobBlock.Length)

  Write-Host "OK: Inserted 'inventoryItems InventoryItem[]' into model Job." -ForegroundColor Green
}

# Write schema as UTF-8 NO-BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($SchemaPath, $schema, $utf8NoBom)

# Prove first bytes are NOT BOM
$bytes = [System.IO.File]::ReadAllBytes($SchemaPath)
$first3 = "{0:X2} {1:X2} {2:X2}" -f $bytes[0], $bytes[1], $bytes[2]
Write-Host "schema.prisma first 3 bytes: $first3 (should NOT be EF BB BF)" -ForegroundColor Cyan

Write-Host "`nNEXT (run these):" -ForegroundColor Yellow
Write-Host "cd `"$ProjectDir`"" -ForegroundColor Yellow
Write-Host "pnpm exec prisma format" -ForegroundColor Yellow
Write-Host "pnpm exec prisma generate" -ForegroundColor Yellow
Write-Host "pnpm exec prisma migrate dev --name init" -ForegroundColor Yellow