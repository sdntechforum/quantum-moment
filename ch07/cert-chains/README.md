# Measure X.509 certificate-chain size

Run:

```sh
./measure_cert_chains.sh
```

The script creates a root CA, an intermediate CA, and a leaf certificate for
each algorithm. It verifies the chain and reports the DER size of the leaf plus
intermediate certificates. The root is excluded because TLS clients normally
receive trust anchors out of band.

The certificates deliberately contain only the extensions needed for the lab.
Production certificates can be larger because of names, policies, revocation
metadata, Certificate Transparency data, and other extensions.
