
#!/bin/bash

exitWithError() {
  echo "*ERROR* $1"
  exit 1
}

[[ -z $VIYA_NAMESPACE ]] && exitWithError "Environment variable VIYA_NAMESPACE not defined."

kubectl -n $VIYA_NAMESPACE get secrets sas-cas-server-default-controller -o json | jq -r '.data."ca.crt"' | base64 -d > CAS.CA.crt

echo "CA certificate used by CAS has been saved to the file: CAS.CA.crt"