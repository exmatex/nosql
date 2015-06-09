#!/bin/bash

# Script originally written by Christoph Junghans as part of SkelMM
# Modified by Allen McPherson to start cluster redis (version 3+).
# Also swiped a bunch of stuff from the redis create-cluster script.

START_PORT=30000
TIMEOUT=2000

# Where are redis binaries located?
redis_bin=$HOME/redis-3.0.1/src

# Where redis will store its backing files.
# Remember, on Darwin, the filesystem is shared by all nodes so we
# can configure here (presumably on the login node).
redis_tmp=$HOME/redis-save
if [[ -d $redis_tmp ]]
then
    echo "cleaning up leftovers from last time"
    rm $redis_tmp/*.conf $redis_tmp/*.aof $redis_tmp/*.rdb $redis_tmp/*.log
else
    echo "mkdir $redsi_tmp"           # create directory if needed
fi
sleep 1


# Slurm sets the SLURM_NODELIST environment variable.
# Slurm's scontrol command will unpack the node list in one-per-line.
PORT=$START_PORT
for i in $(scontrol show hostname $SLURM_NODELIST)
do
    echo "Starting master: $PORT on $i"
    nohup ssh -n $i "cd $redis_tmp; $redis_bin/redis-server --port $PORT --cluster-enabled yes --cluster-config-file nodes-${PORT}-${i}.conf --cluster-node-timeout $TIMEOUT --appendonly yes --appendfilename appendonly-${PORT}-${i}.aof --dbfilename dump-${PORT}-${i}.rdb --logfile ${PORT}-${i}.log --daemonize yes"
    PORT=$(($PORT+1))
    echo "Starting backup: $PORT on $i"
    nohup ssh -n $i "cd $redis_tmp; $redis_bin/redis-server --port $PORT --cluster-enabled yes --cluster-config-file nodes-${PORT}-${i}.conf --cluster-node-timeout $TIMEOUT --appendonly yes --appendfilename appendonly-${PORT}-${i}.aof --dbfilename dump-${PORT}-${i}.rdb --logfile ${PORT}-${i}.log --daemonize yes"
    PORT=$(($PORT+1))
done


# Connect the cluster nodes.
# redis-trib doesn't support hostnames, only IP addresses (hence dig)
# http://unix.stackexchange.com/questions/20784/how-can-i-resolve-a-hostname-to-an-ip-address-in-a-bash-script
PORT=$START_PORT
HOSTS=""
for i in $(scontrol show hostname $SLURM_NODELIST)
do
    HOSTS="$HOSTS `dig +short $i`:$PORT"
    PORT=$((PORT+1))
    HOSTS="$HOSTS `dig +short $i`:$PORT"
    PORT=$((PORT+1))
done

sleep 5
$redis_bin/redis-trib.rb create --replicas 1 $HOSTS


