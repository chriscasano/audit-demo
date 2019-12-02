# Audit Demo

This demo shows how to create an audit table in CockroachDB using change data capture.  The demonstration uses the CockroachDB Bank workload.  Each insert/update/delete statement is capture via CHANGEFEED and sent to a topic in Kafka.  From there, Apache Nifi picks up the data in the Kafka topic, organizes the events and writes them to an audit table in CockroachDB.  You can run this demo using 1 of the following two methods: <br>
-  Docker-Compose (Stable) <br>
- Roachprod (In Development) <br>

![Audit Demo](/images/Audit_Demo.png)

## 1) Docker Compose

#### Before you run anything...

Be sure to update your Cockroach Organization and License in sql/bank.sql file since this demo uses CHANGEFEED which is under the enterprise license

#### Bring up the environment

`docker-compose up --build`

#### UIs

Apache Nifi: http://localhost:9095/nifi/

Cockroach Admin: http://localhost:8090

Kafka Control Center: http://localhost:9021/clusters

#### Run the demo

This script will deploy a Nifi template the grabs the bank data from the Kafka queue, organizes it and then puts into the audit table.  All you need to do is start up the Controller Services for the Record Readers (JSON/Avro) and the DBConnectionPool Services.  Start the Processors and off you go.

`deploy-docker.sh`

You can demonstrate how the data flows from the bank table --> Kafka --> Nifi --> audit table

![Bank Demo](/images/Bank_Demo.png)

1) You can show the Bank records here:

`docker exec -it roach-0 /cockroach/cockroach.sh sql --insecure --host haproxy --port 5432 --database bank -e "select * from bank limit 5"`

![Bank Demo](/images/Bank_Table.png)

2) You can show the Kafka queue here:

`docker-compose exec -T connect /usr/bin/kafka-console-consumer --bootstrap-server broker:29092 --property schema.registry.url=http://schema-registry:8081 --topic bank_json_bank --from-beginning`

![Audit Table](/images/Kafka_Topic.png)

3) You can show the Audit records here:

`docker exec -it roach-0 /cockroach/cockroach.sh sql --insecure --host haproxy --port 5432 --database cis -e "select * from audit limit 5"`

![Audit Table](/images/Audit_Table.png)


#### CLI

SQL (local crdb): cockroach sql --insecure --host localhost --port 5432 --database cis

SQL (no local crdb): docker exec -it roach-0 /cockroach/cockroach.sh sql --insecure --host haproxy --port 5432 --database cis


## 2) Roach Prod (In Dev)

### Before you run anything...

Be sure to update your Cockroach Organization and License in sql/bank.sql file since this demo uses CHANGEFEED which is under the enterprise license

### Run it
The deployment is very straightforward.  You can run the deploy,sh which will spin up a 3 node Cockroach cluster, a 1 Kafka node, 1 NiFi node and a Cockroach workload node.

`deploy.sh`

Go to the NiFi UI which is the last line output in deploy.sh.  http://<external-ip>:8080/nifi
Deploy the 'audit-demo' template which is already pre-loaded in the NiFi template library
Change the ConsumeKafka_2 processor.

The JDBC connection URL needs to be updated as well

Database driver location needs to be updated too

Make sure to update Kafka Consumer broker in Nifi

### If desired, test you can test Kafka consumption

`docker-compose exec -T connect /usr/bin/kafka-console-consumer --bootstrap-server broker:29092 --property schema.registry.url=http://schema-registry:8081 --topic bank_json_bank --from-beginning`

`roachprod run $KAFKA "/usr/local/confluent/bin/kafka-console-consumer --bootstrap-server localhost:9092 --property schema.registry.url=http://localhost:8081 --topic bank_json_bank --from-beginning"`


# The Demo

<u>Mapping</u>

tbl <-- kafka.topic (attr)
pk  <-- kafka.key (attr)
attr <-- after.<name> (payload)
ts <-- updated (payload)
new <-- after.<name>.value (payload)
prev
action <--  ${after:isEmpty():ifElse('Delete','Insert/Update')}
