#!/bin/bash

echo "Reseting minikube for Smash you Some Haskell!"

minikube delete

minikube start --cpus 6
minikube kubectl -- apply -f deployments/postgres.yaml
minikube kubectl -- apply -f deployments/node-1-nolr.yaml
minikube kubectl -- apply -f deployments/haskell-N.yaml

