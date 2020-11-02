#!/bin/bash
set -x

echo "Deploying non-threaded haskell pinned to cpu $1"

docker run --cpus=1 --cpuset-cpus="$1" --net=host mhcurylo/haskell-fixture:non-threaded
