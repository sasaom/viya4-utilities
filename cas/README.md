# Viya4 Utilities - CAS

## `getCASCACertificate.sh`

Usage:

```bash
# No input parameters.
./getCASCACertificate.sh
```

> The $VIYA_NAMESPACE env variable must must be set

The scripts retrieves the SAS Viya self-signed certificate used to sign the CAS certificate (and all other internal ones) as save it locally as `CAS.CA.crt`

## `restartCAS.sh`

Usage:

```bash
# No input parameters.
./restartCAS.sh
```

> The $VIYA_NAMESPACE env variable must must be set

The scripts restarts the CAS server.