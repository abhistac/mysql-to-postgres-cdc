.PHONY: up down build register status logs psql mysql reset \
        demo-insert demo-update demo-schema smoke help

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

register: ## Register both Debezium source and JDBC sink connectors (idempotent)
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
	docker exec -it postgres sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

mysql: ## Open a MySQL shell
	docker exec -it mysql sh -c 'mysql -uroot -p"$$MYSQL_ROOT_PASSWORD" customers_data'

# ── Demo ──────────────────────────────────────────────────────────────────────

demo-insert: ## Insert 3 demo rows into MySQL and verify they appear in Postgres
	@echo "Inserting demo rows into MySQL..."
	@docker exec -i mysql sh -c 'mysql -uroot -p"$$MYSQL_ROOT_PASSWORD" customers_data' \
	  < mysql/sql/add_demo_rows.sql
	@echo ""
	@echo "Postgres row count:"
	@docker exec -i postgres sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" \
	  -c "SELECT COUNT(*) AS total_rows FROM public.mysql_customers_data_customers;"'

demo-update: ## Update a row in MySQL and verify it propagates to Postgres
	@docker exec -i mysql sh -c 'mysql -uroot -p"$$MYSQL_ROOT_PASSWORD" \
	  -e "UPDATE customers_data.customers SET email='\''updated@example.com'\'' WHERE customerKey='\''2001'\'';"'
	@sleep 2
	@docker exec -i postgres sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" \
	  -c "SELECT \"customerKey\", email FROM public.mysql_customers_data_customers WHERE \"customerKey\"='\''2001'\'';"'

demo-schema: ## Add a column to MySQL and verify Postgres schema evolves automatically
	@docker exec -i mysql sh -c 'mysql -uroot -p"$$MYSQL_ROOT_PASSWORD" \
	  -e "ALTER TABLE customers_data.customers ADD COLUMN phone VARCHAR(32) NULL;"'
	@sleep 3
	@echo "Postgres schema after ALTER TABLE:"
	@docker exec -i postgres sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" \
	  -c "\d public.mysql_customers_data_customers"'

# ── Test ──────────────────────────────────────────────────────────────────────

smoke: ## Run the end-to-end smoke test (requires running stack + registered connectors)
	@bash scripts/smoke-test.sh

# ── Help ──────────────────────────────────────────────────────────────────────

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
