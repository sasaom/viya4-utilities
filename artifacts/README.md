# Viya4 Utilities - Artifacts

## `downloadArtifacts.sh` `downloadArtifacts.ps1`

Usage:

```bash
# No input parameters.
./downloadArtifacts.sh
```

It's possibile to download the SAS Viya artifacts associated to your Service Order using the **SAS Viya Order** API.

First time you need to register an application to get access to these API following the instructions in https://apiportal.sas.com/get-started.

When you have the client key and secret, create a myorder.json file (copying from the myorder-SAMPLE.json) and fill the required values.
The Azure Container Registry URL and credentials are also required.
E.g.:

```json
{
  "CADENCENAME":"lst",
  "CADENCEVERSION":"2023.10",
  "CADENCE":"lts-2023.10",
  "ORDERNUMBER":"ABCDEF",
  "SECRET":"....",
  "KEY":"....",
  "ACRURL":"XYZ.azurecr.io",
  "ACRUSERNAME":"...",
  "ACRPASSWORD":"..."
}
```


## `downloadMirrorManager.sh`


Usage:

```bash
# No input parameters.
./downloadMirrorManager.sh
```

> The $VIYA4_ARTIFACTS env variable must must be set

The scripts downloads and unzip the `mirrormgr` package into the $VIYA4_ARTIFACTS folder.


## `downloadViyaOrderCLI.sh`

Usage:

```bash
# No input parameters.
./downloadViyaOrderCLI.sh
```

> The $VIYA4_ARTIFACTS env variable must must be set

The scripts downloads and unzip the `viya4-orders-cli` package into the $VIYA4_ARTIFACTS folder.



