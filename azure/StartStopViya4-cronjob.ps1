Param
(
  [Parameter (Mandatory= $true)]
  [String] $param = "start"
)
    
 $ValidData = $true        # the tests will set this to false if we find bad data.

if($param.ToLower() -eq 'stop')
{
	Write-Host "Action will be set to: $param"
}
elseif ($param.ToLower() -eq 'start')
{
	Write-Host "Action will be set to: $param"
}
else 
{
     throw "Please rerun the script and provide a valid value for action. You provided: $param. Please us either start or stop as a valid value for action"           
} 

# Login to Azure using the managed identity
function login
{
	param(
		[Parameter(Mandatory=$false)] [String]$id
	)
	try
	{
		Update-AzConfig -DisplayBreakingChangeWarning $false -ErrorAction Stop | Out-Null
		Connect-AzAccount -Identity -AccountId $id -ErrorAction Stop | Out-Null
	}
	catch
	{
		Write-Output "[ERROR]: Something went wrong while trying to connect using the managed identity."
		Write-Output $_
		exit
	}
}
# Installing kubectl CLI
function getKubectl{
	try
	{ 
		$version=$k8s_version.Substring(0,6) + "0"
    	Install-AzAksKubectl -Version $version -ErrorAction Stop
	}
	catch
	{
		Write-Output "[ERROR]: Something went wrong while trying to Install the kubectl CLI."
		Write-Output $_
		exit
	}
}
# Retrieve kube configuration file from cluster
function getKubeConfig
{
	try
	{
		Import-AzAksCredential -Admin -ResourceGroupName $group  -Name $cluster_name -Force -ErrorAction Stop
	}
	catch
	{
		Write-Output "[ERROR]: Something went wrong while trying to get the kubeconfig from the cluster."
		Write-Output $_
		exit
	}
}
# Retrieve IP
function getRunBookIP{
	try
	{
		$ip = (Invoke-WebRequest -UseBasicParsing -ErrorAction Stop -uri "http://ifconfig.me/ip").Content 
	}
	catch
	{
		Write-Output "[ERROR]: Something went wrong while trying to get the IP."
		Write-Output $_
		exit
	}
	return $ip
}
# Check if k8s api is locked down
function addIpToApi
{
	param(
		[Parameter(Mandatory=$false)] [String]$ip
	)
	try
	{
		$iprange = (Get-AzAksCluster -Name $cluster_name -ResourceGroupName $group -ErrorAction Stop).ApiServerAccessProfile.AuthorizedIPRanges
		 if ($iprange.count -gt 0){
		 	 $iprange.add($ip+"/32")
		     echo "[INFO]: Server is locked down. Adding $ip to Authorized Ranges"
	     	 Set-AzAksCluster -ApiServerAccessAuthorizedIpRange $iprange -ResourceGroupName $group -Name $cluster_name -ErrorAction Stop | Out-Null
		 }
		 else
		 {
			echo "[INFO]: K8s API server not locked down. Skipping."
	  	 }
	}
	catch
	{
		Write-Output "[ERROR]: Something went wrong while trying to get the status of the K8s API server."
		Write-Output $_
		exit
	}
}
# Remove IP from runbook from K8s API
function removeIpFromApi
{
	param(
		[Parameter(Mandatory=$false)] [String]$ip
	)
	try
	{
		$iprange = (Get-AzAksCluster -Name $cluster_name -ResourceGroupName $group -ErrorAction Stop).ApiServerAccessProfile.AuthorizedIPRanges
		if ($iprange -gt 0){
			$iprange.remove($ip+"/32")
			echo "[INFO]: Server locked down. Removing $ip from Authorized ranges"
			Set-AzAksCluster -ApiServerAccessAuthorizedIpRange $iprange -ResourceGroupName $group -Name $cluster_name -ErrorAction Stop | Out-Null
		}
		else
		{
			echo "[INFO]: K8s API server not locked down. Skipping."
		}
	}
	catch
	{
		Write-Output "[ERROR]: Something went wrong while removing automation IP from K8s API."
		Write-Output $_
		exit
	}
}
# Execute command against cluster
function executeCronJob
{
	try
	{
		$d = Get-Date -UFormat %s
		$response=Invoke-AzAksRunCommand -ResourceGroupName $group -Name $cluster_name -Command "kubectl create job sas-$action-all-$d --from cronjobs/sas-$action-all -n $namespace" -Force -ErrorAction Stop
		if ($response.Logs -contains "error:"){
			Write-Output "[ERROR]: Executing the cronjob failed with error: $response"
			exit
		}
		$response=Invoke-AzAksRunCommand -ResourceGroupName $group -Name $cluster_name -Command "kubectl wait --for=condition=complete --timeout=15m job/sas-$action-all-$d -n $namespace " -Force -ErrorAction Stop
		if ($response.Logs -contains "error:"){
			Write-Output "[ERROR]: Waiting for the cronjob failed with error: $response"
			exit
		}
		Write-Output "[INFO]: Execution of job completed successfully "
	}
	catch
	{
		Write-Output "[ERROR]: Something went wrong while executing a command against the cluster."
		Write-Output $_
		exit
	}
}
# Stop AKS cluster
function stopAKS 
{
	try
	{
		$ResourceId = (Get-AzAksCluster -ResourceGroupName $group -Name $cluster_name -ErrorAction Stop).Id
    	$Cluster = Get-AzResource -ResourceId $ResourceId -ErrorAction Stop
    	if ($Cluster.Properties.powerState.code -eq "Running")
		{
			Write-Output "[INFO]: Stopping the AKS cluster"	
			Stop-AzAksCluster -ResourceGroupName $group -Name $cluster_name -ErrorAction Stop | Out-Null

		}
		else
		{
			Write-Output "[INFO]: AKS cluster is not running. Skipping."
		}
	}
	catch
	{
		Write-Output "[INFO]: Something went wrong while trying to stop the AKS cluster"
		Write-Output $_
		exit
	}
}
# Start AKS cluster
function startAKS 
{
	try
	{
		$ResourceId = (Get-AzAksCluster -ResourceGroupName $group -Name $cluster_name).Id
    	$Cluster = Get-AzResource -ResourceId $ResourceId
    	if ($Cluster.Properties.powerState.code -ne "Running")
		{
			Write-Output "[INFO]: Starting the AKS cluster"	
			Start-AzAksCluster -ResourceGroupName $group -Name $cluster_name -ErrorAction Stop | Out-Null
			Write-Output "[INFO]: Sleeping for 5 minutes to allow AKS cluster to start"
                        Start-Sleep -Seconds 300
		}
		else
		{
			Write-Output "[INFO]: AKS cluster is not running. Skipping."
		}
	}
	catch
	{
		Write-Output "[ERROR]: Something went wrong while trying to stop the AKS cluster"
		Write-Output $_
		exit
	}
}
# Stop Virtual Machine
function stopVM
{
	param(
		[Parameter (Mandatory = $false)] [String]$vm_name,
		[Parameter (Mandatory = $false)] [String]$VMResourceGroup
	)
	try
	{
		$VMStatuses = (Get-AzVM -ResourceGroupName $VMResourceGroup -Name $vm_name -ErrorAction Stop -Status).Statuses
        $PowerState = $VMStatuses[1].DisplayStatus
		if ($PowerState -ne "VM deallocated") {
			Write-Output "[INFO]: Stopping the virtual machine: $vm_name"
			Stop-AzVM -ResourceGroupName $VMResourceGroup -Name $vm_name -ErrorAction Stop -Force | Out-Null
		}
		else{
			Write-Output "[INFO]: Skipping. Virtual machine: $vm_name already in a stopped state"
		}
	}
	catch
	{
		Write-Output "[ERROR]: Something went wrong while trying to stop virtual machine: $Name"
		Write-Output $_
		exit
	}
}
# Start Virtual Machine
function startVM
{
	param(
		[Parameter (Mandatory = $false)] [String]$vm_name,
		[Parameter (Mandatory = $false)] [String]$VMResourceGroup
	)
	try
	{
		$VMStatuses = (Get-AzVM -ResourceGroupName $VMResourceGroup -Name $vm_name -ErrorAction Stop -Status).Statuses
        $PowerState = $VMStatuses[1].DisplayStatus
		if ($PowerState -eq "VM deallocated") {
			Write-Output "[INFO]: Starting the virtual machine: $vm_name"
			Start-AzVM -ResourceGroupName $VMResourceGroup -Name $vm_name -ErrorAction Stop  | Out-Null
		}
		else{
			Write-Output "[INFO]: Skipping. Virtual machine: $vm_name already in a started state"
		}
	}
	catch
	{
		Write-Output "[ERROR]: Something went wrong while trying to start virtual machine"
		Write-Output $_
		exit
	}
	
}
function checkClusterState
{
	try
	{
		Write-Output "[INFO]: Checking status of AKS cluster"
		$ResourceId = (Get-AzAksCluster -ResourceGroupName $group -Name $cluster_name -ErrorAction Stop).Id
    	$Cluster = Get-AzResource -ResourceId $ResourceId -ErrorAction Stop
    	$value = $Cluster.Properties.powerState.code		
	}
	catch
	{
		Write-Output "[ERROR]: Something went wrong while checking the status of the AKS cluster"
		Write-Output $_
		exit 
	}
	return $value
}

function startPostgresDB
{
  Start-AzPostgreSqlFlexibleServer -Name $postgresqlName -ResourceGroupName $group -ErrorAction ignore
}

function stopPostgresDB
{
  Stop-AzPostgreSqlFlexibleServer -Name $postgresqlName -ResourceGroupName $group -ErrorAction ignore
}

function checkNodePools{
	try
	{
		$nodepools=Get-AzAksNodePool -ResourceGroupName $group -ClusterName $cluster_name -ErrorAction Stop

		foreach($n in $nodepools) {
			$nodepool_name = $n.Name
			Write-Output "[INFO]: Checking status of node for nodepool $nodepool_name"
			$response=(Invoke-AzAksRunCommand -ResourceGroupName $group -Name $cluster_name -Command "kubectl wait --for=condition=Ready nodes -l agentpool=$nodepool_name --timeout=20m" -Force).Logs
			$i=0
			while (($response -Like "*no matching resources found*") -or ($i -eq 20))
			{
    			Write-Output "[INFO]: Node in nodepool $nodepool_name is still provisioning. Sleeping for 30 seconds and will retry again"
				Start-Sleep -Seconds 30
				$response=(Invoke-AzAksRunCommand -ResourceGroupName $group -Name $cluster_name -Command "kubectl wait --for=condition=Ready nodes -l agentpool=$nodepool_name --timeout=20m"  -Force).Logs
				echo "[INFO]: Got the following response from the kubernetes cluster: $response"
				$i++;
			}
			
			if ( $i -eq 20){
				Write-Output "[ERROR]: Hit max retry of 20. Nodepool $nodepool_name has status: $response"
				exit
			}		
			else
			{
				Write-Output "[INFO]: Nodepool $nodepool_name has started. Node(s) are running: $response"
			}	
		}	
	}
	catch
	{
		Write-Output "[ERROR]: Something went wrong while waiting for the AKS cluster nodes to become ready. Please check the status of the cluster through the portal and try again"
		Write-Output $_
		exit 
	}
}

Write-Output "[INFO]: The script will $param SAS Viya"
$action=$param.ToLower()

$group="aom-lab401"
$cluster_name="lab401-aks"
$namespace="lab401"
$postgresqlName = "lab401-viya-db"
$k8s_version="v1.25.6"

# Script

echo "[INFO]: Login using managed identity"
login -id fd2eb4e6-65fa-4cd4-8609-42d675659374

if ($action -eq 'stop')
{
	$status=checkClusterState
	if ($status -eq 'Running')
	{
		echo "[INFO]: AKS cluster is running. Proceeding"
		echo "[INFO]: Getting outbound IP"
		$ip=getRunBookIP
		echo "[INFO]: Found outbound IP: $ip"
		echo "[INFO]: Checking to see if K8s API is locked down"
		addIpToApi -ip $ip
		echo "[INFO]: Execute cronjob to $action SAS Viya"
		executeCronJob
		echo "[INFO:] Remove ip from k8s API if server is locked down"
		removeIpFromApi -ip $ip
		stopAKS
	}
	else
	{
		Write-Output "[INFO]: AKS cluster is not running. Continueing with stopping VM's"
	}

  stopPostgresDB
	#stopVM -Name "nfs"
	#stopVM -Name "jump"

	# Finish
	Write-Output "[INFO]: $action SAS Viya has successfully completed"
}
if ($action -eq 'start')
{
    startVM -vm_name "nordiclabs" -VMResourceGroup "aom-nordiclabs"
	startVM -vm_name "aomdkad" -VMResourceGroup "aom-adserver"
	
  startPostgresDB

	$status=checkClusterState
	if ($status -eq 'Stopped')
	{
		echo "[INFO]: AKS cluster is stopped. Starting AKS cluster and Viya"
		startAKS
		echo "[INFO]: Checking status of nodepools "
		checkNodePools
	}
	echo "[INFO]: Getting outbound IP"
	$ip=getRunBookIP
	echo "[INFO]: Found outbound IP: $ip"
	echo "[INFO]: Checking to see if K8s API is locked down"
	addIpToApi -ip $ip
	echo "[INFO]: Execute cronjob to $action SAS Viya"
	executeCronJob
	echo "[INFO:] Remove ip from k8s API if server is locked down"
	removeIpFromApi -ip $ip

	# Finish
	Write-Output "[INFO]: $action SAS Viya has successfully completed"
}

