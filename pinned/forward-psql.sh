#!/bin/bash
set -x


POD=$(minikube kubectl -- get pods | grep psql | awk '{ print $1}')

echo "Forwarding $POD to 5432"

kubectl port-forward $POD 5432:5432
