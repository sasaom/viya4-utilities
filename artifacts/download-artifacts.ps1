Function CreateTmpFolder($tmpFolder) 
{
  echo "> Creating $tmpFolder directory ..."
  If(Test-Path $tmpFolder)
  {
    Remove-Item $tmpFolder -Force -Recurse
  }
  New-Item -ItemType Directory -Force -Path $tmpFolder | Out-Null
  echo "< Done"
}

Function GetMirrormgr($myfolder) 
{
  echo "> Downloading mirror manager tool..."
  $MIRRORMGRZIPFILENAME="$myfolder\mirrormgr.zip"

  if (Test-Path -Path "$MIRRORMGRZIPFILENAME" -PathType Leaf) {
    Remove-Item $MIRRORMGRZIPFILENAME
  }
  Invoke-WebRequest -Uri https://support.sas.com/installation/viya/4/sas-mirror-manager/wx6/mirrormgr-windows.zip -OutFile $MIRRORMGRZIPFILENAME
  expand-archive -LiteralPath $MIRRORMGRZIPFILENAME -DestinationPath $myfolder
  echo "< Done"
}

Function GetViyaCli($myfolder)
{
  echo "> Downloading Viya4 Order CLI tool..."
  $VIYA4ORDERCLIFILENAME="$myfolder\viya4-orders-cli.exe"

  if (Test-Path -Path "$VIYA4ORDERCLIFILENAME" -PathType Leaf) {
    Remove-Item $VIYA4ORDERCLIFILENAME
  }
  Invoke-WebRequest -Uri https://github.com/sassoftware/viya4-orders-cli/releases/download/1.5.0/viya4-orders-cli_windows_amd64.exe -OutFile $VIYA4ORDERCLIFILENAME
  echo "< Done"
}

Function getViyaArtifacts
{
  Param(
    [Parameter(Mandatory=$true,Position=0)] [String] $VIYA4INIFILE,
    [Parameter(Mandatory=$true,Position=1)] [String] $VIYAARTIFACTSJSON,
    [Parameter(Mandatory=$true,Position=2)] [String] $myfolder
  ) 

  Write-Host "> Getting Viya artifacts"

  $myorderjson = Get-Content $VIY4JSON | Out-String | ConvertFrom-Json

  $ORDERNUMBER = $myorderjson.ORDERNUMBER
  $KEY = $myorderjson.KEY
  $SECRET = $myorderjson.SECRET
  $AZURESTORAGEBLOB = $myorderjson.AZURESTORAGEBLOB
 
  Write-Host "  ORDERNUMBER     : $ORDERNUMBER"
  Write-Host "  KEY             : $KEY"
  Write-Host "  SECRET          : $SECRET"
  Write-Host "  AZURESTORAGEBLOB: $AZURESTORAGEBLOB"

  cd $myfolder

  ## ENCODE KEY AND SECRET
  $SECRETFILENAME="_mysecret.yaml"
  echo "  - Creating the secret file ($SECRETFILENAME)"
  $EncodedText =[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($KEY))
  echo "clientCredentialsId: $EncodedText" > "$SECRETFILENAME"
  $EncodedText =[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($SECRET))
  echo "clientCredentialsSecret: $EncodedText" >> "$SECRETFILENAME"

  Write-Host "  - Downloading Certificate"

  $jsonresponse = .\viya4-orders-cli.exe certificates "${ORDERNUMBER}" --config "$SECRETFILENAME" -p . -o json | ConvertFrom-Json 
  $CERTIFICATEFILENAME = $jsonresponse.assetLocation
  Write-Host "    CERTIFICATEFILENAME : $CERTIFICATEFILENAME"

  #Write-Host "  - Uploading Certificate to Azure Blob Storage"
  #.\azcopy.exe copy "$tmpFolder\$CERTIFICATEFILENAME" $AZURESTORAGEBLOB

  Write-Host "  - Downloading Deployment assets"
  $jsonresponse = .\viya4-orders-cli.exe deploymentAssets "${ORDERNUMBER}" $CADENCENAME --config $SECRETFILENAME -p . -o json | ConvertFrom-Json 
  $DEPLOYMENTASSETLOCATION = $jsonresponse.assetLocation
  Write-Host "    DEPLOYMENTASSETLOCATION : $DEPLOYMENTASSETLOCATION"

  #Write-Host "  - Uploading Deployment Assets to Azure Blob Storage"
  #.\azcopy.exe copy "$DEPLOYMENTASSETLOCATION" $AZURESTORAGEBLOB
  
  Write-Host "  - Downloading Viya license"
  $jsonresponse = .\viya4-orders-cli.exe license "${ORDERNUMBER}" $CADENCENAME $CADENCEVERSION --config $SECRETFILENAME -p . -o json | ConvertFrom-Json 
  $LICENSELOCATION = $jsonresponse.assetLocation
  Write-Host "    LICENSELOCATION : $LICENSELOCATION"

  #Write-Host "  - Uploading License to Azure Blob Storage"
  #.\azcopy.exe copy "$LICENSELOCATION" $AZURESTORAGEBLOB

  $DEPLOYMENTINFOFILENAME = "set-deployment-info.sh"
  Write-Host "  - Creating $DEPLOYMENTINFOFILENAME"
  
  echo "#!/bin/bash" > $DEPLOYMENTINFOFILENAME
  echo "export CADENCENAME=$CADENCENAME" >> $DEPLOYMENTINFOFILENAME
  echo "export CADENCEVERSION=$CADENCEVERSION" >> $DEPLOYMENTINFOFILENAME
  echo "export CERTIFICATEFILENAME=$CERTIFICATEFILENAME" >> $DEPLOYMENTINFOFILENAME
  echo "export DEPLOYMENTASSET=$DEPLOYMENTASSETLOCATION" >> $DEPLOYMENTINFOFILENAME
  echo "export LICENSEFILENAME=$LICENSELOCATION" >> $DEPLOYMENTINFOFILENAME

  #echo "  - Uploading set-deployment-info.sh Storage"
  #.\azcopy.exe copy "$DEPLOYMENTINFOFILENAME" $AZURESTORAGEBLOB

  Write-Host "  - Creating $VIYAARTIFACTSJSON"
  echo "{}" > $VIYAARTIFACTSJSON
  $artifactsjsonobj = Get-Content $VIYAARTIFACTSJSON | Out-String | ConvertFrom-Json
  $artifactsjsonobj | add-member -name "CERTIFICATEFILENAME" -value "$CERTIFICATEFILENAME" -MemberType NoteProperty
  $artifactsjsonobj | add-member -name "DEPLOYMENTASSETFILENAME" -value "$DEPLOYMENTASSETLOCATION" -MemberType NoteProperty
  $artifactsjsonobj | add-member -name "LICENSEFILENAME" -value "$LICENSELOCATION" -MemberType NoteProperty

  ConvertTo-Json $artifactsjsonobj -depth 100 | Out-File "$VIYAARTIFACTSJSON"

  cd ..
  
  Write-Host "< Done"
}

Function UpdateLocalMirror
{
  Param(
    [Parameter(Mandatory=$true,Position=0)] [String] $myfolder,
    [Parameter(Mandatory=$true,Position=1)] [String] $ARTIFACTSJSON,
    [Parameter(Mandatory=$true,Position=2)] [String] $MIRRORPATH,
    [Parameter(Mandatory=$true,Position=3)] [String] $CADENCE
  ) 
  echo "> Update local mirror"

  

  echo "  MIRRORPATH         = $MIRRORPATH"
  echo "  CADENCE            = $CADENCE"

  cd $myfolder

  if (-not(Test-Path -Path $MIRRORPATH)) {
    New-Item -ItemType Directory -Force -Path $MIRRORPATH | Out-Null
  }

  If(-not( Test-Path -Path $ARTIFACTSJSON -PathType Leaf))
  {
    write-host "** ERROR ** Cannot find $ARTIFACTSJSON"
    return
  }

  $artifactsjsonobj = Get-Content $ARTIFACTSJSON | Out-String | ConvertFrom-Json
  $CERTIFICATEFILENAME = $artifactsjsonobj.CERTIFICATEFILENAME

  echo "  CERTIFICATEFILENAME= $CERTIFICATEFILENAME"

  .\mirrormgr.exe mirror --deployment-data "$CERTIFICATEFILENAME" --path $MIRRORPATH --cadence $CADENCE

  #echo "  - Uploading mirror metadata assets to Azure Blob Storage"
  #.\azcopy.exe copy $MIRRORPATH $AZURESTORAGEBLOB --recursive

  cd ..
  echo "< Done"
}

Function UpdateLocalRegistry
{
  Param(
    [Parameter(Mandatory=$true,Position=0)] [String] $VIY4JSON,
    [Parameter(Mandatory=$true,Position=1)] [String] $ARTIFACTSJSON,
    [Parameter(Mandatory=$true,Position=2)] [String] $myfolder,
    [Parameter(Mandatory=$true,Position=4)] [String] $MIRRORPATH,
    [Parameter(Mandatory=$true,Position=5)] [String] $CADENCE
  ) 
  echo "> Update local Container Registry"
  
  echo "  ACRURL              = $ACRURL"
  echo "  ACRUSERNAME         = $ACRUSERNAME"
  echo "  ACRPASSWORD         = xxxxxxxxxxxx"
  echo "  MIRRORPATH          = $MIRRORPATH"
  echo "  CADENCE             = $CADENCE"

  If(-not( Test-Path -Path $myfolder\$ARTIFACTSJSON -PathType Leaf))
  {
    write-host "** ERROR ** Cannot find $myfolder\$ARTIFACTSJSON"
    return
  }

  $myorderjson = Get-Content $VIY4JSON | Out-String | ConvertFrom-Json

  $ACRURL = $myorderjson.ACRURL
  $ACRUSERNAME = $myorderjson.ACRUSERNAME
  $ACRPASSWORD = $myorderjson.ACRPASSWORD
  
  cd $myfolder

  $artifactsjsonobj = Get-Content $ARTIFACTSJSON | Out-String | ConvertFrom-Json
  $CERTIFICATEFILENAME = $artifactsjsonobj.CERTIFICATEFILENAME

  echo "  CERTIFICATEFILENAME = $CERTIFICATEFILENAME"

  .\mirrormgr mirror registry --destination $ACRURL --path $MIRRORPATH --username $ACRUSERNAME --password $ACRPASSWORD --deployment-data .\$CERTIFICATEFILENAME --remove-after-upload --cadence $CADENCE

  cd ..
  echo "< Done"
}

Function PushSasOrchestration
{
  Param(
    [Parameter(Mandatory=$true,Position=0)] [String] $VIY4JSON,
    [Parameter(Mandatory=$true,Position=1)] [String] $myfolder,
    [Parameter(Mandatory=$true,Position=2)] [String] $CERTIFICATEFILENAME,
    [Parameter(Mandatory=$true,Position=3)] [String] $MIRRORPATH,
    [Parameter(Mandatory=$true,Position=4)] [String] $CADENCE
  ) 
  echo "> Update local Container Registry"
  
  $myorderjson = Get-Content $VIY4JSON | Out-String | ConvertFrom-Json

  $ACRURL = $myorderjson.ACRURL
  $ACRUSERNAME = $myorderjson.ACRUSERNAME
  $ACRPASSWORD = $myorderjson.ACRPASSWORD
 
  docker pull cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration
  docker tag cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration $ACRURL/sas-orchestration
  docker push $ACRURL/sas-orchestration
  
  echo "< Done"
}

Function RemoveTmpFolder($myfolder) 
{
  echo "> Removing $myfolder directory ..."
  If(Test-Path $myfolder)
  {
    Remove-Item $myfolder -Force -Recurse
  }
  echo "< Done"
}

##############################################################################################
#                                        MAIN
##############################################################################################

write-host "########################################################################"
write-host "IT IS ASSUMED YOU LOGGED IN TO AZURE (az login)"
write-host "########################################################################"
write-host ""
#az login -u $MYUSERNAME

$VIY4JSON='myorder.json'

$myorderjson = Get-Content $VIY4JSON | Out-String | ConvertFrom-Json

$CADENCENAME = $myorderjson.CADENCENAME
$CADENCEVERSION = $myorderjson.CADENCEVERSION
$CADENCE = $myorderjson.CADENCE

write-host "> CADENCENAME    = $CADENCENAME"
write-host "> CADENCEVERSION = $CADENCEVERSION"
write-host "> CADENCE        = $CADENCE"

$localTmpFolder = ".\tmp"

$VIYAARTIFACTSJSON="ViyaArtifacts.json"

write-host ""
write-host "------------------------------------------------------------------------"
CreateTmpFolder $localTmpFolder

write-host "------------------------------------------------------------------------"
GetMirrormgr $localTmpFolder

write-host "------------------------------------------------------------------------"
GetViyaCli $localTmpFolder

write-host "------------------------------------------------------------------------"
getViyaArtifacts $VIY4JSON $VIYAARTIFACTSJSON $localTmpFolder

write-host "------------------------------------------------------------------------"
UpdateLocalMirror $localTmpFolder $VIYAARTIFACTSJSON ".\mirror" $CADENCE

write-host "------------------------------------------------------------------------"
# The file $localTmpFolder/ViyaArtifacts.json is produced by the getViyaArtifacts function
UpdateLocalRegistry $VIY4JSON $VIYAARTIFACTSJSON $localTmpFolder ".\mirror" $CADENCE

write-host "------------------------------------------------------------------------"
#PushSasOrchestration $VIY4JSON $localTmpFolder $CERTIFICATEFILENAME ".\mirror" $CADENCE

write-host "------------------------------------------------------------------------"
#RemoveTmpFolder $localTmpFolder

write-host "------------------------------------------------------------------------"