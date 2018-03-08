#!/bin/bash

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../../"

cd $ROOTDIR

echo "Creating openwhisk namespace"
kkubectl create namespace openwhisk


couchdbHealthCheck () {
  # wait for the pod to be created before getting the job name
  sleep 5
  POD_NAME=$(kubectl -n openwhisk get pods -o wide --show-all | grep "couchdb" | awk '{print $1}')

  PASSED=false
  TIMEOUT=0
  until [ $TIMEOUT -eq 30 ]; do
    if [ -n "$(kubectl -n openwhisk logs $POD_NAME | grep "successfully setup and configured CouchDB v2.0")" ]; then
      PASSED=true
      break
    fi

    let TIMEOUT=TIMEOUT+1
    sleep 10
  done

  if [ "$PASSED" = false ]; then
    echo "Failed to finish deploying CouchDB"

    kubectl -n openwhisk logs $POD_NAME
    exit 1
  fi

  echo "CouchDB is up and running"
}

deploymentHealthCheck () {
  if [ -z "$1" ]; then
    echo "Error, component health check called without a component parameter"
    exit 1
  fi

  PASSED=false
  TIMEOUT=0
  until $PASSED || [ $TIMEOUT -eq 30 ]; do
    KUBE_DEPLOY_STATUS=$(kubectl -n openwhisk get pods -o wide | grep "$1" | awk '{print $3}')
    if [ "$KUBE_DEPLOY_STATUS" == "Running" ]; then
      PASSED=true
      break
    fi

    kubectl get pods --all-namespaces -o wide --show-all

    let TIMEOUT=TIMEOUT+1
    sleep 10
  done

  if [ "$PASSED" = false ]; then
    echo "Failed to finish deploying $1"

    kubectl -n openwhisk logs $(kubectl -n openwhisk get pods -o wide | grep "$1" | awk '{print $1}')
    exit 1
  fi

  echo "$1 is up and running"
}

statefulsetHealthCheck () {
  if [ -z "$1" ]; then
    echo "Error, StatefulSet health check called without a parameter"
    exit 1
  fi

  PASSED=false
  TIMEOUT=0
  until $PASSED || [ $TIMEOUT -eq 30 ]; do
    KUBE_DEPLOY_STATUS=$(kubectl -n openwhisk get pods -o wide | grep "$1"-0 | awk '{print $3}')
    if [ "$KUBE_DEPLOY_STATUS" == "Running" ]; then
      PASSED=true
      break
    fi

    kubectl get pods --all-namespaces -o wide --show-all

    let TIMEOUT=TIMEOUT+1
    sleep 10
  done

  if [ "$PASSED" = false ]; then
    echo "Failed to finish deploying $1"

    kubectl -n openwhisk logs $(kubectl -n openwhisk get pods -o wide | grep "$1"-0 | awk '{print $1}')
    exit 1
  fi

  echo "$1-0 is up and running"

}

# setup couchdb
echo "Deploying couchdb"
pushd kubernetes/couchdb
  kubectl apply -f couchdb.yml

  couchdbHealthCheck
popd

# setup redis
echo "Deploying redis"
pushd kubernetes/redis
  kubectl apply -f redis.yml

  deploymentHealthCheck "redis"
popd

# setup apigateway
echo "Deploying apigateway"
pushd kubernetes/apigateway
  kubectl apply -f apigateway.yml

  deploymentHealthCheck "apigateway"
popd

# setup zookeeper
echo "Deploying zookeeper"
pushd kubernetes/zookeeper
  kubectl apply -f zookeeper.yml

  deploymentHealthCheck "zookeeper"
popd

# setup kafka
echo "Deploying kafka"
pushd kubernetes/kafka
  kubectl apply -f kafka.yml

  deploymentHealthCheck "kafka"
popd

# setup the controller
echo "Deploying controller"
pushd kubernetes/controller
  kubectl apply -f controller.yml

  statefulsetHealthCheck "controller"
popd

# setup the invoker
echo "Deploying invoker"
pushd kubernetes/invoker
  kubectl apply -f invoker.yml

  # wait until the invoker is ready
  deploymentHealthCheck "invoker"
popd

# setup nginx
echo "Deploying nginx"
pushd kubernetes/nginx
  mkdir -p certs
  ./certs.sh localhost
  openssl req -x509 -newkey rsa:2048 -keyout certs/key.pem -out certs/cert.pem -nodes -subj "/CN=localhost" -days 365
  kubectl -n openwhisk create configmap nginx --from-file=nginx.conf
  kubectl -n openwhisk create secret tls nginx --cert=certs/cert.pem --key=certs/key.pem

  # have seen this fail where nginx pod is applied but never created. Hard to know
  # why that is happening without having access to Kube component logs.
  sleep 5

  kubectl apply -f nginx.yml

  # wait until nginx is ready
  deploymentHealthCheck "nginx"
popd






echo "PASSED! Deployed openwhisk "
