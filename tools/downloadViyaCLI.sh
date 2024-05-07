#!/bin/bash

echo "> Downloading Viya4 Order CLI tool..."
VIYA4ORDERCLIFILENAME="viya4-orders-cli_linux_amd64"
[[ -f "$VIYA4ORDERCLIFILENAME" ]] && rm -f $VIYA4ORDERCLIFILENAME
wget https://github.com/sassoftware/viya4-orders-cli/releases/download/1.6.0/viya4-orders-cli_linux_amd64
chmod a+x $VIYA4ORDERCLIFILENAME
echo "< Done"