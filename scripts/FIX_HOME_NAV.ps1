# scripts/FIX_HOME_NAV.ps1
$ErrorActionPreference = "Stop"

$path = "app/page.tsx"
if (!(Test-Path -LiteralPath $path)) {
  throw "app/page.tsx not found"
}

$content = Get-Content -LiteralPath $path -Raw

function HasLink($href) {
  return ($content -match [regex]::Escape("href=""$href"""))
}

# Ensure Link import exists
if ($content -notmatch 'from\s+"next/link"' -and $content -notmatch "from\s+'next/link'") {
  # Insert after the Clerk import line (best-effort)
  if ($content -match 'import\s+\{[^}]*\}\s+from\s+"@clerk/nextjs";') {
    $content = $content -replace '(import\s+\{[^}]*\}\s+from\s+"@clerk/nextjs";)',
      ('$1' + "`r`n" + 'import Link from "next/link";')
  } elseif ($content -match 'import\s+\{[^}]*\}\s+from\s+''@clerk/nextjs'';') {
    $content = $content -replace '(import\s+\{[^}]*\}\s+from\s+''@clerk/nextjs'';)',
      ('$1' + "`r`n" + 'import Link from "next/link";')
  } else {
    # Fallback: prepend at top
    $content = 'import Link from "next/link";' + "`r`n" + $content
  }
}

# Re-check against updated content
$jobsOk  = ($content -match 'href="/jobs"' )
$postOk  = ($content -match 'href="/post-job"' )
$moverOk = ($content -match 'href="/mover"' )

if ($jobsOk -and $postOk -and $moverOk) {
  Write-Host "Home nav links already present. Skipping injection." -ForegroundColor Yellow
} else {
  $navBlock = @'
      <div style={{ marginTop: "1rem", display: "flex", gap: "0.75rem", flexWrap: "wrap" }}>
        <Link
          href="/jobs"
          style={{
            padding: "0.5rem 1rem",
            backgroundColor: "#111",
            color: "white",
            textDecoration: "none",
            borderRadius: "6px",
          }}
        >
          Browse Jobs
        </Link>

        <Link
          href="/post-job"
          style={{
            padding: "0.5rem 1rem",
            border: "1px solid #111",
            color: "#111",
            textDecoration: "none",
            borderRadius: "6px",
          }}
        >
          Post a Job
        </Link>

        <Link
          href="/mover"
          style={{
            padding: "0.5rem 1rem",
            border: "1px solid #111",
            color: "#111",
            textDecoration: "none",
            borderRadius: "6px",
          }}
        >
          Mover Dashboard
        </Link>
      </div>
'@

  if ($content -notmatch '</main>') {
    throw "Could not find </main> in app/page.tsx to inject nav block"
  }

  # Inject right before closing </main>
  $content = $content -replace '</main>', ($navBlock + "`r`n</main>")

  Set-Content -LiteralPath $path -Value $content -Encoding UTF8
  Write-Host "Injected Home navigation block into app/page.tsx" -ForegroundColor Green
}

# Gates
Write-Host "Running pnpm lint..." -ForegroundColor Cyan
pnpm lint
if ($LASTEXITCODE -ne 0) { throw "Lint failed. STOP." }

Write-Host "Running pnpm build..." -ForegroundColor Cyan
pnpm build
if ($LASTEXITCODE -ne 0) { throw "Build failed. STOP." }

Write-Host "Home navigation fix verified (lint + build passed)." -ForegroundColor Green

