**SQLite. Without a doubt.**

Concrete tradeoffs for your case:

**SQLite wins because:**
- Single-user, 50k rows = SQLite never breaks sweat. Sub-ms aggregations with good indexes.
- Zero ops: `.db` file next to app. No daemon, no port, no `pg_hba.conf`, no user/password rotation.
- VPS $5: PostgreSQL eats ~100-200MB RAM idle. SQLite = 0. Matters on a 1GB VPS.
- Backup = `cp file.db` or Litestream. Restore = copy file.
- Next.js + SQLite via `better-sqlite3` (sync, fast) or Turso/libSQL if you want edge.

**Real SQLite costs:**
- Global write lock (irrelevant — only you write).
- No rich native types (no `JSONB`, no arrays). For expenses = unnecessary.
- Less polished migrations than Postgres (Drizzle/Prisma handle both OK).

**When Postgres would win (not your case):**
- Multiple concurrent writers.
- Complex full-text search / extensions (PostGIS, pgvector).
- Heavy `JSONB` queries needed.

**Recommended middle ground: SQLite + Litestream**
- Litestream replicates WAL to S3/B2/R2 continuously. RPO ~seconds.
- Backblaze B2: ~$0.005/GB/month. Your DB will weigh <100MB for years.
- Setup: 1 binary, 1 YAML config, systemd unit. Done.

**Modern alternative:** Turso (libSQL fork) — SQLite with managed replication, generous free tier. If you don't want to deal with Litestream.

**Suggested stack:** Next.js + Drizzle ORM + better-sqlite3 + Litestream → B2. Deploy: Coolify/Dokploy on Hetzner CX22 VPS ($4).