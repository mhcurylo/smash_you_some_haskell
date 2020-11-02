#!/bin/bash
set -x

TARGET=$(minikube service $1-f --url)

echo "Stress testing $TARGET"

apib -c 200 -d 25 -w 5 -W 100 $TARGET/item/1
