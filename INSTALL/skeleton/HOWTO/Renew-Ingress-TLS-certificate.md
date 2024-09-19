# Renew TLS Ingress Certificate

## Impact on Viya4 Monitoring and Logging

References:
- https://go.documentation.sas.com/doc/en/obsrvcdc/v_002/obsrvdply/p0ssqw32dy9a44n1rokwojskla19.htm#n0sghivkfndketn1fltphnopwz10


If monitoring ad logging where configured with path-based ingress (e.g.: https://viy4url.xxx.yyy/dashboard), then:

```bash
# LOGGING

V4LOGGING_NS="logging"

NEW_TLS_FILE="xxxxxxxxxxxxxxxx"
NEW_KEY_FILE="xxxxxxxxxxxxxxxx"

secretname="elasticsearch-ingress-tls-secret"
kubectl -n $V4LOGGING_NS delete secret $secretname --ignore-not-found
kubectl -n $V4LOGGING_NS create secret tls $secretname --key=$NEW_KEY_FILE --cert=$NEW_TLS_FILE

secretname="kibana-ingress-tls-secret"
kubectl -n $V4LOGGING_NS delete secret $secretname --ignore-not-found
kubectl -n $V4LOGGING_NS create secret tls $secretname --key=$NEW_KEY_FILE --cert=$NEW_TLS_FILE

# MONITORING
V4MONITORING_NS="monitoring"

secretname="grafana-ingress-tls-secret"
kubectl -n $V4MONITORING_NS delete secret elasticsearch-ingress-tls-secret --ignore-not-found
kubectl -n $V4MONITORING_NS create secret tls elasticsearch-ingress-tls-secret --key=$NEW_KEY_FILE --cert=$NEW_TLS_FILEnordiclabs_wildcard.pem

secretname="prometheus-ingress-tls-secret"
kubectl -n $V4MONITORING_NS delete secret elasticsearch-ingress-tls-secret --ignore-not-found
kubectl -n $V4MONITORING_NS create secret tls elasticsearch-ingress-tls-secret --key=$NEW_KEY_FILE --cert=$NEW_TLS_FILEnordiclabs_wildcard.pem

secretname="alertmanager-ingress-tls-secret"
kubectl -n $V4MONITORING_NS delete secret elasticsearch-ingress-tls-secret --ignore-not-found
kubectl -n $V4MONITORING_NS create secret tls elasticsearch-ingress-tls-secret --key=$NEW_KEY_FILE --cert=$NEW_TLS_FILE

## MOVE TO THE FOLDER WHERE THE viya4-monitoring-kubernetes WAS CLONED

cd viya4-monitoring-kubernetes/bin/
./renew-tls-certs.sh -t ALL -r
```