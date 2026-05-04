#!/usr/bin/env bash
set -euo pipefail

CONNECT_URL="http://localhost:8083"
CONNECTOR_NAME="mysql-source"

echo "Registering Debezium MySQL Source connector..."

response=$(curl -sf -X POST \
  -H "Content-Type: application/json" \
  --data @connectors/mysql-source.json \
  "${CONNECT_URL}/connectors")

echo "$response" | jq .
echo "Done: ${CONNECTOR_NAME} registered."
