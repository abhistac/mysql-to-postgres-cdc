#!/usr/bin/env bash
set -euo pipefail

CONNECT_URL="http://localhost:8083"
CONNECTOR_NAME="jdbc-sink-postgres"

echo "Registering JDBC Sink connector (PostgreSQL)..."

response=$(curl -sf -X POST \
  -H "Content-Type: application/json" \
  --data @connectors/jdbc-sink.json \
  "${CONNECT_URL}/connectors")

echo "$response" | jq .
echo "Done: ${CONNECTOR_NAME} registered."
