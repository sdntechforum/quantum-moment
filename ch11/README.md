# Chapter 11 companion lab

This directory contains the Chapter 11 crypto-agility experiment. It compares
two narrow implementation patterns:

- `agile_sign.sh` parses a one-line policy as data, accepts only an explicit
  algorithm allowlist, and runs unchanged with Ed25519 and ML-DSA-65.
- `brittle_ed25519.sh` and `brittle_mldsa65.sh` hardcode the choice, so the
  migration changes the executable script.

The lab also rejects a policy containing shell syntax. This matters because the
first draft used `. ./crypto-policy.conf`; in POSIX shell, `.` executes a file.
That construct does not establish a safe configuration boundary.

## Run on the authorized Linux Docker host

```sh
cd ch11
./run_lab.sh
```

The Dockerfile pins Alpine 3.22.1 by digest and installs OpenSSL 3.5.8, which
provides the standardized ML-DSA algorithms. The run disables container
networking, mounts the lab read-only, and writes evidence to `results/`.

A passing run verifies all of the following:

- the same agile script signs and verifies with Ed25519 and ML-DSA-65;
- verification uses the public key rather than the private key;
- generated private keys remain in the container's temporary filesystem and are
  not retained as published evidence;
- Ed25519 and ML-DSA-65 signatures are 64 and 3,309 bytes, respectively;
- the malicious policy is rejected and is not executed; and
- the paired hardcoded examples have different source hashes.

## Interpretation boundary

This is a controlled demonstration of configuration-driven selection, strict
policy parsing, variable-size artifacts, and evidence capture. It does **not**
prove that a production system is crypto-agile. Production agility also depends
on provider and HSM support, algorithm identifiers and file formats, key and
certificate lifecycle, peer interoperability, persisted-data migration,
downgrade resistance, observability, rollback, and the ability to continue
verifying artifacts created under the retired policy.

Primary references:

- NIST CSWP 39upd1, *Considerations for Achieving Crypto Agility*:
  <https://doi.org/10.6028/NIST.CSWP.39-upd1>
- OpenSSL 3.5 release notes:
  <https://openssl-library.org/news/openssl-3.5-notes/index.html>
- FIPS 204, *Module-Lattice-Based Digital Signature Standard*:
  <https://doi.org/10.6028/NIST.FIPS.204>
