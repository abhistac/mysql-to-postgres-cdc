# MySQL → PostgreSQL CDC with Debezium, Kafka, and JDBC Sink

This project demonstrates a **real-time Change Data Capture (CDC) pipeline** using Debezium, Kafka Connect, and JDBC Sink to replicate an on-premises MySQL database into PostgreSQL.

The entire stack (MySQL, Kafka, Zookeeper, Kafka Connect, Kafka-UI, PostgreSQL) runs on **Docker Compose**.

---

## ✨ What it demonstrates
- **Initial snapshot + continuous CDC** (inserts, updates; optional hard deletes)
- **Topic → table naming normalization** (avoid invalid `schema.table` names in Postgres)
- **Schema evolution** with `auto.evolve=true`
- **Containerized setup** for reproducibility

---

## 🚀 Quick start

```bash
# Build and start the stack
docker compose up -d --build

# Register source (Debezium MySQL) and sink (JDBC → Postgres)
bash scripts/register-mysql-source.sh
bash scripts/register-jdbc-sink.sh

# Check connectors
curl -s http://localhost:8083/connectors/mysql-source/status | jq .
curl -s http://localhost:8083/connectors/jdbc-sink-postgres/status | jq .
```

---

## 🔍 Demo Scenarios

### 1. Verify snapshot
```bash
docker exec -it postgres psql -U postgres -d mydb -c "\d"
docker exec -it postgres psql -U postgres -d mydb -c "SELECT COUNT(*) FROM public.mysql_customers_data_customers;"
```

### 2. Insert new rows
```bash
docker exec -i mysql mysql -uroot -prootpwd -h 127.0.0.1 -P 3306 customers_data < mysql/sql/add_demo_rows.sql
docker exec -it postgres psql -U postgres -d mydb -c "SELECT COUNT(*) FROM public.mysql_customers_data_customers;"
```

### 3. Update rows
```bash
docker exec -it mysql mysql -uroot -prootpwd -h 127.0.0.1 -P 3306   -e "UPDATE customers_data.customers SET email='ravi.updated@example.com' WHERE customerKey='2001';"

docker exec -it postgres psql -U postgres -d mydb -c "SELECT \"customerKey\", email FROM public.mysql_customers_data_customers WHERE \"customerKey\"='2001';"
```

### 4. Delete rows (soft delete, default)
```bash
docker exec -it mysql mysql -uroot -prootpwd -h 127.0.0.1 -P 3306   -e "DELETE FROM customers_data.customers WHERE customerKey='2003';"

# MySQL row count will drop, Postgres keeps it (soft delete)
```

### 5. Schema evolution
```bash
docker exec -it mysql mysql -uroot -prootpwd -h 127.0.0.1 -P 3306   -e "ALTER TABLE customers_data.customers ADD COLUMN phone VARCHAR(32) NULL;
      UPDATE customers_data.customers SET phone='+1-555-0101' WHERE customerKey='2001';"

docker exec -it postgres psql -U postgres -d mydb -c '\d public.mysql_customers_data_customers'
```

---

## ⚡ Extensions

- **Hard deletes**  
  - In source: set `"transforms.unwrap.delete.handling.mode": "none"`  
  - In sink: set `"pk.mode": "record_key"`, `"delete.enabled": "true"`  
  - Recreate connectors → deletes propagate physically.

- **Lowercase columns**  
  Postgres is case-sensitive for quoted identifiers.  
  You can either:
  - Use a view (`CREATE VIEW customers_v …`) with lowercase aliases, or
  - Add a `ReplaceField` SMT in the sink to rename fields automatically.

- **Monitoring**  
  - Kafka-UI is included at [http://localhost:8080](http://localhost:8080).  
  - Check connector/task logs with:  
    ```bash
    docker logs -f connect
    ```

- **Automation**  
  A sample `Makefile` is included for quick ops:  
  ```bash
  make up      # start stack
  make down    # stop stack
  make logs    # follow connect logs
  make register # register both connectors
  make psql    # open Postgres shell
  make mysql   # open MySQL shell
  ```

---

## 📌 Tech stack
- **MySQL** (source DB)
- **Apache Kafka + Zookeeper** (event backbone)
- **Debezium MySQL Connector** (CDC source)
- **Kafka Connect** (integration runtime)
- **JDBC Sink Connector** (target DB)
- **PostgreSQL** (destination DB)
- **Kafka-UI** (for monitoring)

---

## 📖 Resume-ready description

*MySQL → PostgreSQL CDC via Debezium & Kafka Connect (Docker Compose)*
