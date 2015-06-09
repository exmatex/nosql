# nosql
Installation, testing, benchmarking, and interfacing to NoSQL databases.

There is also a [wiki](../../wiki) for this repository.

## Redis
We (ExMatEx) have been using redis since the early days of the project. At the
time, redis did not support distribution. It did support replication for fault
tolerance, but not distributing (or sharding) data across multiple nodes to
support large databases. With the arrival or redis 3.0, distribution is now
supported. This repository contains some instructions and simple test code
designed to explore redis 3.0 on LANL's Darwin cluster.

Installation of redis is relatively straightforward. In the past we have
installed it as a local module on Darwin. This repo uses redis as if it were
installed by a user into their personal directories. It's unlikely we'll be
able to install system wide on other DoE clusters, so testing user
installations is essential.

### Installation
Redis is available at [redis.io](http://redis.io/download). Download, untar,
and install the latest version of cluster redis (version 3.0+) according to the
instructions on the page. There is a
[tutorial document](http://redis.io/topics/cluster-tutorial) that describes how
to set up a redis cluster, but this repository contains a script, specific to
the Darwin cluster, that will build a redis cluster to support ExMatEx
applications.

### Requirements
Redis easily installs with no requirements for additional software. However, to
set up and run a distributed cluster, Ruby is required. Moreover, the redis gem
is also required. We've installed it globally on Darwin, but a savvy Ruby user
should be able to figure out how to install it locally using
[rvm](https://rvm.io/).

### Darwin-specific script
The `start_cluster_redis.sh` script in the `scripts` directory will build and
initialize a distributed version of redis on Darwin. The script steals material
from Christoph's original `start_redis` script in `SkelMM` and from the redis
`create-cluster` script.

Edit the script and update the `redis_tmp` and `redis_bin` variables to reflect
where to store temporary files and the install location of redis
respectively. The script is set up to use three nodes of the cluster (which you
must have previously allocated using slurm). The script creates `N` master
instances of redis on `N` nodes and `N` slaves for these masters on the
same set of `N` nodes. So, you'll have a total of `N` nodes running `2*N`
instances of redis. The script supports one command line parameter: start,
create, or stop. The following shows the sequence of commands to start the
cluster:

```bash
salloc -N 3 -p bigmem
cd scripts
./start_cluster_redis.sh start     # start N instances
./start_cluster_redis.sh create    # link them into a cluster
# connect to any port using redis-cli and play
./start_cluster_redis.sh stop      # stops all N instances
```

An initial port number is specified in the script. This port number is
incremented sequentially to address all the masters and slaves. Use any port to
connect to the database--queries will be rerouted the node containing the data
for a specified key (the cluster redis document specifies the hashing algorithm
and hos a smart client would cache the mapping between keys and nodes).

Finally, the script is not totally automated. Redis software requires that you
accept a potential cluster configuration by typing `yes` to a prompt. There may
be a flag to force this but we haven't found it.


# Copyright and License

Los Alamos National Security, LLC (LANS) owns the copyright to nosql, which
it identifies as LA-CC-2012-065 (ExMatEx: Scale-Bridging Materials Evaluation
and Test Suite, Version 1). The license is BSD-sh with a "modifications must be
indicated" clause. See LICENSE.md for the full text.
