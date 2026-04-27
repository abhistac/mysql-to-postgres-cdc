# MySQL → PostgreSQL CDC Pipeline

Real-time Change Data Capture pipeline that replicates a MySQL database into PostgreSQL using Debezium and Kafka Connect. The entire stack — MySQL, Kafka, Zookeeper, Kafka Connect, PostgreSQL, and a monitoring UI — runs in Docker Compose with a single command.

Built to demonstrate the kind of real-time data replication pattern used in production data engineering: zero-downtime migrations, event-driven architecture, and schema evolution without manual intervention.

---

## What it does

- **Initial snapshot**: on startup, captures the full state of the source MySQL database
- **Continuous CDC**: streams every INSERT, UPDATE, and DELETE as a Kafka event in real time
- **Schema evolution**: when you add a column to MySQL, PostgreSQL updates automatically (`auto.evolve=true`)
- **Soft and hard deletes**: configurable — tombstone records or physically delete from the sink
- **Topic normalization**: handles the `schema.table` naming format that breaks PostgreSQL identifiers

---

## Architecture

```
┌─────────────┐    binlog     ┌──────────────────┐    Kafka    ┌─────────────────┐
│    MySQL    │ ────────────▶ │ Debezium Source  │ ──────────▶ │  Kafka Connect  │
│  (source)   │               │   Connector      │             │  JDBC Sink      │
└─────────────┘               └──────────────────┘             └────────┬────────┘
                                                                         │
                                                                         ▼
                                                                ┌─────────────────┐
                                                                │   PostgreSQL    │
                                                                │   (target)      │
                                                                └─────────────────┘

Supporting services: Zookeeper · Kafka · Kafka-UI (localhost:8080)
```

---

## Quick start

```bash
# Start the full stack
docker compose up -d --build

# Register source and sink connectors
bash scripts/register-mysql-source.sh
bash scripts/register-jdbc-sink.sh

# Verify both connectors are running
curl -s http://localhost:8083/connectors/mysql-source/status | jq .
curl -s http://localhost:8083/connectors/jdbc-sink-postgres/status | jq .
```

---

## Demo scenarios

**1. Verify the initial snapshot replicated**
```bash
docker exec -it postgres psql -U postgres -d mydb \
  -c "SELECT COUNT(*) FROM public.mysql_customers_data_customers;"
```

**2. Insert rows in MySQL → watch them appear in Postgres**
```bash
docker exec -i mysql mysql -uroot -prootpwd -h 127.0.0.1 -P 3306 \
  customers_data < mysql/sql/add_demo_rows.sql

# Check Postgres — count should increase
docker exec -it postgres psql -U postgres -d mydb \
  -c "SELECT COUNT(*) FROM public.mysql_customers_data_customers;"
```

**3. Update a row → verify it propagates**
```bash
docker exec -it mysql mysql -uroot -prootpwd -h 127.0.0.1 -P 3306 \
  -e "UPDATE customers_data.customers SET email='updated@example.com' WHERE customerKey='2001';"

docker exec -it postgres psql -U postgres -d mydb \
  -c "SELECT \"customerKey\", email FROM public.mysql_customers_data_customers WHERE \"customerKey\"='2001';"
```

**4. Add a new column → schema evolution**
```bash
docker exec -it mysql mysql -uroot -prootpwd -h 127.0.0.1 -P 3306 \
  -e "ALTER TABLE customers_data.customers ADD COLUMN phone VARCHAR(32) NULL;"

# Column appears in Postgres automatically
docker exec -it postgres psql -U postgres -d mydb \
  -c '\d public.mysql_customers_data_customers'
```

---

## Makefile shortcuts

```bash
make up        # start stack
make down      # stop stack
make register  # register both connectors
make logs      # follow Kafka Connect logs
make psql      # open PostgreSQL shell
make mysql     # open MySQL shell
```

---

## Stack

| Component | Role |
|-----------|------|
| MySQL | Source database |
| Debezium MySQL Connector | Reads MySQL binlog, emits CDC events |
| Apache Kafka + Zookeeper | Event streaming backbone |
| Kafka Connect | Integration runtime |
| JDBC Sink Connector | Writes events to PostgreSQL |
| PostgreSQL | Target database |
| Kafka-UI | Pipeline monitoring at `localhost:8080` |
| Docker Compose | Orchestrates all 6 services |

---

## Why this matters

CDC is the backbone of modern data engineering. It powers real-time analytics, zero-downtime database migrations, event-driven microservices, and data lake ingestion. This project demonstrates the full pattern end-to-end — the same architecture used in production at companies running Debezium on Kafka at scale.

---

## Author

**Abhista Atchutuni** — AI & Data Engineer  
[linkedin.com/in/abhistac](https://linkedin.com/in/abhistac) · [abhistaca@gmail.com](mailto:abhistaca@gmail.com) · [abhistac.github.io](https://abhistac.github.io)
