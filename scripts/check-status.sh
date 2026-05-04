#!/usr/bin/env bash
# Check the status of both connectors.
# Both should show "state": "RUNNING" when healthy.
set -euo pipefail

CONNECT_URL="http://localhost:8083"

echo "=== mysql-source ==="
curl -sf "${CONNECT_URL}/connectors/mysql-source/status" | jq '{
  state: .connector.state,
  tasks: [.tasks[] | {id: .id, state: .state}]
}'

echo ""
echo "=== jdbc-sink-postgres ==="
curl -sf "${CONNECT_URL}/connectors/jdbc-sink-postgres/status" | jq '{
  state: .connector.state,
  tasks: [.tasks[] | {id: .id, state: .state}]
}'
