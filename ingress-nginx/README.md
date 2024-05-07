# INGRESS-NGINX operations

## Update Ingress IP whitelist

1) Add to the `intenal-ip-whitelist.txt` all the ip ranges that should be included in the ingress whitelist. E.g.:

    ```bash
    # This is an example of internal ip ranges 
    62.198.6.116/32    # SAS Aarhus offices
    80.80.4.0/27       # SAS Copenhagen offices
    149.173.0.0/16     # SAS Cary offices
    ```
2) Login to azure with `az login` command. A new window should open on the browser to authenticate to the Azure Portal (use the Admin account).

3) Run

    #### On a Windows Powershell 

    ```powershell
    .\update-ingress-ip-whitelist.ps1
    ```

    #### On Linux
    
    ```powershell
    .\update-ingress-ip-whitelist.sh
    ```

   The script:
   - gets the IP ranges used by all Azure services (using the `az network list-service-tags` commands) on a specific location (check the `azurelocation` variable inside the file)
   - add the ip ranges from the `intenal-ip-whitelist.txt` file
   - create the `ingress-ip-whitelist-patch.yaml` file

4) (Optional, recommended) Check the content of `ingress-ip-whitelist-patch.yaml`

5) Apply the patch with the command:

    #### On a Windows Powershell 
    ```powershell
    $viya4_ingress_namespace = "ingress-nginx"
    $ingress_patch_file_path = "ingress-ip-whitelist-patch.yaml"

    kubectl patch service ingress-nginx-controller -n $viya4_ingress_namespace --patch-file $ingress_patch_file_path
    ```

    #### On Linux
    ```powershell
    viya4_ingress_namespace="ingress-nginx"
    ingress_patch_file_path="ingress-ip-whitelist-patch.yaml"

    kubectl patch service ingress-nginx-controller -n $viya4_ingress_namespace --patch-file $ingress_patch_file_path
    ```