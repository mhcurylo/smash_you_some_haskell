#!/bin/bash
set -x

PIN=$1
PIN=${PIN:-11}
echo "Deploying threaded N1 haskell pinned to cpu $PIN"

docker run --cpus=1 -e "GHCRTS=-N1" -e "PSQL_CONNECTIONS=40" --cpuset-cpus="$PIN" --net=host mhcurylo/haskell-fixture:threaded
