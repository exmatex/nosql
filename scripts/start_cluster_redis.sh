#!/bin/bash

# Script originally written by Christoph Junghans as part of SkelMM
# Modified by Allen McPherson to start cluster redis (version 3+).


# Where are redis binaries located?
redis_bin=$HOME/redis-3.0.1/src

# Where redis will store its backing files.
# Remember, on Darwin, the filesystem is shared by all nodes so we
# can configure here (presumably on the login node).
redis_tmp=$HOME/redis-save
if [[ -d $redis_tmp ]]
then
    ls $redis_tmp/*.rdb    # delete old backing files
else
    mkdir $redsi_tmp           # create directory if needed
fi
sleep 2


# Slurm sets the SLURM_NODELIST environment variable.
# Slurm's scontrol command will unpack the node list in one-per-line.
for i in $(scontrol show hostname $SLURM_NODELIST)
do
    echo $i
    # nohup ssh -n $i "cd $dir/$i; $(type -p redis-server) ./redis.conf " &
done


for i in $(cat "$1"); do
    mkdir "$redis_dir/$i"
    cd "$redis_dir/$i"
    if [[ -z $master ]]; then
        #nohup redis-server &
        #nohup redis-cli flushdb &
        master=$i
    else
        # nohup ssh -n $i "cd $dir/$i; $(type -p redis-server) ./redis.conf " &
        echo "started slave on $i"
    fi
    sleep 2
    cd -
done

