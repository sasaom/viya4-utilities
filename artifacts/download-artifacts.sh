#!/bin/bash

#--------------------------------------------------------------------
# Global vars
#--------------------------------------------------------------------
myfolder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MIRRORMGR_CMD="mirrormgr"

VIYA4ORDERCLIFILENAME=""
VIYA4_ORDER_CLI_CMD="viya4-orders-cli"
VIYA4_ORDER_CLI_VER="1.6.0"

# Do not set the following values
CERTIFICATEFILENAME=""
DEPLOYMENTASSETLOCATION=""
LICENSELOCATION=""


exitWithError() {
  echo "**ERROR** $1"
  exit 1
}

getMirrormgr() 
{
  echo "> Downloading mirror manager tool..."
  MIRRORMGRZIPFILENAME="$myfolder/mirrormgr-linux.tgz"

  [[ -f $MIRRORMGRZIPFILENAME ]] && rm -f $MIRRORMGRZIPFILENAME
  wget https://support.sas.com/installation/viya/4/sas-mirror-manager/lax/mirrormgr-linux.tgz
  tar xfz $MIRRORMGRZIPFILENAME -C "$myfolder"
  rm -f $MIRRORMGRZIPFILENAME
  echo "< Done"
}

getViyaCli()
{
  echo "> Downloading Viya4 Order CLI tool..."
  VIYA4ORDERCLIFILENAME="$myfolder/$VIYA4_ORDER_CLI_CMD"
  [[ -f $VIYA4ORDERCLIFILENAME ]] && rm -f $VIYA4ORDERCLIFILENAME
  wget https://github.com/sassoftware/viya4-orders-cli/releases/download/${VIYA4_ORDER_CLI_VER}/viya4-orders-cli_linux_amd64
  mv viya4-orders-cli_linux_amd64 $VIYA4ORDERCLIFILENAME
  chmod a+x $VIYA4ORDERCLIFILENAME
  echo "< Done"
}

getViyaArtifacts()
{
  echo "> Getting Viya artifacts"

  ## ENCODE KEY AND SECRET
  SECRETFILENAME="_mysecret.yaml"
  encodedText=`echo -n $KEY | base64`
  echo "clientCredentialsId: $encodedText" > "$SECRETFILENAME"
  encodedText=`echo -n $SECRET | base64`
  echo "clientCredentialsSecret: $encodedText" >> "$SECRETFILENAME"

  echo "  - Downloading Certificate"
  jsonresponse=`./$VIYA4_ORDER_CLI_CMD certificates "${ORDERNUMBER}" --config "$SECRETFILENAME" -p . -o json`
  #echo $jsonresponse
  CERTIFICATEFILENAME=`echo $jsonresponse | jq -r '.assetLocation'`
  echo "    CERTIFICATEFILENAME : $CERTIFICATEFILENAME"

  echo "  - Downloading Deployment assets"
  jsonresponse=`./$VIYA4_ORDER_CLI_CMD deploymentAssets "${ORDERNUMBER}" $CADENCENAME --config $SECRETFILENAME -p . -o json`
  DEPLOYMENTASSETLOCATION=`echo $jsonresponse | jq -r '.assetLocation'`
  echo "    DEPLOYMENTASSETLOCATION : $DEPLOYMENTASSETLOCATION"

  echo "  - Downloading Viya license"
  jsonresponse=`./$VIYA4_ORDER_CLI_CMD license "${ORDERNUMBER}" $CADENCENAME $CADENCEVERSION --config $SECRETFILENAME -p . -o json`
  LICENSELOCATION=`echo $jsonresponse | jq -r '.assetLocation'`
  echo "    LICENSELOCATION : $LICENSELOCATION"
   
  echo "< Done"
}

pushToInternalRegistry()
{
  echo "> Pull containers from SAS repository and push into the internal container registry."
  
  MIRRORPATH="$myfolder/mirror"

  echo "  ACRURL              = $ACRURL"
  echo "  ACRUSERNAME         = $ACRUSERNAME"
  echo "  ACRPASSWORD         = xxxxxxxxxxxx"
  echo "  MIRRORPATH          = $MIRRORPATH"

  ./$MIRRORMGR_CMD mirror registry --destination $ACRURL --path $MIRRORPATH --username $ACRUSERNAME --password $ACRPASSWORD --deployment-data $CERTIFICATEFILENAME --remove-after-upload --cadence $CADENCE
  
  echo "< Done"
}

##############################################################################################
#                                        MAIN
##############################################################################################

myorderjson='myorder.json'

[[ ! -f $myorderjson ]] && exitWithError "Cannot find $myorderjson"

CADENCENAME=`jq -r '.CADENCENAME' $myorderjson`
CADENCEVERSION=`jq -r '.CADENCEVERSION' $myorderjson`
CADENCE=`jq -r '.CADENCE' $myorderjson`
ORDERNUMBER=`jq -r '.ORDERNUMBER' $myorderjson`
KEY=`jq -r '.KEY' $myorderjson`
SECRET=`jq -r '.SECRET' $myorderjson` 
ACRURL=`jq -r '.ACRURL' $myorderjson` 
ACRUSERNAME=`jq -r '.ACRUSERNAME' $myorderjson`
ACRPASSWORD=`jq -r '.ACRPASSWORD' $myorderjson` 

echo "------------------------------------------------------------------------"
echo "Downloading artifacts for service order $ORDERNUMBER"
echo
echo "> CADENCENAME    = $CADENCENAME"
echo "> CADENCEVERSION = $CADENCEVERSION"
echo "> CADENCE        = $CADENCE"
echo

#-----------------------------------------------------------------------------------"
# Get SAS mirrormgr (used to download SAS Viya containers and upload them to the ACR)
#-----------------------------------------------------------------------------------"
if [[ ! -f "$myfolder/$MIRRORMGR_CMD" ]] 
then
  echo "# MIRRORMG --> $MIRRORMGR_CMD not available. Downloading it ..." 
  getMirrormgr
  echo
else
  echo "# MIRRORMG --> $MIRRORMGR_CMD is available." 
  echo
fi

#-----------------------------------------------------------------------------------"
# Get SAS Viya CLI (used to download objects from my.sas.com)
#-----------------------------------------------------------------------------------"
if [[ ! -f "$myfolder/$VIYA4_ORDER_CLI_CMD" ]] 
then
  echo "# VIYA_CLI --> $VIYA4_ORDER_CLI_CMD not available. Downloading it ..." 
  getViyaCli
  echo
else
  echo "# VIYA_CLI --> $VIYA4_ORDER_CLI_CMD is available." 
  echo
fi

#-----------------------------------------------------------------------------------"
# Download artifacts (SAS license + SAS deployment manifests)
#-----------------------------------------------------------------------------------"
echo "# VIYA ARTIFACTS" 
getViyaArtifacts
echo

#-----------------------------------------------------------------------------------"
# Pull containers from SAS and push into the internal container registry (ACR)
#-----------------------------------------------------------------------------------"
echo "# VIYA4 CONTAINERS" 
pushToInternalRegistry
echo
echo "------------------------------------------------------------------------"#


