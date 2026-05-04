#!/usr/bin/env bash
# Registers the Confluent JDBC Sink (PostgreSQL) idempotently:
#   - first run: POST /connectors creates it
#   - subsequent runs: PUT /connectors/<name>/config updates it
set -euo pipefail

CONNECT_URL="${CONNECT_URL:-http://localhost:8083}"
CONNECTOR_NAME="jdbc-sink-postgres"
CONFIG_FILE="connectors/jdbc-sink.json"

if [ -f .env ]; then
  set -a; source .env; set +a
fi

: "${POSTGRES_USER:?POSTGRES_USER not set (copy .env.example to .env)}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD not set}"
: "${POSTGRES_DB:?POSTGRES_DB not set}"

# Substitute only our placeholders so Kafka Connect's own ${...} refs stay intact.
config=$(envsubst '${POSTGRES_USER} ${POSTGRES_PASSWORD} ${POSTGRES_DB}' < "${CONFIG_FILE}")

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
