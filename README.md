# MySQL → PostgreSQL CDC Pipeline

Real-time Change Data Capture pipeline replicating MySQL to PostgreSQL via Debezium and Kafka Connect. The full stack — MySQL, Kafka, Zookeeper, Kafka Connect, PostgreSQL, and a monitoring UI — runs locally with a single command.

Demonstrates the CDC pattern used in production for zero-downtime migrations, event-driven data synchronisation, and real-time data lake ingestion.

---

## What it does

| Capability | How |
|-----------|-----|
| **Initial snapshot** | Debezium reads all existing MySQL rows on first start |
| **Continuous replication** | Every INSERT, UPDATE, DELETE streams as a Kafka event |
| **Schema evolution** | `ALTER TABLE` in MySQL → column appears in PostgreSQL automatically |
| **Upsert semantics** | Duplicate events are idempotent — no double-writes |
| **Topic normalisation** | `schema.table` naming converted to PostgreSQL-safe identifiers |

---

## Architecture

```
MySQL (source)
  │
  │  binlog (ROW format)
  ▼
Debezium MySQL Source Connector
  │
  │  Kafka topic: mysql.customers_data.customers
  ▼
Apache Kafka  ◄──  Kafka-UI (localhost:8080)
  │
  ▼
Confluent JDBC Sink Connector
  │
  ▼
PostgreSQL (target)
  table: public.mysql_customers_data_customers
```

**Services:**

| Service | Image | Port |
|---------|-------|------|
| MySQL | mysql:8.0 | 3306 |
| PostgreSQL | postgres:15 | 5432 |
| Kafka | confluentinc/cp-kafka:7.6.1 | 9094 |
| Zookeeper | confluentinc/cp-zookeeper:7.6.1 | 2181 |
| Kafka Connect | custom (see `connect/Dockerfile`) | 8083 |
| Kafka-UI | provectuslabs/kafka-ui | 8080 |

---

## Prerequisites

- Docker Desktop (or Docker Engine + Compose plugin)
- `jq` installed (`brew install jq` on Mac, `apt install jq` on Linux)
- ~4GB free RAM (Kafka + Connect are memory-heavy)

---

## Quick start

```bash
# 1. Start the stack and wait for Kafka Connect to be ready
make up

# 2. Register both connectors
make register

# 3. Verify both show state: RUNNING
make status
```

That's it. The initial snapshot runs automatically — MySQL seed data is already in PostgreSQL.

---

## Verify end-to-end

**Check the initial snapshot:**
```bash
make psql
# Inside psql:
SELECT COUNT(*) FROM public.mysql_customers_data_customers;
-- Should return 5 (seed rows from mysql/init/01-schema.sql)
\q
```

**Insert rows in MySQL → watch them appear in Postgres:**
```bash
make demo-insert
```

**Update a row → verify it propagates:**
```bash
make demo-update
```

**Add a column → verify schema evolution:**
```bash
make demo-schema
```

---

## All make commands

```
make up           Start the full stack (waits for Connect to be ready)
make down         Stop all containers
make build        Rebuild the Connect image
make reset        Full teardown including Docker volumes (clean slate)

make register     Register both connectors
make status       Show connector state (both should be RUNNING)

make logs         Follow Kafka Connect logs
make psql         Open PostgreSQL shell
make mysql        Open MySQL shell

make demo-insert  Insert 3 rows and verify replication
make demo-update  Update a row and verify propagation
make demo-schema  Add a column and verify schema evolution

make help         Show all commands
```

---

## Common issues

**`make register` fails with connection refused**

Connect isn't ready yet. `make up` waits automatically, but if you ran `register` manually, wait 60–90 seconds after `docker compose up` then try again.

**Connector shows `state: FAILED`**

Check the logs:
```bash
make logs
# or
docker compose logs connect | grep ERROR
```
Most common cause: MySQL wasn't ready when Debezium tried to connect. Run `make down && make up` to restart cleanly.

**Port 3306 or 5432 already in use**

Stop any local MySQL or Postgres instances, or change the host ports in `docker-compose.yml`.

---

## Connector configuration

**`connectors/mysql-source.json`** — Debezium MySQL Source

Key settings:
- `snapshot.mode: initial` — snapshots existing data on first run, then switches to streaming
- `transforms.unwrap` — extracts the `after` field from Debezium's envelope so the sink receives flat records
- `delete.handling.mode: rewrite` — appends `__deleted: true` to deleted records instead of emitting tombstones

**`connectors/jdbc-sink.json`** — Confluent JDBC Sink

Key settings:
- `insert.mode: upsert` — uses `INSERT ... ON CONFLICT` so replayed events don't create duplicates
- `auto.evolve: true` — adds new columns to PostgreSQL when MySQL schema changes
- `pk.fields: customerKey` — required for upsert to work correctly

---

## Version compatibility

| Component | Version | Notes |
|-----------|---------|-------|
| Confluent Platform | 7.6.1 | Kafka 3.6 |
| Debezium MySQL Connector | 2.6.1.Final | Tested against cp-kafka-connect:7.6.1 |
| kafka-connect-jdbc | 10.7.4 | Last version with stable upsert behaviour |
| MySQL | 8.0 | binlog_format=ROW required |
| PostgreSQL | 15 | JDBC sink compatible |

---

## Author

**Abhista Atchutuni** — AI & Data Engineer  
[linkedin.com/in/abhistac](https://linkedin.com/in/abhistac) · [abhistaca@gmail.com](mailto:abhistaca@gmail.com) · [abhistac.github.io](https://abhistac.github.io)
