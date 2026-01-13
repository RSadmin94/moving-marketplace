# Vercel Environment Variables Setup

## Required Production Environment Variables

### Database Connection (Supabase)

**DATABASE_URL** (Required)
- Format: `postgresql://user:password@host:port/dbname?pgbouncer=true&connection_limit=1`
- Use Supabase **Connection Pooling** URL (port 6543)
- Example: `postgresql://postgres.xxx:password@aws-0-us-east-1.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1`

**DIRECT_URL** (Required)
- Format: `postgresql://user:password@host:port/dbname`
- Use Supabase **Direct Connection** URL (port 5432)
- Example: `postgresql://postgres.xxx:password@db.xxx.supabase.co:5432/postgres`
- Used for migrations and Prisma introspection

### Clerk Authentication

**CLERK_SECRET_KEY** (Required)
- Your Clerk secret key from the Clerk dashboard

**NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY** (Required)
- Your Clerk publishable key (public, safe to expose)

## Verification

After setting environment variables in Vercel:

1. Test database connection:
   ```bash
   curl https://moving-marketplace.vercel.app/api/health/db
   ```
   Should return: `{"status":"ok","database":"connected"}`

2. Test full health check:
   ```bash
   curl https://moving-marketplace.vercel.app/api/health
   ```

## Important Notes

- **DATABASE_URL** must use connection pooling (pgbouncer) for serverless functions
- **DIRECT_URL** is only used for migrations and schema operations
- If Supabase password was reset, update both URLs in Vercel Production environment
- Never commit these values to git - use Vercel dashboard or CLI

