$path = "app/page.tsx"

if (!(Test-Path $path)) {
  throw "app/page.tsx not found"
}

$content = Get-Content $path -Raw

if ($content -match "Browse Jobs") {
  Write-Host "Navigation block already exists. Skipping." -ForegroundColor Yellow
  return
}

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

# Insert block right before closing </main>
$content = $content -replace "</main>", "$navBlock`n</main>"

Set-Content -Path $path -Value $content -Encoding UTF8

Write-Host "Home navigation block injected." -ForegroundColor Green

# Gates
pnpm lint
if ($LASTEXITCODE -ne 0) { throw "Lint failed. STOP." }

pnpm build
if ($LASTEXITCODE -ne 0) { throw "Build failed. STOP." }

Write-Host "Navigation fix complete and verified." -ForegroundColor Green


