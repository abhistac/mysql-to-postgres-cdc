#!/usr/bin/env bash
# Registers the Debezium MySQL Source connector.
set -euo pipefail

if [ -f .env ]; then
  set -a; source .env; set +a
fi

: "${MYSQL_DEBEZIUM_USER:?MYSQL_DEBEZIUM_USER not set (copy .env.example to .env)}"
: "${MYSQL_DEBEZIUM_PASSWORD:?MYSQL_DEBEZIUM_PASSWORD not set}"

# shellcheck source=scripts/_register-connector.sh
source "$(dirname "$0")/_register-connector.sh"

register_connector \
  "mysql-source" \
  "connectors/mysql-source.json" \
  '${MYSQL_DEBEZIUM_USER} ${MYSQL_DEBEZIUM_PASSWORD}'
