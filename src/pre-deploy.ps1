

If (Test-Path site-cluster-api.yaml) {
    Rename-Item -Path site-cluster-api.yaml -NewName site-cluster-api.yaml.PREV
}
.\yq.exe e 'select(.metadata.labels.\"sas.com/admin\" == \"cluster-api\")' site.yaml > site-cluster-api.yaml

If (Test-Path site-cluster-wide.yaml) {
    Rename-Item -Path site-cluster-wide.yaml -NewName site-cluster-wide.yaml.PREV
}
.\yq.exe e 'select(.metadata.labels.\"sas.com/admin\" == \"cluster-wide\")' site.yaml > site-cluster-wide.yaml

If (Test-Path site-cluster-local.yaml) {
    Rename-Item -Path site-cluster-local.yaml -NewName site-cluster-local.yaml.PREV
}
.\yq.exe e 'select(.metadata.labels.\"sas.com/admin\" == \"cluster-local\")' site.yaml > site-cluster-local.yaml

If (Test-Path site-namespace.yaml) {
    Rename-Item -Path site-namespace.yaml -NewName site-namespace.yaml.PREV
}
.\yq.exe e 'select(.metadata.labels.\"sas.com/admin\" == \"namespace\")' site.yaml > site-namespace.yaml