
## Run
docker-compose up --build

## Connect to Cockroach and run the audit script

/cockroach/cockroach sql --certs-dir=/certs --host roach-0

## UIs

Confluent Control Center: http://localhost:9021/clusters
Cockroach UI: http://localhost:8090
