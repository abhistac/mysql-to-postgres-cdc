#!/usr/bin/env bash
set -euo pipefail
echo "Registering JDBC Sink connector (PostgreSQL)..."
curl -s -X POST -H "Content-Type: application/json" \
     --data @connectors/jdbc-sink.json \
     http://localhost:8083/connectors | jq .
echo "Done."
