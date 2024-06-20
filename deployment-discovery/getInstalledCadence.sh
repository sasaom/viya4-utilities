#!/bin/bash

echo "SAS Viya4 installed candende (VIYA_NAMESPACE: $VIYA_NAMESPACE)"
kubectl -n $VIYA_NAMESPACE get cm -o yaml | grep ' SAS_CADENCE'