#!/bin/bash

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../../"

cd $ROOTDIR

echo "Creating openwhisk namespace"
kubectl create namespace openwhisk



# setup couchdb
echo "Deploying couchdb"
pushd kubernetes/couchdb
kubectl apply -f couchdb.yml
popd



# setup redis
echo "Deploying redis"
pushd kubernetes/redis
  kubectl apply -f redis.yml

  deploymentHealthCheck "redis"
popd

