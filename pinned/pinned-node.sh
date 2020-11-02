#!/bin/bash
set -x

echo "Deploying node pinned to cpu $1"

docker run --cpus=1 --cpuset-cpus="$1" --net=host mhcurylo/nodejs-fixture:js
