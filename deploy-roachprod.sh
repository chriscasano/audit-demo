# Create Cockroach, Kafka and Nifi clusters

export CLUSTER="${USER:0:6}-test"
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

# Create Kafka cluster (Kafka install is in /usr/local/confluent)
echo "installing kafka..."
roachprod install ${KAFKA} confluent
roachprod run ${KAFKA} '/usr/local/confluent/bin/confluent start'

# Create NiFi cluster
echo "installing nifi..."
roachprod run ${NIFI} 'sudo apt-get update'
roachprod run ${NIFI} 'sudo apt-get install -y openjdk-8-jre-headless'
roachprod run ${NIFI} 'curl -s https://archive.apache.org/dist/nifi/1.9.2/nifi-1.9.2-bin.tar.gz | sudo tar -C /opt/nifi -xz'
roachprod run ${NIFI} 'wget -nv https://jdbc.postgresql.org/download/postgresql-42.2.8.jar'
roachprod put ${NIFI} './nifi/audit-demo-docker.xml'
roachprod run ${NIFI} 'sudo mkdir -p /opt/nifi/nifi-1.9.2/conf/templates'
roachprod run ${NIFI} 'sudo mkdir -p /opt/nifi/nifi-1.9.2/jdbc'
roachprod run ${NIFI} 'sudo mv audit-demo-docker.xml /opt/nifi/nifi-1.9.2/conf/templates'
roachprod run ${NIFI} 'sudo mv postgresql-42.2.8.jar /opt/nifi/nifi-1.9.2/extensions'
roachprod run ${NIFI} 'sudo /opt/nifi/nifi-1.9.2/bin/nifi.sh start'


# Get NiFi Template Id
templateId=$(curl http://`roachprod ip $NIFI --external`:8080/nifi-api/flow/templates | jq '.templates[0] | .template.name="audit-demo-docker" | .id' )

#Get root process group
rootpg=$(curl http://`roachprod ip $NIFI --external`:8080/nifi-api/flow/process-groups/root | jq '.processGroupFlow.id'  | sed "s/\"//g")

# Apply template
curl -i -X POST -H 'Content-Type:application/json' -d '{"originX": 2.0,"originY": 3.0,"templateId": '$templateId'}' http://`roachprod ip $NIFI --external`:8080/nifi-api/process-groups/$rootpg/template-instance

# Get Controller Services
conserv=$(curl http://localhost:9095/nifi-api/flow/process-groups/$rootpg/controller-services | jq '.controllerServices[].component.id')




echo "----------------"
echo "Run Workloads"
echo "----------------"

roachprod run ${CLUSTER}:1 -- "./workload init bank"
roachprod put ${CLUSTER} './sql'
roachprod run $CLUSTER:1 <<EOF
./cockroach sql --insecure --host=`roachprod ip $CLUSTER:1` --echo-sql < sql/bank.sql
EOF

# Check the admin UI.
roachprod admin --open ${CLUSTER}:1

#roachprod run ${CLUSTER}:4 -- "./workload run bank --duration 5m {pgurl:1-3}"

# Output IPs
echo -e "Kafka: `roachprod ip ${KAFKA} --external`"
echo -e "NiFi: `roachprod ip ${NIFI} --external`"
echo -e "NiFi UI: http://`roachprod ip ${NIFI} --external`:8080/nifi"


# Run a workload.
#roachprod run ${CLUSTER}:4 -- ./workload init bank
#roachprod run ${CLUSTER}:4 -- ./workload run bank --read-percent=0 --splits=1000 --concurrency=384 --duration=5m

# Open a SQL connection to the first node.
#roachprod sql ${CLUSTER}:1
