# Viya4 Utilities - Tools

## `downloadTools.sh`

Usage:

```bash
# No input parameters.
./downloadTools.sh
```

> The $VIYA4_TOOLS env variable must must be set

The scripts downloads and unzip the following tools into the $VIYA4_TOOLS folder:

|Tool|Version|
|----|-------|
|jq  |JQ_VER="1.7.1"|
|kustomize|KUSTOMIZE_VER="v5.0.3"|
|kubectl|KUBECTL_VER="v1.27.9"|
|yq|YQ_VER="v4.42.1"|

To get a different version, modify the value of the variable inside the file.
