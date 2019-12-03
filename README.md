# Audit Demo

This demo shows how to create an audit table in CockroachDB using change data capture.  The demonstration uses the CockroachDB Bank workload.  Each insert/update/delete statement is capture via CHANGEFEED and sent to a topic in Kafka.  From there, Apache Nifi picks up the data in the Kafka topic, organizes the events and writes them to an audit table in CockroachDB.  You can run this demo using 1 of the following two methods: <br>
-  Docker-Compose (Stable) <br>
- Roachprod (In Development) <br>

![Audit Demo](/images/Audit_Demo.png)

## 1) Docker Compose

#### Before you run anything...

Be sure to update your Cockroach Organization and License in sql/bank.sql file since this demo uses CHANGEFEED which is under the enterprise license

`SET CLUSTER SETTING cluster.organization = '';`<br>
`SET CLUSTER SETTING enterprise.license = '';`

#### Bring up the environment

`docker-compose up --build`

Wait for the NiFi to come up before going to the next step.  You can also check all of the containers are running by running `docker-compose ps`

The script below will deploy a Nifi template the grabs the bank data from the Kafka queue, organizes it and then puts into the audit table.  All you need to do is start up the Controller Services for the Record Readers (JSON/Avro) and the DBConnectionPool Services.  Start the Processors and off you go.

`deploy-docker.sh`

#### UIs

- Apache Nifi: http://localhost:9095/nifi/
- Cockroach Admin: http://localhost:8090
- Kafka Control Center: http://localhost:9021/clusters


#### CLI

- SQL (local crdb): `cockroach sql --insecure --host localhost --port 5432 --database cis`
- SQL (none): `docker exec -it roach-0 /cockroach/cockroach.sh sql --insecure --host haproxy --port 5432 --database cis`


## 2) Roach Prod

### Before you run anything...

Be sure to update your Cockroach Organization and License in sql/bank.sql file since this demo uses CHANGEFEED which is under the enterprise license.

`SET CLUSTER SETTING cluster.organization = '';`<br>
`SET CLUSTER SETTING enterprise.license = '';`

### Run it
The deployment is very straightforward.  You can run the deploy-roachprod.sh script which will spin up a 3 node Cockroach cluster, 1 workload node, 1 Kafka node and 1 NiFi node

`deploy-roachprod.sh`

The script will ask you to update the following items in the deployed NiFi flow:
- The Kafka broker in the ConsumeKafka_2 Processor
- The Database ip:port for the DBConnectionPool
- Starting all of the Controller Services in the flow.

#### UI

- Apache Nifi: http://`roachprod ip $CLUSTER:6 -external`:8080/nifi/
- Cockroach Admin: http://`roachprod ip $CLUSTER:1 -external`:26258
- Kafka Control Center: http://`roachprod ip $CLUSTER:5 -external`:9021/clusters

#### CLI

- SQL: `roachprod ssh $CLUSTER:1`

## Run the demo

You can demonstrate how the data flows from the Bank table --> Kafka --> Nifi --> Audit table

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


### If desired, test you can test Kafka consumption

`docker-compose exec -T connect /usr/bin/kafka-console-consumer --bootstrap-server broker:29092 --property schema.registry.url=http://schema-registry:8081 --topic bank_json_bank --from-beginning`

`roachprod run $KAFKA "/usr/local/confluent/bin/kafka-console-consumer --bootstrap-server localhost:9092 --property schema.registry.url=http://localhost:8081 --topic bank_json_bank --from-beginning"`
