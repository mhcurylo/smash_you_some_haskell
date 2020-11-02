#!/bin/bash
set -x

echo "Load testing http://localhost:$1"

apib -c 200 -d 25 -w 5 -W 100 http://localhost:$1/item
