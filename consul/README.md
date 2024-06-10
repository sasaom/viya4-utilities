# Viya4 Utilities - Consul

## `getConsulToken.sh`

Usage:

```bash
# No input parameters.
./getConsulToken.sh
```

> The $VIYA_NAMESPACE env variable must must be set

The scripts retrieves a token to connect to Consul and as save it:
- locally, in the `CONSUL.TOKEN` file
- in the environment variable `$CONSUL_HTTP_TOKEN`

## `getConsulKeyValue.sh`

Usage:

```bash
# Input param:
# - consulpath: the path to retrieve thekey/value pairs from consul (default: "/")
./getConsulKeyValue.sh <onsulpath (default: "/")>
```

> The $VIYA_NAMESPACE env variable must must be set

The script exec into the Viya consul pod the command `/opt/sas/viya/home/bin/sas-bootstrap-config kv read --recurse $CONSULPATH` and save locally the result into the file ´CONSUL-KEY-VALUE.txt`.