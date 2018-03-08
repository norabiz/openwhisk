#!/bin/bash

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)

cd $SCRIPTDIR

echo "Creating openwhisk namespace"
kubectl create namespace openwhisk



# setup couchdb
echo "Deploying couchdb"
pushd kubernetes/couchdb
kubectl apply -f couchdb.yml
popd

sleep 15

# setup redis
echo "Deploying redis"
pushd kubernetes/redis
  kubectl apply -f redis.yml
popd

sleep 15

# setup apigateway
echo "Deploying apigateway"
pushd kubernetes/apigateway
  kubectl apply -f apigateway.yml
popd

# setup zookeeper
echo "Deploying zookeeper"
pushd kubernetes/zookeeper
  kubectl apply -f zookeeper.yml
popd


sleep 15

# setup kafka
echo "Deploying kafka"
pushd kubernetes/kafka
  kubectl apply -f kafka.yml
popd


sleep 15

# setup the controller
echo "Deploying controller"
pushd kubernetes/controller
  kubectl apply -f controller.yml
popd

sleep 15

# setup the invoker
echo "Deploying invoker"
pushd kubernetes/invoker
  kubectl apply -f invoker.yml

popd








echo "PASSED! Deployed openwhisk "
