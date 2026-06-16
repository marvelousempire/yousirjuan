# Redis Persistence Strategy for You-Sir Juan

## Recommended: Hybrid RDB + AOF

- RDB snapshots for fast recovery
- AOF with `everysec` for durability (max ~1s loss)
- TTLs on voice keys

Update command in docker-compose.yml as shown.

See full details in docs/setup/21-redis-persistence.md