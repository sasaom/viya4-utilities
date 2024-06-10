#!/bin/bash

myfolder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exitWithError() {
  echo "**ERROR** $1"
  exit 1
}

[[ -z $VIYA4_ARTIFACTS ]] && exitWithError "VIYA4_ARTIFACTS env variable not set. Source the Viya4 settings."

echo "> Downloading mirror manager tool..."
MIRRORMGRZIPFILENAME="mirrormgr-linux.tgz"
[[ -f "$MIRRORMGRZIPFILENAME" ]] && rm -f $MIRRORMGRZIPFILENAME
wget https://support.sas.com/installation/viya/4/sas-mirror-manager/lax/$MIRRORMGRZIPFILENAME

tar xvfz $MIRRORMGRZIPFILENAME -C $VIYA4_ARTIFACTS

echo "< Done"