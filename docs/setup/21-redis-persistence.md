# Redis Persistence for You-Sir Juan Voice System

## Hybrid Strategy (Recommended)

**docker-compose.yml** uses:

```yaml
command: >
  redis-server --save 60 1000 --save 300 100 --save 900 1 \
  --appendonly yes \
  --appendfsync everysec \
  --auto-aof-rewrite-percentage 100 \
  --auto-aof-rewrite-min-size 64mb
```

## Why This Config

- RDB: Fast snapshots every 60s (if many changes), 5min, 15min
- AOF: Every second fsync → excellent durability
- Auto-rewrite keeps AOF compact

## Next
- Add TTLs in Nephew code (e.g. 30-60min for sessions)
- Monitor with `INFO persistence`

Continue with Caddy after Redis is stable.