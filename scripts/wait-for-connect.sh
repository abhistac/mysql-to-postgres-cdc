#!/usr/bin/env bash
# Polls the Kafka Connect REST API until it responds.
# Called automatically by `make up` so connector registration never races.
set -euo pipefail

CONNECT_URL="http://localhost:8083"
MAX_WAIT=120
INTERVAL=5
elapsed=0

echo "Waiting for Kafka Connect at ${CONNECT_URL}..."

until curl -sf "${CONNECT_URL}/connectors" > /dev/null 2>&1; do
  if [ "$elapsed" -ge "$MAX_WAIT" ]; then
    echo "ERROR: Kafka Connect did not become ready within ${MAX_WAIT}s."
    echo "Check logs with: docker compose logs connect"
    exit 1
  fi
  printf "  still waiting... (%ds elapsed)\n" "$elapsed"
  sleep "$INTERVAL"
  elapsed=$((elapsed + INTERVAL))
done

echo "Kafka Connect is ready."
