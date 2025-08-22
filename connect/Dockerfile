FROM confluentinc/cp-kafka-connect:7.6.1

# Debezium MySQL connector from Maven Central (retries for flaky networks)
RUN set -e; \
  curl -fL --retry 5 --retry-delay 2 --retry-connrefused \
    -o /tmp/debezium-mysql.tgz \
    https://repo.maven.apache.org/maven2/io/debezium/debezium-connector-mysql/2.6.1.Final/debezium-connector-mysql-2.6.1.Final-plugin.tar.gz \
  && mkdir -p /usr/share/java/debezium-connector-mysql \
  && tar -xzf /tmp/debezium-mysql.tgz -C /usr/share/java/debezium-connector-mysql --strip-components=1 \
  && rm /tmp/debezium-mysql.tgz

# Confluent JDBC Sink via Confluent Hub
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.7.4
