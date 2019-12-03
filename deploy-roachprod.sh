# Create Cockroach, Kafka and Nifi clusters

export CLUSTER="${USER:0:6}-test"
export HAPROXY=${CLUSTER}:4
export KAFKA=${CLUSTER}:5
export NIFI=${CLUSTER}:6
roachprod create ${CLUSTER} -n 6 --local-ssd

# Add gcloud SSH key. Optional for most commands, but some require it.
#ssh-add ~/.ssh/google_compute_engine

echo "----------------"
echo "Stage Binaries"
echo "----------------"

roachprod stage ${CLUSTER} workload
roachprod stage $CLUSTER release latest

echo "----------------"
echo "Start Up Services"
echo "----------------"

# Create Cockroach cluster
echo "installing cockroach..."
roachprod start ${CLUSTER}:1-3

echo "installing haproxy..."
roachprod run ${CLUSTER}:4 'sudo apt-get update'
roachprod run ${CLUSTER}:4 'sudo apt-get install -y haproxy'
roachprod run ${CLUSTER}:4 "./cockroach gen haproxy --insecure --host `roachprod ip $CLUSTER:1 --external`"
roachprod run ${CLUSTER}:4 'cat haproxy.cfg'
roachprod run ${CLUSTER}:4 'haproxy -f haproxy.cfg &' &

# Create Kafka cluster (Kafka install is in /usr/local/confluent)
echo "installing kafka..."
roachprod install ${KAFKA} confluent
roachprod run ${KAFKA} '/usr/local/confluent/bin/confluent start'

# Create NiFi cluster
echo "installing nifi..."
roachprod run ${NIFI} 'sudo apt-get update'
roachprod run ${NIFI} 'sudo apt-get install -y openjdk-8-jre-headless'
roachprod run ${NIFI} 'sudo mkdir -p /opt/nifi'
roachprod run ${NIFI} 'curl -s https://archive.apache.org/dist/nifi/1.9.2/nifi-1.9.2-bin.tar.gz | sudo tar -C /opt/nifi -xz'
roachprod run ${NIFI} 'wget -nv https://jdbc.postgresql.org/download/postgresql-42.2.8.jar'
roachprod put ${NIFI} './nifi/audit-demo-roachprod.xml'
roachprod run ${NIFI} 'sudo ln -s /opt/nifi/nifi-1.9.2 /opt/nifi/nifi-current'
roachprod run ${NIFI} 'sudo mkdir -p /opt/nifi/nifi-1.9.2/conf/templates'
roachprod run ${NIFI} 'sudo mkdir -p /opt/nifi/nifi-1.9.2/jdbc'
roachprod run ${NIFI} 'sudo mv audit-demo-roachprod.xml /opt/nifi/nifi-1.9.2/conf/templates'
roachprod run ${NIFI} 'sudo mv postgresql-42.2.8.jar /opt/nifi/nifi-1.9.2/extensions'
roachprod run ${NIFI} 'sudo /opt/nifi/nifi-1.9.2/bin/nifi.sh start'

sleep 60

# Get NiFi Template Id
templateId=$(curl http://`roachprod ip $NIFI --external`:8080/nifi-api/flow/templates | jq '.templates[0] | .template.name="audit-demo-roachprod" | .id' )

#Get root process group
rootpg=$(curl http://`roachprod ip $NIFI --external`:8080/nifi-api/flow/process-groups/root | jq '.processGroupFlow.id'  | sed "s/\"//g")

# Apply template
curl -i -X POST -H 'Content-Type:application/json' -d '{"originX": 2.0,"originY": 3.0,"templateId": '$templateId'}' http://`roachprod ip $NIFI --external`:8080/nifi-api/process-groups/$rootpg/template-instance

# Get Controller Services
conserv=$(curl http://`roachprod ip $NIFI --external`:9095/nifi-api/flow/process-groups/$rootpg/controller-services | jq '.controllerServices[].component.id')

echo -e "***************************************************"
echo -e "***************************************************"
echo -e "NiFi UI: http://`roachprod ip ${NIFI} --external`:8080/nifi""
read -p "Please update the NiFi ConsumeKafka_2 Processor with Kafka Broker property to:  `roachprod ip $KAFKA`:9092
Press Enter When Complete" kb

read -p "Please update the DBConnectionPool with a the proper DB url:  `roachprod ip $HAPROXY`:26257
Press Enter When Complete" db


echo "----------------"
echo "Run Workloads"
echo "----------------"

roachprod run ${CLUSTER}:1 -- "./workload init bank"

cat sql/bank-roachprod.sql > sql/bank-roachprod2.sql
echo -e "CREATE CHANGEFEED FOR TABLE bank INTO 'kafka://`roachprod ip ${KAFKA} --external`:9092?topic_prefix=bank_json_' WITH updated, key_in_value, format = json, confluent_schema_registry = 'http://`roachprod ip ${KAFKA} --external`:8081';" >> sql/bank-roachprod2.sql

roachprod put ${CLUSTER} './sql'
roachprod run $CLUSTER:1 <<EOF
./cockroach sql --insecure --host=`roachprod ip $CLUSTER:1` --echo-sql < sql/bank-roachprod2.sql
EOF

# Check the admin UI.
roachprod admin --open ${CLUSTER}:1

#roachprod run ${CLUSTER}:4 -- "./workload run bank --duration 5m {pgurl:1-3}"

# Output IPs
echo -e "Kafka: `roachprod ip ${KAFKA} --external`"
echo -e "NiFi: `roachprod ip ${NIFI} --external`"
echo -e "NiFi UI: http://`roachprod ip ${NIFI} --external`:8080/nifi"


# Run a workload.
roachprod run ${CLUSTER}:4 -- ./workload run bank --duration=10m

# Open a SQL connection to the first node.
#roachprod sql ${CLUSTER}:1
