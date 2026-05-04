#!/usr/bin/env bash
# Registers the Debezium MySQL Source connector idempotently:
#   - first run: POST /connectors creates it
#   - subsequent runs: PUT /connectors/<name>/config updates it
set -euo pipefail

CONNECT_URL="${CONNECT_URL:-http://localhost:8083}"
CONNECTOR_NAME="mysql-source"
CONFIG_FILE="connectors/mysql-source.json"

if [ -f .env ]; then
  set -a; source .env; set +a
fi

: "${MYSQL_DEBEZIUM_USER:?MYSQL_DEBEZIUM_USER not set (copy .env.example to .env)}"
: "${MYSQL_DEBEZIUM_PASSWORD:?MYSQL_DEBEZIUM_PASSWORD not set}"

# Substitute only our placeholders so Kafka Connect's own ${...} refs stay intact.
config=$(envsubst '${MYSQL_DEBEZIUM_USER} ${MYSQL_DEBEZIUM_PASSWORD}' < "${CONFIG_FILE}")

echo "Registering ${CONNECTOR_NAME}..."

if curl -sf -o /dev/null "${CONNECT_URL}/connectors/${CONNECTOR_NAME}"; then
  echo "  exists — updating config via PUT"
  inner=$(echo "${config}" | jq '.config')
  response=$(curl -sf -X PUT \
    -H "Content-Type: application/json" \
    --data "${inner}" \
    "${CONNECT_URL}/connectors/${CONNECTOR_NAME}/config")
else
  response=$(curl -sf -X POST \
    -H "Content-Type: application/json" \
    --data "${config}" \
    "${CONNECT_URL}/connectors")
fi

echo "${response}" | jq .
echo "Done: ${CONNECTOR_NAME} registered."
