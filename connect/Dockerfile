FROM confluentinc/cp-kafka-connect:7.6.1

# Debezium MySQL connector — pulled from Maven Central rather than Confluent Hub
# because the Confluent Hub version lags behind official Debezium releases.
# Version 2.6.1.Final is tested against cp-kafka-connect:7.6.1 (Kafka 3.6).
RUN set -e; \
  curl -fL --retry 5 --retry-delay 3 --retry-connrefused \
    -o /tmp/debezium-mysql.tgz \
    https://repo.maven.apache.org/maven2/io/debezium/debezium-connector-mysql/2.6.1.Final/debezium-connector-mysql-2.6.1.Final-plugin.tar.gz \
  && mkdir -p /usr/share/java/debezium-connector-mysql \
  && tar -xzf /tmp/debezium-mysql.tgz \
       -C /usr/share/java/debezium-connector-mysql \
       --strip-components=1 \
  && rm /tmp/debezium-mysql.tgz

# Confluent JDBC Sink — used to write Kafka events into PostgreSQL.
# Version 10.7.4 is the last release compatible with the JDBC Sink upsert
# behaviour used in connectors/jdbc-sink.json.
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.7.4
