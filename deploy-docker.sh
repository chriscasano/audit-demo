# Create Cockroach, Kafka and Nifi clusters
echo -e "*******************************"
echo -e "Loading the audit demo flow for NiFi"
echo -e "*******************************"
# Get NiFi Template Id
templateId=$(curl http://localhost:9095/nifi-api/flow/templates | jq '.templates[0] | .template.name="audit-demo-docker" | .id' )

#Get root process group
rootpg=$(curl http://localhost:9095/nifi-api/flow/process-groups/root | jq '.processGroupFlow.id'  | sed "s/\"//g")

# Apply template
curl -i -X POST -H 'Content-Type:application/json' -d '{"originX": 2.0,"originY": 3.0,"templateId": '$templateId'}' http://localhost:9095/nifi-api/process-groups/$rootpg/template-instance

# Get Controller Services
conserv=$(curl http://localhost:9095/nifi-api/flow/process-groups/$rootpg/controller-services | jq '.controllerServices[].component.id')

##TODO:
### curl - Create statement to enable all Controller Services

echo ""
echo "Go to the NiFi UI (http://localhost:9095/nifi) and make sure all of the Controller Services are running."
read -p "...Did you update the Controller Services?" cs

echo -e "*******************************"
echo -e "Running Bank Demo"
echo -e "*******************************"
docker-compose exec -T roach-0 ./cockroach workload init bank "postgresql://roach-0:26257/bank?sslmode=disable"
docker-compose exec -T roach-0 ./cockroach sql --insecure --host roach-0 --echo-sql < sql/bank-docker_KEY.sql
docker-compose exec -T roach-0 ./cockroach workload run bank --duration 10s "postgresql://roach-0:26257/bank?sslmode=disable"

# Output IPs
echo -e "******** Connect **************"
echo -e "Kafka Broker: localhost:9092 "
echo -e "NiFi UI: http://localhost:9095/nifi"
echo -e "Cockroach Admin UI: http://localhost:8090"
echo -e "SQL (local crdb): cockroach sql --insecure --host localhost --port 5432 --database cis"
echo -e "SQL (no local crdb): docker exec -it roach-0 /cockroach/cockroach.sh sql --insecure --host haproxy --port 5432 --database cis"
echo -e "*******************************"
echo -e ""
echo -e "Below is a quick view of the audit table.  If you don't see any records, check your NiFi flow: "
docker exec -it roach-0 /cockroach/cockroach.sh sql --insecure --host haproxy --port 5432 --database cis -e "select tbl, pk, ts, action, substring(new,0,30) from audit limit 5"
