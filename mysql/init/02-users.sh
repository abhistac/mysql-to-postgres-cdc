#!/bin/bash
# Creates the Debezium replication user from environment variables passed
# to the MySQL container. The MySQL image executes any *.sh in this
# directory after the *.sql files have been sourced as root.
set -euo pipefail

mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<SQL
CREATE USER IF NOT EXISTS '${MYSQL_DEBEZIUM_USER}'@'%' IDENTIFIED BY '${MYSQL_DEBEZIUM_PASSWORD}';

GRANT SELECT, RELOAD, SHOW DATABASES,
      REPLICATION SLAVE, REPLICATION CLIENT,
      LOCK TABLES, SHOW VIEW
  ON *.* TO '${MYSQL_DEBEZIUM_USER}'@'%';

FLUSH PRIVILEGES;
SQL
