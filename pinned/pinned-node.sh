#!/bin/bash
set -x

PIN=$1
PIN=${PIN:-11}
echo "Deploying node pinned to cpu $PIN"

docker run --cpuset-cpus="$PIN" -e "PSQL_CONNECTIONS=80" --net=host mhcurylo/nodejs-fixture:js
