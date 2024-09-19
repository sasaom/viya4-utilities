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

### [tag: `Inst-Stable-2024.08`] 2024 Oct 30 - Installation Stable-2024.08

- Author: **your email**

Base installation of Viya4 

Reference: [SAS Viya Platform Administrator - Required Customizations](https://go.documentation.sas.com/doc/en/sasadmincdc/v_055/dplyml0phy0dkr/n1krog58in1e5bn13yfy9zxt52sd.htm)

- `#NAMESPACE#`

  Viya4 is deployed on the  ***`{{ NAME-OF-NAMESPACE }}`*** namespace.

- `#CLUSTERINGRESS#`

  Cluster Ingress
  - URL: ***`{{ NAME-OF-INGRESS-HOST }}`***
  - PORT: ***`{{ PORT }}`***

- `#RWXSTORAGE#`

  The StorageClass used by Viya4 to dynamically provision RWX PVC is ***`{{ RWX-STORAGE-CLASS }}`***

  Note: **SAS requires a POSIX-compliant file system.** 

- `#MIRROR#`

  See: [SAS Viya Platform Administrator - Using a Mirror Registry](https://go.documentation.sas.com/doc/en/sasadmincdc/v_055/dplyml0phy0dkr/n08u2yg8tdkb4jn18u8zsi6yfv3d.htm#p16pozfc1zct66n1b8sitnf1vsfk)
  
  An internal Container Registry is used by Viya4.

  ```bash
  ############ TO BE DONE ##############

  # See sas-bases/examples/mirror/README.md

  # Replace {{ MIRROR-HOST }} with ` ... ` 
  
  ```

- `#VIYADB_INTERNAL#` 

  (Default) Viya4 uses an internal instace of PostgreSQL.

- `#OPENSEARCH_INTERNAL#` 

  **Viya4 uses an internal instace of OpenSearch.**

  - (Default) Use of an init-container to configure the Default Virtual Memory Resources.
    - The SAS Viya platform includes an optional transformer as part of the internal-elasticsearch overlay that adds an init container to automatically set this parameter. **This init container must be run at a privileged level since it modifies the kernel parameters of the host.** The container terminates after it sets the kernel parameter. The OpenSearch software then starts as a non-privileged container. Therefore, privileged containers must be permitted by your Pod Security Standards to use this option.

  - (Default) No High Availability is configured for the internal OpenSearch.

  - (Default) The OpenSearch JVM process runs under the fixed UID of 1000.

  - (Default) The OpenSearch is **NOT** running in a **FIPS-enabled environment**. 

  - (Default) OpenSearch deletes security audit log indices after seven days.

- `#OPENSSL#` 

  (default) The openssl certificate generator is used.

- `#TLS_FULLSTACK#`

  (default) In Full-stack TLS mode, the ingress controller must be configured to decrypt incoming network traffic and re-encrypt traffic before forwarding it to the back-end SAS servers. Network traffic between SAS servers is encrypted in this mode.

- `#TLS-INGRESS#` 

  The TLS used by Ingress is provided by the customer.
  
  ```bash
  ############ TO BE DONE ##############

  # See sas-bases/examples/security/README.md

  # The TLS certificates are provided in `/nfs/share/resources/tls`
  
  ```

- `#TLS-CABUNDLE#`

  Customer proprietary CA certificates are added to the Viya4 internal Trust Store.
  
  ```bash
  ############ TO BE DONE ##############

  # See sas-bases/examples/security/README.md

  # The TLS certificates are provided in `/nfs/share/resources/tls`
  
  ```

- `#CAS_SMP#`

  (Default) Single Node CAS deployment.

- `#CAS_RESOURCES#`

  (Default) Autoresourcing is enabled.
  > Note: For auto-resourcing to work appropriately, the CAS node pool must have the appropriate taints.

- `#UPDATE-CHECKER#`

  The Update Checker is disabled. 