#!/usr/bin/env bash
# Check the state of every connector in the cluster.
# Both connectors should show "state": "RUNNING" when healthy.
set -euo pipefail

CONNECT_URL="${CONNECT_URL:-http://localhost:8083}"

for name in mysql-source jdbc-sink-postgres; do
  echo "=== ${name} ==="
  curl -sf "${CONNECT_URL}/connectors/${name}/status" | jq '{
    state: .connector.state,
    tasks: [.tasks[] | {id: .id, state: .state}]
  }'
  echo ""
done
