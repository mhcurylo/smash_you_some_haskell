#!/bin/bash
set -x

echo "Stress testing http://localhost:$1"

apib -c 200 -d 25 -w 5 -W 25 http://localhost:$1/item
