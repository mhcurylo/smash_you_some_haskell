#!/bin/bash
set -x

PIN=$1
PIN=${PIN:-11}
echo "Deploying non-threaded haskell pinned to cpu $PIN"

docker run --cpus=1 --cpuset-cpus="$PIN" -e "PSQL_CONNECTIONS=40" --net=host mhcurylo/haskell-fixture:non-threaded
