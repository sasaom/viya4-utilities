#!/bin/bash

#----------------------------------------------------------------------------------
# Set the correct values:
#----------------------------------------------------------------------------------
azurelocation="northeurope"
viya4_ingress_namespace="ingress-nginx"
internal_ip_whitelist_file_path="internal-ip-whitelist.txt"

exitWithError() {
  echo "*ERROR* $1"
  exit 1
}

#----------------------------------------------------------------------------------
# Create the skeleton for the patch yaml file
#----------------------------------------------------------------------------------
prev_ingress_patch_file_path="ingress-ip-whitelist-patch.PREV.yaml"
ingress_patch_file_path="ingress-ip-whitelist-patch.yaml"

[[ -f $ingress_patch_file_path ]] && mv $ingress_patch_file_path $prev_ingress_patch_file_path

echo "spec:" > $ingress_patch_file_path
echo "  loadBalancerSourceRanges:" >> $ingress_patch_file_path

#----------------------------------------------------------------------------------
# Add the internal ip ranges to the patch file
#----------------------------------------------------------------------------------
if [[ -f $internal_ip_whitelist_file_path ]]
then
  echo "Adding the internal ip ranges to the patch file (from $internal_ip_whitelist_file_path)"
  while read -r anip
  do 
    [[ "$anip" =~ ^[0-9]+\..+ ]] && echo "  - $anip" >> $ingress_patch_file_path
  done < $internal_ip_whitelist_file_path
else
  echo "The file with the internal ip whitelist was not found ($internal_ip_whitelist_file_path)"
fi

#----------------------------------------------------------------------------------
# Get public IP addresses used by Azure services on specified location
#----------------------------------------------------------------------------------
echo "Getting IP addresses used by Azure Services"

azure_service_tags_json=`az network list-service-tags --location northeurope` 
ips=`echo $azure_service_tags_json | jq -r '.values[] | select(.name == "AzureActiveDirectory") | .properties.addressPrefixes[]'`
for anip in $ips
do 
  [[ "$anip" =~ ^[0-9]+\..+ ]] && echo "  - $anip    # Azure Entra ID" >> $ingress_patch_file_path
done

#kubectl patch service ingress-nginx-controller -n $viya4_ingress_namespace --patch-file $ingress_patch_file_path
