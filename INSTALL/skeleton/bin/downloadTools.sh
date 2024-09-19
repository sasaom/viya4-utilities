#!/bin/bash

###############################################################################
# Global vars
###############################################################################
JQ_VER="1.7.1"
KUSTOMIZE_VER="v5.3.0"
KUBECTL_VER="v1.29.7"
YQ_VER="v4.42.1"
###############################################################################

myfolder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exitWithError() {
  echo "**ERROR** $1"
  exit 1
}

[[ -z $VIYA4_TOOLS ]] && VIYA4_TOOLS=$myfolder

#------------------------------------------------------------------------------
# jq
#------------------------------------------------------------------------------
#JQ_CMD="jq.exe"
JQ_CMD="jq"

if [[ ! -f "${VIYA4_TOOLS}/$JQ_CMD" ]]
then
  echo "  Downloading jq $JQ_VER"
  wget https://github.com/jqlang/jq/releases/download/jq-${JQ_VER}/jq-linux-amd64
  chmod a+x jq-linux-amd64
  mv jq-linux-amd64 ${VIYA4_TOOLS}/$JQ_CMD
fi
jqver=`$JQ_CMD --version`
echo "  jq installed version  : $jqver"
echo

#------------------------------------------------------------------------------
# Kustomize
#------------------------------------------------------------------------------
#KUSTOMIZE_CMD="kustomize.exe"
KUSTOMIZE_CMD="kustomize"

if [[ ! -f "${VIYA4_TOOLS}/$KUSTOMIZE_CMD" ]]
then
  echo "  Downloading jq $KUSTOMIZE_VER"
  wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VER}/kustomize_${KUSTOMIZE_VER}_linux_amd64.tar.gz
  tar xfz kustomize_${KUSTOMIZE_VER}_linux_amd64.tar.gz -C "${VIYA4_TOOLS}"
  chmod a+x ${VIYA4_TOOLS}/kustomize
  [[ -f kustomize_${KUSTOMIZE_VER}_linux_amd64.tar.gz ]] && rm -f kustomize_${KUSTOMIZE_VER}_linux_amd64.tar.gz
fi

kustomizever=`$KUSTOMIZE_CMD version`
echo "  kustomize  installed version: $kustomizever"
echo

#------------------------------------------------------------------------------
# kubectl
#------------------------------------------------------------------------------
KUBECTL_CMD="kubectl"

if [[ ! -f "${VIYA4_TOOLS}/$KUBECTL_CMD" ]]
then
  echo "  Downloading kubectl $KUBECTL_VER"
  wget https://dl.k8s.io/${KUBECTL_VER}/kubernetes-client-linux-amd64.tar.gz
  tar xfz kubernetes-client-linux-amd64.tar.gz
  mv kubernetes/client/bin/kubectl* ${VIYA4_TOOLS}
  rm -rf kubernetes
fi

kubectlver=`$KUBECTL_CMD version --client --output=json | $JQ_CMD -r '.clientVersion.gitVersion'`
echo "  kubectl installed version: $kubectlver"
echo

#------------------------------------------------------------------------------
# yq
#------------------------------------------------------------------------------
#JQ_CMD="yq.exe"
YQ_CMD="yq"

if [[ ! -f "${VIYA4_TOOLS}/$YQ_CMD" ]]
then
  echo "  Downloading yq $YQ_VER"
  wget https://github.com/mikefarah/yq/releases/download/${YQ_VER}/yq_linux_amd64
  chmod a+x yq_linux_amd64
  mv yq_linux_amd64 ${VIYA4_TOOLS}/$YQ_CMD
fi
yqver=`$YQ_CMD --version`
echo "  yq installed version  : $yqver"
echo
