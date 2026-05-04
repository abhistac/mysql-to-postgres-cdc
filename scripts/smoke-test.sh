#!/usr/bin/env bash
# End-to-end smoke test for the CDC pipeline.
#
# Inserts a row in MySQL, waits for it to appear in Postgres, then
# updates it and waits for the change to propagate. Exits non-zero
# (and dumps connector status for debugging) if either step times out.
#
# Pre-requisites: stack running (`make up`) and connectors registered
# (`make register`).
set -euo pipefail

CONNECT_URL="${CONNECT_URL:-http://localhost:8083}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-60}"
POLL_INTERVAL=2

# Unique key per run so reruns don't collide with stale data.
KEY="smoke-$(date +%s)"
EMAIL_INITIAL="smoke@example.com"
EMAIL_UPDATED="smoke-updated@example.com"

mysql_exec() {
  docker exec -i mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -N -B' "$@"
}

psql_query() {
  docker exec -i postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "'"$1"'"'
}

dump_status_on_failure() {
  echo ""
  echo "── Connector status (for debugging) ──────────────────────────────────"
  curl -sf "${CONNECT_URL}/connectors/mysql-source/status" 2>&1 | jq . || true
  curl -sf "${CONNECT_URL}/connectors/jdbc-sink-postgres/status" 2>&1 | jq . || true
}
trap dump_status_on_failure ERR

wait_for() {
  local description="$1"
  local query="$2"
  local expected="$3"
  local elapsed=0

  echo "Waiting for: ${description}..."
  while [ "${elapsed}" -lt "${TIMEOUT_SECONDS}" ]; do
    actual=$(psql_query "${query}" | tr -d '[:space:]')
    if [ "${actual}" = "${expected}" ]; then
      echo "  ✓ matched after ${elapsed}s"
      return 0
    fi
    sleep "${POLL_INTERVAL}"
    elapsed=$((elapsed + POLL_INTERVAL))
  done

  echo "  ✗ timed out after ${TIMEOUT_SECONDS}s (got '${actual}', expected '${expected}')"
  return 1
}

echo "── Smoke test (key=${KEY}) ──────────────────────────────────────────"

# 1. INSERT propagation
mysql_exec <<SQL
INSERT INTO customers_data.customers (customerKey, firstName, lastName, email)
VALUES ('${KEY}', 'Smoke', 'Test', '${EMAIL_INITIAL}');
SQL

wait_for "INSERT to appear in Postgres" \
  "SELECT email FROM public.mysql_customers_data_customers WHERE \\\"customerKey\\\"='${KEY}'" \
  "${EMAIL_INITIAL}"

# 2. UPDATE propagation
mysql_exec <<SQL
UPDATE customers_data.customers SET email='${EMAIL_UPDATED}' WHERE customerKey='${KEY}';
SQL

wait_for "UPDATE to propagate to Postgres" \
  "SELECT email FROM public.mysql_customers_data_customers WHERE \\\"customerKey\\\"='${KEY}'" \
  "${EMAIL_UPDATED}"

trap - ERR

echo ""
echo "✓ Smoke test passed: insert and update both replicated within ${TIMEOUT_SECONDS}s."
