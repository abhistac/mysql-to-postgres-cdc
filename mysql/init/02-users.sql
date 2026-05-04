-- Debezium user — needs REPLICATION SLAVE to read the binlog.
-- RELOAD and LOCK TABLES are required for the initial snapshot.
CREATE USER IF NOT EXISTS 'debezium'@'%' IDENTIFIED BY 'dbz';

GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT, LOCK TABLES ON *.* TO 'debezium'@'%';
GRANT SHOW VIEW ON *.* TO 'debezium'@'%';

FLUSH PRIVILEGES;
