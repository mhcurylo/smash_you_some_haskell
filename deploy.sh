#!/bin/bash

set -x

echo "Deploying $1!"


minikube kubectl -- delete deployment haskell-fixture
minikube kubectl -- delete deployment node-fixture
minikube kubectl -- apply -f $1

