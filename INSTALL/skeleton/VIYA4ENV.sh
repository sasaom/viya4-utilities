#!/bin/bash

export VIYA4_ROOT=~
export VIYA4_ARTIFACTS=${VIYA4_ROOT}/artifacts
export VIYA4_DEPLOY=${VIYA4_ROOT}/deploy
export VIYA4_INFRA=${VIYA4_DEPLOY}/infra
export VIYA4_MONITOR=${VIYA4_ROOT}/monitor-logging
export VIYA4_RESOURCES=${VIYA4_ROOT}/resources
export VIYA4_TOOLS=${VIYA4_ROOT}/bin
export VIYA4_UTILITIES=${VIYA4_ROOT}/utilities
export VIYA4_ARCHIVE=${VIYA4_DEPLOY}/archive
export VIYA_NAMESPACE=$VIYAENV
export PATH=${VIYA4_TOOLS}:$PATH
export USER_DIR=${VIYA4_ROOT}/monitoring-logging

echo "------------------------------------------------------------------------"
echo "Viya4 environment settings (from $VIY4_ROOT/VIYA4ENV.sh)"
echo
echo "VIYA4_ROOT              : $VIYA4_ROOT"
echo "VIYA_NAMESPACE (VIYAENV): $VIYA_NAMESPACE"
echo "kustomize version       : $(kustomize version)"
echo "kubectl version         : $(kubectl version --output=json | jq -r '.clientVersion.gitVersion')"
echo "------------------------------------------------------------------------"

echo "cd ${VIYA4_ROOT}"
cd ${VIYA4_ROOT}