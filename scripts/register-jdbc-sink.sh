#!/usr/bin/env bash
# Registers the Confluent JDBC Sink (PostgreSQL).
set -euo pipefail

if [ -f .env ]; then
  set -a; source .env; set +a
fi

: "${POSTGRES_USER:?POSTGRES_USER not set (copy .env.example to .env)}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD not set}"
: "${POSTGRES_DB:?POSTGRES_DB not set}"

# shellcheck source=scripts/_register-connector.sh
source "$(dirname "$0")/_register-connector.sh"

register_connector \
  "jdbc-sink-postgres" \
  "connectors/jdbc-sink.json" \
  '${POSTGRES_USER} ${POSTGRES_PASSWORD} ${POSTGRES_DB}'
