# Lab 1 — PQC algorithms & the "size tax"

**Backs:** Chapter 6 — *The New Toolbox* (Table 6-2 and Figure 6-4).

**Claim tested:** the selected OpenSSL implementation can invoke the named NIST
algorithms and produce measurable keys, signatures, and KEM ciphertexts. The
size difference depends on the exact artifact and parameter set; this lab does
not measure protocol traffic or production performance.

## What it does
Uses OpenSSL to generate keys, then performs a **real** operation (KEM encapsulation
or a signature) and measures the bytes produced:

- Classical: Ed25519, ECDSA P-256, RSA-2048, X25519.
- PQC KEM: ML-KEM-512 / 768 / 1024 (FIPS 203).
- PQC signatures: ML-DSA-44 / 65 / 87 (FIPS 204); SLH-DSA-SHA2-128s / 128f (FIPS 205).

## Requirements
- OpenSSL **≥ 3.5** (native ML-KEM/ML-DSA/SLH-DSA). Tested on **3.6.3** and on **3.5.8** in a network-isolated Ubuntu-host container on 2 October 2026.
- macOS note: the system `openssl` is LibreSSL — use a real OpenSSL 3.5+ (`brew install openssl@3`).

## Run
```bash
./measure_pqc_sizes.sh            # prints a Markdown table
./measure_pqc_sizes.sh > results.md
```

## Reference result (OpenSSL 3.6.3)
Representative raw operation-output sizes (bytes; not full protocol messages):

| Item | Classical | PQC | Ratio |
|---|---|---|---|
| Key-establishment artifact | X25519 public value 32 | ML-KEM-768 ct **1088** | ~34× in bytes; different roles |
| Signature | Ed25519 **64** | ML-DSA-44 **2420** | ~38× |
| Conservative signature | RSA-2048 256 | SLH-DSA-128f **17088** | ~67× |

These match the FIPS raw sizes in Table 6-2 (public-key column shows a few extra
bytes of DER/ASN.1 framing over the raw FIPS key, e.g. ML-KEM-768 raw 1184 → DER 1206).
The printed chapter also checks that verification of an altered message returns
a nonzero result; the size-reporting script does not claim that negative check.

## Notes / caveats
- FN-DSA (Falcon) was not available in the tested builds. As of October 2026, NIST lists
  FIPS 206 as **in development**, not as a final standard;
  the representative Falcon-512 signature size is cited from NIST's selected-
  algorithm material, not measured by this lab.
- ECDSA/RSA signatures are DER-encoded (ECDSA P-256 ≈ 70–72 B; raw r‖s is 64 B).
- Public, clean-room: built only from OpenSSL + FIPS 203/204/205. No confidential material.
