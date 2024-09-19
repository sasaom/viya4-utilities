# Viya4 Deployment

|||
|---------------------|-------------------------------------------------|
|#VIYA4URL#           |**https://XXXX.YYYY.ZZZ**|
|#CADENCE#            |*Stable, LTS*|
|#DEPLOYMENT-METHOD#  |*Manual,Deployment Operator,sas-rochestration,DaC*|
|#GITREPO#            |*Local, GitHub (https://github.com/XXXXX/XXXXXXX.git)*|
|#SECRETVAULT#        |*Where are TLS keys and password stored ?*|
|#DEDICATED-CLUSTER#  |Yes, No|
|#CLUSTERTYPE#        |Openshift OCP, Openshift OKE, AKS, Vanilla Kubertes, Tanzu on VMWare|
|#NODEPOOLS#          |CAS, sas, nosas, infra|
|#MIRROR#             |No mirror,ACR (aomdk.azurecr.io)|
|#EXTPROXY#           |No external proxy (clients connect to the cluster Load Balancer)|
|#CERTMANAGER#        |OpenSSL, CertManager|
|#VIYADB_INTERNAL#    |Internal Crunchy DB|
|#OPENSEARCH_INTERNAL#|Internal OpenSearch|
|#INGRESS#            |nginx-ingress, route|


## Deployment description

```bash
# The environment variables used by the scripts are defined in VIYA4ENV.sh
# This file is sourced in ~/.bashrc

# How to build to manifest

# How to deploy the manifest

# How to commit (and push) to the git repo + tags

```

## History

### [tag: `Inst-Stable-2024.08`] 2024 Oct 31 - Installation Stable-2024.08

- Author: **your email**

Base installation of Viya4

- `#VIYADB_INTERNAL#`

  

- `#RWXSTORAGE#`

- `#TLS_FULLSTACK#` 

- `#TLS-CABUNDLE#`

- `#CAS_SMP#`

- `#CAS_RESOURCES#`

  Enable/Disable Use autoresourcing
  > Note: For auto-resourcing to work appropriately, you must have set labels on your node

  With no auroresourcing, you can djust RAM and CPU Resources for CAS Servers

- `#WORLOAD_CR_CRB#`