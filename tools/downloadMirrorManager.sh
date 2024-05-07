#!/bin/bash

echo "> Downloading mirror manager tool..."
MIRRORMGRZIPFILENAME="mirrormgr-linux.tgz"
[[ -f "$MIRRORMGRZIPFILENAME" ]] && rm -f $MIRRORMGRZIPFILENAME
wget https://support.sas.com/installation/viya/4/sas-mirror-manager/lax/mirrormgr-linux.tgz
echo "< Done"