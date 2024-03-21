#----------------------------------------------------------------------------------
# Set the correct values:
#----------------------------------------------------------------------------------
$azurelocation = "northeurope"
$viya4_ingress_namespace = "ingress-nginx"
$internal_ip_whitelist_file_path = "internal-ip-whitelist.txt"

#----------------------------------------------------------------------------------
# Create the skeleton for the patch yaml file
#----------------------------------------------------------------------------------
$prev_ingress_patch_file_path="ingress-ip-whitelist-patch.PREV.yaml"
$ingress_patch_file_path="ingress-ip-whitelist-patch.yaml"

if (Test-Path -Path $ingress_patch_file_path) {
  Move-Item -Path $ingress_patch_file_path -Destination $prev_ingress_patch_file_path -Force
}

"spec:" > $ingress_patch_file_path
"  loadBalancerSourceRanges:" >> $ingress_patch_file_path

#----------------------------------------------------------------------------------
# Add the internal ip ranges to the patch file
#----------------------------------------------------------------------------------
if (Test-Path -Path $internal_ip_whitelist_file_path) {
  Write-Host "Adding the internal ip ranges to the patch file (from $internal_ip_whitelist_file_path)"
  foreach($line in Get-Content $internal_ip_whitelist_file_path) {
    if($line -match '\d+\.+'){
	  "  - " + $line >> $ingress_patch_file_path
    }
  }
} else {
  Write-Host "The file with the internal ip whitelist was not found ($internal_ip_whitelist_file_path)"
}

#----------------------------------------------------------------------------------
# Get public IP addresses used by Azure services on specified location
#----------------------------------------------------------------------------------
Write-Host "Getting IP addresses used by Azure Services"
$azure_service_tags_json = az network list-service-tags --location $azurelocation | ConvertFrom-Json 

#----------------------------------------------------------------------------------
# Add Azure Entra ID ip ranges to the patch file
#----------------------------------------------------------------------------------
Write-Host "Adding IP addresses used by Entra ID to the internal whitelist"
$entra_id_section = $azure_service_tags_json | Select-Object -ExpandProperty values | Where-Object {$_.name -eq "AzureActiveDirectory" }
foreach($line in $entra_id_section.properties.addressPrefixes) {
  if($line -match '\d+\.+') {
    "  - " + $line + " # Azure Entra ID ">> $ingress_patch_file_path
  }
}

#----------------------------------------------------------------------------------
# Patch INGRESS with the new ip whitelist
#----------------------------------------------------------------------------------
kubectl patch service ingress-nginx-controller -n $viya4_ingress_namespace --patch-file $ingress_patch_file_path