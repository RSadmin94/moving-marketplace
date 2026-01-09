Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Step($m){ Write-Host "`n==> $m" -ForegroundColor Cyan }
function Ok($m){ Write-Host "OK: $m" -ForegroundColor Green }
function Warn($m){ Write-Host "WARN: $m" -ForegroundColor Yellow }
function Fail($m){ Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }

$ProjectDir = "C:\Users\RODERICK\Projects\moving-marketplace"
if (-not (Test-Path $ProjectDir)) { Fail "Project dir not found: $ProjectDir" }
Set-Location $ProjectDir

# -----------------------------
# 0) Verify we have a Next.js app + schema path
# -----------------------------
Step "Sanity checks"
if (-not (Test-Path ".\package.json")) { Fail "package.json missing. Wrong folder?" }
if (-not (Test-Path ".\prisma")) { Fail "prisma folder missing." }
if (-not (Test-Path ".\prisma\schema.prisma")) { Fail "prisma\schema.prisma missing." }
Ok "Project structure looks correct."

# -----------------------------
# 1) Ensure Prisma v6.19.1 (Prisma 7 breaks url/directUrl in schema)
# -----------------------------
Step "Ensuring Prisma v6.19.1"
$pkg = Get-Content ".\package.json" -Raw
$needs = ($pkg -notmatch '"prisma"\s*:\s*"6\.19\.1"') -or ($pkg -notmatch '"@prisma/client"\s*:\s*"6\.19\.1"')
if ($needs) {
  Warn "Pinning prisma + @prisma/client to 6.19.1"
  try { pnpm remove prisma @prisma/client | Out-Null } catch {}
  pnpm add -D prisma@6.19.1
  pnpm add @prisma/client@6.19.1
}
pnpm exec prisma -v | Out-Host
Ok "Prisma version enforced."

# -----------------------------
# 2) Write schema.prisma EXACTLY as UTF-8 (NO BOM)
#    (BOM was causing: 'invalid keyword' on line 1)
# -----------------------------
Step "Writing schema.prisma (UTF-8 NO-BOM)"
$SchemaPath = Join-Path $ProjectDir "prisma\schema.prisma"

# IMPORTANT:
# Paste your full schema below exactly between the @"" and ""@.
$SCHEMA = @"
generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["postgresqlExtensions"]
}

datasource db {
  provider   = "postgresql"
  url        = env("DATABASE_URL")
  directUrl  = env("DIRECT_URL")
  extensions = [postgis(schema: "public")]
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  clerkId   String   @unique
  role      UserRole
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  customer      Customer?
  mover         Mover?
  notifications Notification[]
}

model Customer {
  id        String   @id @default(cuid())
  userId    String   @unique
  phone     String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  user     User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  jobs     Job[]
  reviews  Review[]
  disputes Dispute[] @relation("CustomerDisputes")
}

model Mover {
  id                       String             @id @default(cuid())
  userId                   String             @unique
  businessName             String
  businessEin              String?
  baseLat                  Decimal            @db.Decimal(10, 8)
  baseLng                  Decimal            @db.Decimal(11, 8)
  serviceRadiusMiles       Int
  subscriptionTier         SubscriptionTier   @default(FREE)
  subscriptionStatus       SubscriptionStatus @default(INCOMPLETE)
  platformStatus           PlatformStatus     @default(ACTIVE)
  suspensionReason         String?
  stripeCustomerId         String?            @unique
  stripeSubscriptionId     String?
  stripeCurrentPeriodStart DateTime?
  stripeCurrentPeriodEnd   DateTime?
  bidCreditsRemaining      Int                @default(0)
  verificationStage        VerificationStage  @default(PENDING)
  insuranceExpiryDate      DateTime?
  reputationScore          Decimal            @db.Decimal(3, 2) @default(0.00)
  totalJobsCompleted       Int                @default(0)
  noShowCount              Int                @default(0)
  disputeCount             Int                @default(0)
  createdAt                DateTime           @default(now())
  updatedAt                DateTime           @updatedAt

  user                  User                   @relation(fields: [userId], references: [id], onDelete: Cascade)
  bids                  Bid[]
  reviews               Review[]
  verificationDocuments VerificationDocument[]
  disputes              Dispute[]              @relation("MoverDisputes")
  awardedJobs           Job[]                  @relation("AwardedMover")

  @@index([baseLat, baseLng])
}

model Job {
  id                     String    @id @default(cuid())
  customerId             String
  originAddressFull      String
  originCity             String
  originState            String
  originZip              String
  originLat              Decimal   @db.Decimal(10, 8)
  originLng              Decimal   @db.Decimal(11, 8)
  destinationAddressFull String
  destinationCity        String
  destinationState       String
  destinationZip         String
  destinationLat         Decimal?  @db.Decimal(10, 8)
  destinationLng         Decimal?  @db.Decimal(11, 8)
  status                 JobStatus @default(DRAFT)
  moveDate               DateTime?
  isFlexibleDate         Boolean   @default(false)
  needsPacking           Boolean   @default(false)
  needsStorage           Boolean   @default(false)
  stairsAtOrigin         Boolean   @default(false)
  stairsAtDestination    Boolean   @default(false)
  elevatorAtOrigin       Boolean   @default(false)
  elevatorAtDestination  Boolean   @default(false)
  specialItems           String?
  totalVolumeCuft        Decimal?  @db.Decimal(8, 2)
  truckSizeRecommended   String?
  awardedBidId           String?   @unique
  awardedMoverId         String?
  awardedAt              DateTime?
  expiresAt              DateTime?
  createdAt              DateTime  @default(now())
  updatedAt              DateTime  @updatedAt

  customer       Customer        @relation(fields: [customerId], references: [id], onDelete: Restrict)
  awardedBid     Bid?            @relation("AwardedBid", fields: [awardedBidId], references: [id], onDelete: SetNull)
  awardedMover   Mover?          @relation("AwardedMover", fields: [awardedMoverId], references: [id], onDelete: SetNull)
  photos         Photo[]
  scopeVersions  ScopeVersion[]
  bids           Bid[]           @relation("JobBids")
  reviews        Review[]
  disputes       Dispute[]
  notifications  Notification[]

  @@index([originLat, originLng])
  @@index([status])
  @@index([customerId])
  @@index([status, originLat, originLng])
}

model Photo {
  id            String       @id @default(cuid())
  jobId         String
  room          Room
  url           String
  thumbnailUrl  String?
  uploadStatus  UploadStatus @default(PENDING)
  contentType   String
  fileSizeBytes Int
  source        PhotoSource  @default(UPLOAD)
  capturedAt    DateTime?
  createdAt     DateTime     @default(now())
  updatedAt     DateTime     @updatedAt

  job Job @relation(fields: [jobId], references: [id], onDelete: Cascade)

  @@index([jobId])
}

model ScopeVersion {
  id              String    @id @default(cuid())
  jobId           String
  versionNumber   Int
  lockedAt        DateTime?
  isCurrent       Boolean   @default(true)
  totalVolumeCuft Decimal?  @db.Decimal(8, 2)
  itemsJson       Json?
  createdAt       DateTime  @default(now())
  updatedAt       DateTime  @updatedAt

  job            Job             @relation(fields: [jobId], references: [id], onDelete: Cascade)
  inventoryItems InventoryItem[]
  bids           Bid[]

  @@unique([jobId, versionNumber])
  @@index([jobId])
  @@index([jobId, isCurrent])
}

model InventoryItem {
  id                  String   @id @default(cuid())
  jobId               String
  scopeVersionId      String
  room                Room
  itemType            String
  itemName            String
  quantity            Int      @default(1)
  volumeCuft          Decimal  @db.Decimal(6, 2)
  isFragile           Boolean  @default(false)
  requiresDisassembly Boolean  @default(false)
  aiDetected          Boolean  @default(false)
  aiConfidence        Decimal? @db.Decimal(3, 2)
  notes               String?
  createdAt           DateTime @default(now())
  updatedAt           DateTime @updatedAt

  job          Job          @relation(fields: [jobId], references: [id], onDelete: Cascade)
  scopeVersion ScopeVersion @relation(fields: [scopeVersionId], references: [id], onDelete: Cascade)

  @@index([jobId])
  @@index([scopeVersionId])
}

model Bid {
  id                 String    @id @default(cuid())
  jobId              String
  moverId            String
  scopeVersionId     String
  priceTotal         Decimal   @db.Decimal(10, 2)
  priceBreakdownJson Json?
  truckSizeOffered   String?
  moversCount        Int?
  hoursEstimated     Decimal?  @db.Decimal(5, 2)
  validUntil         DateTime?
  expiresAt          DateTime
  status             BidStatus @default(PENDING)
  createdAt          DateTime  @default(now())
  updatedAt          DateTime  @updatedAt

  job          Job          @relation("JobBids", fields: [jobId], references: [id], onDelete: Cascade)
  mover        Mover        @relation(fields: [moverId], references: [id], onDelete: Cascade)
  scopeVersion ScopeVersion @relation(fields: [scopeVersionId], references: [id], onDelete: Restrict)
  awardedJob   Job?         @relation("AwardedBid")
  reviews      Review[]
  disputes     Dispute[]

  @@unique([jobId, moverId])
  @@index([jobId])
  @@index([moverId])
  @@index([status])
  @@index([jobId, status])
  @@index([moverId, status])
}

model Review {
  id           String   @id @default(cuid())
  jobId        String
  bidId        String
  moverId      String
  customerId   String
  rating       Int
  onTime       Boolean  @default(true)
  professional Boolean  @default(true)
  careful      Boolean  @default(true)
  comment      String?
  response     String?
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt

  job      Job      @relation(fields: [jobId], references: [id], onDelete: Cascade)
  bid      Bid      @relation(fields: [bidId], references: [id], onDelete: Cascade)
  mover    Mover    @relation(fields: [moverId], references: [id], onDelete: Cascade)
  customer Customer @relation(fields: [customerId], references: [id], onDelete: Cascade)

  @@unique([jobId, customerId])
  @@index([moverId])
}

model Dispute {
  id                   String        @id @default(cuid())
  jobId                String
  bidId                String?
  reportedBy           ReportedBy
  reportedByCustomerId String?
  reportedByMoverId    String?
  disputeType          DisputeType
  description          String
  status               DisputeStatus @default(OPEN)
  resolutionNotes      String?
  resolvedBy           String?
  resolvedAt           DateTime?
  createdAt            DateTime      @default(now())
  updatedAt            DateTime      @updatedAt

  job                Job       @relation(fields: [jobId], references: [id], onDelete: Cascade)
  bid                Bid?      @relation(fields: [bidId], references: [id], onDelete: SetNull)
  reportedByCustomer Customer? @relation("CustomerDisputes", fields: [reportedByCustomerId], references: [id], onDelete: Cascade)
  reportedByMover    Mover?    @relation("MoverDisputes", fields: [reportedByMoverId], references: [id], onDelete: Cascade)

  @@index([jobId])
  @@index([status])
}

model VerificationDocument {
  id           String         @id @default(cuid())
  moverId      String
  documentType DocumentType
  fileUrl      String
  status       DocumentStatus @default(PENDING)
  expiresAt    DateTime?
  reviewedAt   DateTime?
  reviewedBy   String?
  createdAt    DateTime       @default(now())
  updatedAt    DateTime       @updatedAt

  mover Mover @relation(fields: [moverId], references: [id], onDelete: Cascade)

  @@index([moverId])
}

model StripeEvent {
  id            String   @id @default(cuid())
  stripeEventId String   @unique
  eventType     String
  payloadJson   Json
  processedAt   DateTime @default(now())
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt

  @@index([stripeEventId])
}

model Notification {
  id        String    @id @default(cuid())
  userId    String
  jobId     String?
  type      String
  title     String
  message   String
  isRead    Boolean   @default(false)
  readAt    DateTime?
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt

  user User  @relation(fields: [userId], references: [id], onDelete: Cascade)
  job  Job?  @relation(fields: [jobId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@index([isRead])
}

enum UserRole {
  CUSTOMER
  MOVER
  ADMIN
}

enum SubscriptionTier {
  FREE
  STARTER
  PRO
  ELITE
}

enum SubscriptionStatus {
  ACTIVE
  PAST_DUE
  CANCELED
  INCOMPLETE
  TRIALING
}

enum PlatformStatus {
  ACTIVE
  WARNING
  SUSPENDED
  BANNED
}

enum VerificationStage {
  PENDING
  DOCUMENTS_SUBMITTED
  VERIFIED
  REJECTED
}

enum JobStatus {
  DRAFT
  PENDING_SCOPE
  ACTIVE
  AWARDED
  COMPLETED
  CANCELED
  EXPIRED
}

enum Room {
  LIVING_ROOM
  KITCHEN
  BEDROOM_1
  BEDROOM_2
  BEDROOM_3
  DINING_ROOM
  GARAGE
  BASEMENT
  ATTIC
  OTHER
}

enum UploadStatus {
  PENDING
  UPLOADED
  FAILED
}

enum PhotoSource {
  CAMERA
  UPLOAD
}

enum BidStatus {
  PENDING
  ACCEPTED
  REJECTED
  WITHDRAWN
  EXPIRED
}

enum DisputeType {
  PRICE_DISAGREEMENT
  DAMAGE_CLAIM
  NO_SHOW
  LATE_ARRIVAL
  INCOMPLETE_SERVICE
  UNPROFESSIONAL_CONDUCT
  OTHER
}

enum DisputeStatus {
  OPEN
  INVESTIGATING
  RESOLVED
  CLOSED
}

enum DocumentType {
  BUSINESS_LICENSE
  INSURANCE_COI
  EQUIPMENT_PHOTOS
  BACKGROUND_CHECK
}

enum DocumentStatus {
  PENDING
  APPROVED
  REJECTED
}

enum ReportedBy {
  CUSTOMER
  MOVER
}
"@

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($SchemaPath, $SCHEMA, $utf8NoBom)

# Confirm no BOM
$bytes = [System.IO.File]::ReadAllBytes($SchemaPath)
$first3 = "{0:X2} {1:X2} {2:X2}" -f $bytes[0],$bytes[1],$bytes[2]
Write-Host "schema.prisma first 3 bytes: $first3" -ForegroundColor DarkCyan
if ($first3 -eq "EF BB BF") { Fail "BOM still present in schema.prisma" }
Ok "schema.prisma written clean (no BOM)."

# Count models
$modelCount = ([regex]::Matches($SCHEMA, "(?m)^\s*model\s+")).Count
Ok "Schema model count: $modelCount"

# -----------------------------
# 3) Ensure .env has DATABASE_URL + DIRECT_URL (Prisma loads .env)
# -----------------------------
Step "Ensuring .env has DATABASE_URL + DIRECT_URL"
if (-not (Test-Path ".\.env")) { New-Item ".\.env" -ItemType File | Out-Null }

$envRaw = Get-Content ".\.env" -Raw
$hasDb = $envRaw -match '(?m)^DATABASE_URL='
$hasDirect = $envRaw -match '(?m)^DIRECT_URL='

if (-not $hasDb -or -not $hasDirect) {
  Warn ".env missing one or both variables - you'll be prompted once."
  $DATABASE_URL = Read-Host "DATABASE_URL (pooler 6543, must include pgbouncer=true)"
  $DIRECT_URL   = Read-Host "DIRECT_URL (direct 5432)"
  if ($DATABASE_URL -notmatch "pgbouncer=true") { Fail "DATABASE_URL must include pgbouncer=true" }
  $envOut = @"
DATABASE_URL="$DATABASE_URL"
DIRECT_URL="$DIRECT_URL"
"@
  [System.IO.File]::WriteAllText((Join-Path $ProjectDir ".env"), $envOut, $utf8NoBom)
  Ok ".env written."
} else {
  Ok ".env already contains both vars."
}

# -----------------------------
# 4) Generate client
# -----------------------------
Step "Prisma generate"
pnpm exec prisma generate
Ok "Generated Prisma Client."

# -----------------------------
# 5) Migrate (handle Supabase directUrl IPv6/no-A-record issue)
# -----------------------------
Step "Attempting migration via DIRECT_URL"
try {
  pnpm exec prisma migrate dev --name init
  Ok "Migration succeeded via DIRECT_URL."
} catch {
  Warn "Migration failed (likely DIRECT_URL unreachable on your network due to IPv6-only A-record issue)."
  Warn "Safe dev workaround: temporarily set DIRECT_URL = DATABASE_URL just to run migrations."

  $envPath = Join-Path $ProjectDir ".env"
  $envText = Get-Content $envPath -Raw

  # Extract DATABASE_URL value (simple parse)
  $dbLine = ($envText -split "`n" | Where-Object { $_ -match '^DATABASE_URL=' } | Select-Object -First 1)
  if (-not $dbLine) { Fail "Could not find DATABASE_URL in .env" }

  $dbVal = $dbLine -replace '^DATABASE_URL=', ''
  $dbVal = $dbVal.Trim()

  Step "Temporarily setting DIRECT_URL = DATABASE_URL in .env (dev workaround)"
  $envText2 = $envText -replace '(?m)^DIRECT_URL=.*$', "DIRECT_URL=$dbVal"
  [System.IO.File]::WriteAllText($envPath, $envText2, $utf8NoBom)

  Step "Retrying migration"
  pnpm exec prisma migrate dev --name init
  Ok "Migration succeeded using pooler workaround."

  Warn "IMPORTANT: For production/CI, you still want a real DIRECT_URL reachable from that environment."
}

# -----------------------------
# 6) Output deliverables checklist
# -----------------------------
Step "DAY 3 Deliverables you will paste back"
Write-Host "1) Migration output: done above (scroll and copy)." -ForegroundColor Yellow
Write-Host "2) PostGIS version: run this in Supabase SQL Editor:" -ForegroundColor Yellow
Write-Host "   select postgis_version();" -ForegroundColor Cyan
Write-Host "3) Local health check (if you have /api/health): http://localhost:3000/api/health" -ForegroundColor Yellow
Write-Host "4) Next: GitHub push + Vercel deploy + Clerk webhook endpoint." -ForegroundColor Yellow

Ok "Day 3 infra steps completed."
