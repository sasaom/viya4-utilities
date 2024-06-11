#!/bin/bash

kubectl get nodes -o json | jq ".items[]|{name:.metadata.name, taints:.spec.taints, labels:.metadata.labels}"