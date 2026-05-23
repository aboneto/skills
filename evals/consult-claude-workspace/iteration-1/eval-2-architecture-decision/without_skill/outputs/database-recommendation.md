# Database Choice Analysis: SQLite vs PostgreSQL

## Project Context

- **Type:** Personal expense tracking dashboard
- **Scale:** 10-20 tables, ~50k rows total
- **Deployment:** Cheap VPS
- **Priority:** Easy deployment and maintenance

## Comparison

| Criteria | SQLite | PostgreSQL |
|----------|--------|------------|
| Setup complexity | Zero-config, single file | Requires separate process, user/role config |
| Memory footprint | ~0MB (embedded) | ~50-100MB baseline |
| Deployment | Copy the file | Install, configure, manage service |
| Backups | `cp database.db backup.db` | `pg_dump`, requires service coordination |
| Concurrent reads | Excellent | Excellent |
| Concurrent writes | Limited (WAL mode helps) | Excellent |
| 50k rows performance | More than sufficient | Overkill |
| VPS cost impact | None | Needs more RAM = higher tier |
| Migrations | Simple (schema in file) | Simple (standard SQL) |
| Query complexity | Full SQL support | Full SQL + advanced features |
| Future scaling | Good up to ~100GB | Unlimited |

## Analysis

### Why SQLite fits this project

1. **Scale match:** 50k rows across 20 tables is trivial for SQLite. It handles millions of rows comfortably.
2. **Single-user dashboard:** No concurrent write contention. Expense tracking is typically one user inserting data.
3. **Deployment simplicity:** No database server to install, configure, secure, or monitor. Just a file.
4. **VPS savings:** A $3.50-5/mo VPS (1GB RAM) is enough since there's no database process eating memory.
5. **Backups:** Copying a single `.db` file is the simplest backup strategy possible.
6. **WAL mode:** Enables concurrent reads while writing, which is more than enough for a personal dashboard.

### When PostgreSQL would be better

- Multi-user app with concurrent writes
- Need for full-text search with `tsvector` (SQLite FTS5 is decent though)
- Complex JSON operations (SQLite JSON1 extension covers most cases)
- Need for database-level replication or clustering
- Team of developers needing shared dev database

### Potential SQLite concerns (and mitigations)

| Concern | Mitigation |
|---------|------------|
| "SQLite isn't production-ready" | Myth. Used by every iPhone, Android, Chrome, Firefox. |
| Write concurrency | Not an issue for single-user dashboard. WAL mode handles it anyway. |
| No network access | App and DB on same VPS = no network needed. Use Litestream for replication if needed. |
| Migration tooling | Works with standard migration tools (golang-migrate, Flyway, Alembic, etc.) |

## Recommendation: SQLite

**Confidence: High**

For a personal expense dashboard with 50k rows on a cheap VPS, SQLite is the clear winner:

- **Zero ops burden** — no database server to maintain
- **Cheaper VPS** — no RAM overhead from a DB process
- **Simpler deploys** — one binary + one file
- **Trivial backups** — copy the file
- **Performance is a non-issue** — SQLite handles this workload effortlessly

### Suggested setup

```
app/
  data/
    expenses.db      # The database file
    expenses.db-wal   # WAL file (auto-managed)
    expenses.db-shm   # Shared memory file (auto-managed)
```

Enable WAL mode on first connection:
```sql
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA foreign_keys=ON;
```

### Upgrade path

If the project grows beyond SQLite's comfort zone (unlikely for personal use), migrating to PostgreSQL later is straightforward:
1. Export schema and data
2. Adjust any SQLite-specific SQL (minimal for standard queries)
3. Point app to PostgreSQL connection string

The migration cost is low, so starting with SQLite doesn't paint you into a corner.
