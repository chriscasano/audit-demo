############################
# IN DEVELOPMENT ###########
############################


# Create a cluster with 4 nodes and local SSD. The last node is used as a
# load generator for some tests. Note that the cluster name must always begin
# with your username.
export CLUSTER="${USER:0:6}-test"
roachprod create ${CLUSTER} -n 4 --local-ssd

# Add gcloud SSH key. Optional for most commands, but some require it.
ssh-add ~/.ssh/google_compute_engine

# Stage binaries.
roachprod stage ${CLUSTER} workload
roachprod stage ${CLUSTER} release v19.1.5


# Start a cluster.
roachprod start ${CLUSTER}

# Check the admin UI.
roachprod admin --open ${CLUSTER}:1

# Run a workload.
#roachprod run ${CLUSTER}:4 -- ./workload init kv
#roachprod run ${CLUSTER}:4 -- ./workload run kv --read-percent=0 --splits=1000 --concurrency=384 --duration=5m

# Open a SQL connection to the first node.
roachprod sql ${CLUSTER}:1
