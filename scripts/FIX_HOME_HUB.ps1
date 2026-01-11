# scripts/FIX_HOME_HUB.ps1
$ErrorActionPreference = "Stop"

$path = "app/page.tsx"
if (!(Test-Path -LiteralPath $path)) {
  throw "app/page.tsx not found"
}

# Create backup with timestamp
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = "$path.bak.$timestamp"
Copy-Item -LiteralPath $path -Destination $backupPath
Write-Host "Backed up app/page.tsx to $backupPath" -ForegroundColor Cyan

# New server component content
$newContent = @'
import Link from "next/link";
import { SignedIn, SignedOut, UserButton } from "@clerk/nextjs";
import { auth, clerkClient } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";

export default async function Page() {
  const { userId } = await auth();

  // Not signed in: show signed out UI
  if (!userId) {
    return (
      <main style={{ padding: 24, fontFamily: "system-ui" }}>
        <h1>Moving Marketplace</h1>
        <SignedOut>
          <p>
            <Link href="/sign-up">Create account</Link>{" | "}
            <Link href="/sign-in">Sign in</Link>
          </p>
        </SignedOut>
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
        </div>
      </main>
    );
  }

  // Signed in: check role and render signed in UI
  const client = await clerkClient();
  const user = await client.users.getUser(userId);
  const role = user.publicMetadata?.role as string | undefined;

  // No role: redirect to choose role (preserve existing behavior)
  if (!role) {
    redirect("/choose-role");
  }

  // Determine continue link based on role
  const continueLink = role === "SHIPPER" ? "/post-job" : "/mover";

  return (
    <main style={{ padding: 24, fontFamily: "system-ui" }}>
      <h1>Moving Marketplace</h1>
      <SignedIn>
        <p>You are signed in.</p>
        <UserButton afterSignOutUrl="/" />
      </SignedIn>
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
        <Link
          href={continueLink}
          style={{
            padding: "0.5rem 1rem",
            backgroundColor: "#0070f3",
            color: "white",
            textDecoration: "none",
            borderRadius: "6px",
          }}
        >
          Continue
        </Link>
      </div>
    </main>
  );
}
'@

# Write new content
Set-Content -LiteralPath $path -Value $newContent -Encoding UTF8
Write-Host "Wrote new server component to app/page.tsx" -ForegroundColor Green

# Gates
Write-Host "Running pnpm lint..." -ForegroundColor Cyan
pnpm lint
if ($LASTEXITCODE -ne 0) { 
  Write-Host "Lint failed. Restoring backup..." -ForegroundColor Red
  Copy-Item -LiteralPath $backupPath -Destination $path -Force
  throw "Lint failed. STOP. Backup restored to $path"
}

Write-Host "Running pnpm build..." -ForegroundColor Cyan
pnpm build
if ($LASTEXITCODE -ne 0) { 
  Write-Host "Build failed. Restoring backup..." -ForegroundColor Red
  Copy-Item -LiteralPath $backupPath -Destination $path -Force
  throw "Build failed. STOP. Backup restored to $path"
}

Write-Host "Home hub fix verified (lint + build passed)." -ForegroundColor Green
Write-Host "Backup saved at: $backupPath" -ForegroundColor Yellow

