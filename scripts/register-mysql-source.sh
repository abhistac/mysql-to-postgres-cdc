#!/usr/bin/env bash
set -euo pipefail
echo "Registering Debezium MySQL Source connector..."
curl -s -X POST -H "Content-Type: application/json" \
     --data @connectors/mysql-source.json \
     http://localhost:8083/connectors | jq .
echo "Done."
