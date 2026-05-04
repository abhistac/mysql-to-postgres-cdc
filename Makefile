.PHONY: up down build register status logs psql mysql reset help

# ── Docker Compose ────────────────────────────────────────────────────────────

up: ## Start the full 6-service stack (builds Connect image on first run)
	docker compose up -d --build
	@echo ""
	@echo "Stack started. Waiting for Kafka Connect to be ready..."
	@bash scripts/wait-for-connect.sh
	@echo ""
	@echo "Next: run 'make register' to register the source and sink connectors."

down: ## Stop and remove all containers (data is NOT persisted between runs)
	docker compose down

build: ## Rebuild the Kafka Connect image (run after changing connect/Dockerfile)
	docker compose build connect

reset: ## Full teardown including volumes — use when you want a clean slate
	docker compose down -v

# ── Connectors ────────────────────────────────────────────────────────────────

register: ## Register both Debezium source and JDBC sink connectors
	@bash scripts/register-mysql-source.sh
	@bash scripts/register-jdbc-sink.sh
	@echo ""
	@echo "Connectors registered. Run 'make status' to verify."

status: ## Check connector status (both should show state: RUNNING)
	@bash scripts/check-status.sh

# ── Shells ────────────────────────────────────────────────────────────────────

logs: ## Follow Kafka Connect logs
	docker compose logs -f connect

psql: ## Open a PostgreSQL shell
	docker exec -it postgres psql -U postgres -d mydb

mysql: ## Open a MySQL shell
	docker exec -it mysql mysql -uroot -prootpwd customers_data

# ── Demo ──────────────────────────────────────────────────────────────────────

demo-insert: ## Insert 3 demo rows into MySQL and verify they appear in Postgres
	@echo "Inserting demo rows into MySQL..."
	docker exec -i mysql mysql -uroot -prootpwd -h 127.0.0.1 -P 3306 \
	  customers_data < mysql/sql/add_demo_rows.sql
	@echo ""
	@echo "Checking Postgres row count..."
	docker exec -it postgres psql -U postgres -d mydb \
	  -c "SELECT COUNT(*) AS total_rows FROM public.mysql_customers_data_customers;"

demo-update: ## Update a row in MySQL and verify it propagates to Postgres
	docker exec -it mysql mysql -uroot -prootpwd -h 127.0.0.1 -P 3306 \
	  -e "UPDATE customers_data.customers SET email='updated@example.com' WHERE customerKey='2001';"
	@sleep 2
	docker exec -it postgres psql -U postgres -d mydb \
	  -c "SELECT \"customerKey\", email FROM public.mysql_customers_data_customers WHERE \"customerKey\"='2001';"

demo-schema: ## Add a column to MySQL and verify Postgres schema evolves automatically
	docker exec -it mysql mysql -uroot -prootpwd -h 127.0.0.1 -P 3306 \
	  -e "ALTER TABLE customers_data.customers ADD COLUMN phone VARCHAR(32) NULL;"
	@sleep 3
	@echo "Postgres schema after ALTER TABLE:"
	docker exec -it postgres psql -U postgres -d mydb \
	  -c "\d public.mysql_customers_data_customers"

# ── Help ──────────────────────────────────────────────────────────────────────

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
