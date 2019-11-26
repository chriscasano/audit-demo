# Audit Demo

This demo shows how to create an audit table in CockroachDB using change data capture.  You can run this demo using 1 of the following two methods.
1) Docker-Compose (Stable)
2) Roachprod (In Development)


![Audit Demo](/images/Audit_Demo.png)

## 1) Docker

### Before you run anything...

Be sure to update your Cockroach Organization and License in sql/audit_table.sql file since this demo uses CHANGEFEED which is under the enterprise license

### Bring It Up

`docker-compose up --build`

### Connect to Cockroach and run the audit scripts

`docker-compose exec -T roach-0 ./cockroach sql --insecure --host roach-0 < sql/audit.sql`

### If desired, test Kafka consumption

`docker-compose exec -T connect /usr/bin/kafka-console-consumer --bootstrap-server broker:29092 --property schema.registry.url=http://schema-registry:8081 --topic cis_json_customers --from-beginning`

### For NiFi, install it on your local machine and start it up
<i>more install options here: https://nifi.apache.org/docs/nifi-docs/html/getting-started.html#downloading-and-installing-nifi</i>

`brew install nifi`

`bin/nifi.sh start`

Import the nifi/audit-demo.xml template, start up the Controller Services for the Record Readers (JSON/Avro) and the DBConnectionPool Services.  Start the Processors and off you go.


### UIs

Control Center: http://localhost:9021/clusters

Cockroach UI: http://localhost:8090


## 2) Roach Prod

### Before you run anything...

Be sure to update your Cockroach Organization and License in sql/audit_table.sql file since this demo uses CHANGEFEED which is under the enterprise license

### Run it
The deployment is very straightforward.  You can run the deploy,sh which will spin up a 3 node Cockroach cluster, a 1 Kafka node, 1 NiFi node and a Cockroach workload node.

`deploy.sh`

Go to the NiFi UI which is the last line output in deploy.sh.  http://<external-ip>:8080/nifi
Deploy the 'audit-demo' template which is already pre-loaded in the NiFi template library
Change the ConsumeKafka_2 processor.

The JDBC connection URL needs to be updated as well

Database driver location needs to be updated too

Make sure to update Kafka Consumer broker in Nifi

<u>Mapping</u>

tbl <-- kafka.topic (attr)
pk  <-- kafka.key (attr)
attr <-- after.<name> (payload)
ts <-- updated (payload)
new <-- after.<name>.value (payload)
prev
action <--  ${after:isEmpty():ifElse('Delete','Insert/Update')}
