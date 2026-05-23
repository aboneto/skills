# Decision: SQLite for Expense Tracker

## Consultation
Consulted Claude (Opus model) as a second opinion for the SQLite vs PostgreSQL decision.

## Project Context
- Personal expense dashboard
- ~10-20 tables, <50k rows total
- Read-heavy (aggregations, filters), occasional writes
- Single user (no concurrency)
- Deploy on cheap VPS ($5-10/month)

## Claude's Response
**Clear recommendation: SQLite.**

### Main reasons
1. **Zero ops**: A single `.db` file, no daemon or network configuration
2. **RAM**: PostgreSQL consumes ~100-200MB idle; SQLite = 0 overhead
3. **Performance**: 50k rows with a single user = SQLite is more than enough
4. **Trivial backup**: `cp file.db` or Litestream for continuous replication

### Acceptable tradeoffs
- Global write lock: irrelevant for single-user
- No JSONB/arrays: unnecessary for the expense domain
- Migrations: Drizzle/Prisma handle SQLite well

### Recommended stack
- Next.js + Drizzle ORM + better-sqlite3
- Litestream → Backblaze B2 for backups (~$0.005/GB/month)
- Deploy: Coolify/Dokploy on Hetzner CX22 ($4/month)

## Final Decision
**SQLite** is the right choice for this case. Claude's arguments confirm what the project profile suggests: PostgreSQL's advantages (concurrency, extensions, rich types) aren't leveraged in a single-user personal dashboard with <50k rows, while SQLite's advantages (zero ops, minimal RAM consumption, simple backup) are exactly what matters for cheap VPS deployment.

### Next Action
Use SQLite with Drizzle ORM for schema and migrations. Configure Litestream for automated backups to S3-compatible storage (Backblaze B2 or Cloudflare R2).