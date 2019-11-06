## Wait!  Before you run anything...

Before you kickoff Docker Compose, be sure to update your Cockroach Organization and License in sql/audit_table.sql file since this demo uses CHANGEFEED which is under the enterprise license



## Run
docker-compose up --build

## Connect to Cockroach and run the audit script

/cockroach/cockroach sql --insecure --host roach-0 < sql/audit_table_KEYS.sql


## Test Kafka consumption

docker exec -it connect /bin/bash
/usr/bin/kafka-avro-console-consumer --bootstrap-server broker:29092 --property schema.registry.url=http://schema-registry:8081 --topic cis_avro_customers --from-beginning


## UIs

Confluent Control Center: http://localhost:9021/clusters

Cockroach UI: http://localhost:8090
