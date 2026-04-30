# Project Notes

## Architecture Decisions

### Why we chose PostgreSQL over MongoDB

After evaluating both options for three weeks, we landed on PostgreSQL for the following reasons:

- **Schema stability**: our domain model is well-defined and unlikely to change shape frequently
- **Transactions**: we need ACID guarantees for order processing — MongoDB's transaction support is improving but still lags
- **Team familiarity**: 80% of the team has production Postgres experience
- **Tooling**: pgAdmin, pgBadger, and our existing monitoring stack all integrate cleanly

The main argument for Mongo was flexible document storage for user preferences. We solved this with a `jsonb` column instead.

### API versioning strategy

We use URL-based versioning (`/v1/`, `/v2/`) rather than header-based for two reasons:

1. Easier to test in a browser or with `curl` — no custom headers needed
2. Clearer in logs and dashboards — the version is visible at a glance

Tradeoff: URL versioning is considered "impure" REST, but pragmatism wins here.

---

## Known Issues

### Issue #142 — Race condition in order processing

**Status**: In progress (assigned to @diana)
**Severity**: Medium
**Reproduced**: Intermittently under high load (~2000 req/s)

When two requests arrive simultaneously for the same order, we occasionally
see a duplicate charge. The root cause is missing locking around the `status`
transition check in `OrderService.processPayment()`.

**Proposed fix**: pessimistic lock (`SELECT ... FOR UPDATE`) on the order row
before reading status.

### Issue #167 — Memory leak in WebSocket handler

**Status**: Open
**Severity**: High
**Reproduced**: Consistently after ~6 hours of uptime

The `WebSocketManager` holds references to closed connections in its
subscriber map. These are never cleaned up because the `onClose` callback
is only registered in the happy path.

TODO: audit all the places we register `onClose` — there are at least 3.

---

## Deployment Checklist

Before deploying to production:

- [ ] Run full test suite: `./gradlew test`
- [ ] Check migration scripts are backward compatible
- [ ] Verify feature flags are set correctly in config
- [ ] Confirm rollback plan is documented in the release ticket
- [ ] Notify #oncall channel at least 30 minutes before

## Team Contacts

| Name    | Role               | Slack          |
|---------|--------------------|----------------|
| Alice   | Tech Lead          | @alice         |
| Bob     | Backend Engineer   | @bob           |
| Carol   | Frontend Engineer  | @carol         |
| Diana   | Backend Engineer   | @diana         |
| Eve     | DevOps             | @eve           |

---

## Useful Commands

```bash
# Start local dependencies
docker-compose up -d postgres redis kafka

# Run the service
./gradlew bootRun --args='--spring.profiles.active=local'

# Run migrations
./gradlew flywayMigrate

# Run tests with coverage
./gradlew test jacocoTestReport

# Tail logs (local)
tail -f logs/application.log | jq .
```

## Links

- [API Docs](https://docs.example.com/api)
- [Runbook](https://wiki.internal/runbooks/user-service)
- [Grafana Dashboard](https://grafana.internal/d/user-service)
- [Error Budget](https://slo.internal/user-service)
