#!/usr/bin/env bash
# Shared helper: idempotently register (or update) a Kafka Connect connector.
#
# Usage:
#   register_connector <connector-name> <config-file> <envsubst-vars>
#
# - <envsubst-vars> is a single string listing the placeholders to substitute,
#   e.g. '${POSTGRES_USER} ${POSTGRES_PASSWORD}'. Restricting the list keeps
#   Kafka Connect's own ${topic}-style references untouched.
# - First run POSTs /connectors; subsequent runs PUT /connectors/<name>/config.
set -euo pipefail

CONNECT_URL="${CONNECT_URL:-http://localhost:8083}"

register_connector() {
  local name="$1"
  local config_file="$2"
  local vars="$3"

  local config
  config=$(envsubst "${vars}" < "${config_file}")

  echo "Registering ${name}..."

  if curl -sf -o /dev/null "${CONNECT_URL}/connectors/${name}"; then
    echo "  exists — updating config via PUT"
    local inner
    inner=$(echo "${config}" | jq '.config')
    curl -sf -X PUT \
      -H "Content-Type: application/json" \
      --data "${inner}" \
      "${CONNECT_URL}/connectors/${name}/config" | jq .
  else
    curl -sf -X POST \
      -H "Content-Type: application/json" \
      --data "${config}" \
      "${CONNECT_URL}/connectors" | jq .
  fi

  echo "Done: ${name} registered."
}
