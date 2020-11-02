#!/bin/bash
set -x

echo "Deploying threaded N1 haskell pinned to cpu $1"

docker run --cpus=1 -e "GHCRTS=-N1" --cpuset-cpus="$1" --net=host mhcurylo/haskell-fixture:threaded
