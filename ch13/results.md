# Chapter 16 CBOM lab results

Originally verified on 2026-09-24 and reverified on 2026-10-12 UTC on the designated Ubuntu host with Docker 29.1.3. The final proof run generated `output/environment.txt` with its UTC date, the two pinned image references and resolved IDs, and SHA-256 values for all four sample Python files. This file records the observed result; retain a fresh environment record with each run.

## Pinned environment

- CBOMkit action image: `ghcr.io/cbomkit/cbomkit-action@sha256:7dfc905c614549fdb630d41a33b34a039af7f60c982501c6d74dfc63ef700512`
- CycloneDX CLI image: `cyclonedx/cyclonedx-cli@sha256:252c2e26f468c25fea1e63ecde1bc3198ad6e9dbb57f5ed3236bddcb2281b3a7`
- Scanner network: disabled
- Source mount: read-only
- Container user: invoking host UID and GID

## Verified result

The scanner processed four Python files and reported 15 evidence occurrences across 13 CycloneDX components. The official CycloneDX CLI validated the consolidated output as CycloneDX 1.6.

Detected algorithm records included RSA-2048, EC-secp256r1 key generation, HMAC-SHA-256, MD5, SHA-1, AES-GCM, AES-CBC, and Fernet. The generated CBOM also modeled Fernet dependencies, including AES-128-CBC-PKCS7 and SHA-256.

## Deliberate negative controls

The same scan did not report either of these source categories:

- finite-field Diffie-Hellman and ECDH operations in `vault/exchange.py`;
- MD5 and SHA-1 invoked through Python's standard-library `hashlib` in `vault/tokens.py`.

The negative controls are the important result. A schema-valid CBOM and a successful scanner exit prove that a specific tool ran and emitted evidence. They do not prove complete cryptographic discovery.

## Additional interpretation limit

The sample's `encrypt_blob` function accepts an AES key but does not enforce a key length. The source comment cannot prove AES-256 use, and the scanner's AES-GCM record does not establish the runtime key length. Runtime configuration, call-site analysis, protocol observation, certificate and key-management inventories, vendor evidence, and manual review remain separate discovery inputs.
