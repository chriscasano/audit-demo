echo -e "Waiting for Nifi to Start"
until $(curl --output /dev/null --silent --head --fail http://localhost:9095/nifi); do
    printf '.'
    sleep 5
done

# Create Cockroach, Kafka and Nifi clusters
echo -e "*******************************"
echo -e "Loading the audit demo flow for NiFi"
echo -e "*******************************"
# Get NiFi Template Id
templateId=$(curl http://localhost:9095/nifi-api/flow/templates | jq '.templates[] | select( .template.name=="audit-demo-docker") | .id' )

#Get root process group
rootpg=$(curl http://localhost:9095/nifi-api/flow/process-groups/root | jq '.processGroupFlow.id'  | sed "s/\"//g")

# Apply template
curl -i -X POST -H 'Content-Type:application/json' -d '{"originX": 2.0,"originY": 3.0,"templateId": '$templateId'}' http://localhost:9095/nifi-api/process-groups/$rootpg/template-instance

# Get Controller Services
conserv=$(curl http://localhost:9095/nifi-api/flow/process-groups/$rootpg/controller-services | jq '.controllerServices[].component.id' | sed "s/\"//g")

# Enable Controller Services
for id in $conserv
do
  echo "Enabling Controller Servics: " $id
  curl -i -X PUT -H 'Content-Type:application/json' -d '{"state": "ENABLED","revision": {"clientId":"value","version":0}}' http://localhost:9095/nifi-api/controller-services/$id/run-status
done

# Get Processors
processors=$(curl http://localhost:9095/nifi-api/flow/process-groups/root | jq '.processGroupFlow.flow.processors[].id' | sed "s/\"//g")

# Start Processors
for p in $processors
do
  echo "Enabling Processor: " $p
  curl -i -X PUT -H 'Content-Type:application/json' -d '{"state": "RUNNING","revision": {"clientId":"value","version":0}}' http://localhost:9095/nifi-api/processors/$p/run-status
done


echo -e "*******************************"
echo -e "Running Bank Demo"
echo -e "*******************************"
docker-compose exec -T roach-0 ./cockroach workload init bank "postgresql://roach-0:26257/bank?sslmode=disable"
docker-compose exec -T roach-0 ./cockroach sql --insecure --host roach-0 --echo-sql < sql/bank-docker_KEYS.sql
docker-compose exec -T roach-0 ./cockroach workload run bank --duration 10s "postgresql://roach-0:26257/bank?sslmode=disable"
echo "Wait for 10 secs..."
sleep 10

# Output IPs
open http://localhost:9095/nifi

echo -e "******** Connect **************"
echo -e "Kafka Broker: localhost:9092 "
echo -e "NiFi UI: http://localhost:9095/nifi"
echo -e "Cockroach Admin UI: http://localhost:8090"
echo -e "SQL (local crdb): cockroach sql --insecure --host localhost --port 5432 --database cis"
echo -e "SQL (no local crdb): docker exec -it roach-0 /cockroach/cockroach.sh sql --insecure --host haproxy --port 5432 --database cis"
echo -e "*******************************"
echo -e ""
echo -e "To run more data, run the following command: docker-compose exec -T roach-0 ./cockroach workload run bank --duration 10s \"postgresql://roach-0:26257/bank?sslmode=disable\" "
echo -e "You can adjust the duration parameter to run it for longer"
echo -e ""
echo -e "Below is a quick view of the audit table.  If you don't see any records, check your NiFi flow: "
docker exec -it roach-0 /cockroach/cockroach.sh sql --insecure --host haproxy --port 5432 --database cis -e "select tbl, pk, ts, action, substring(new,0,30) from audit limit 5"
