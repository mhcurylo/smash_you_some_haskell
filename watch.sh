#!/bin/bash

set -x

watch minikube kubectl -- get pods
