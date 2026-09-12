# Lab 1 — PQC algorithms & the "size tax"

**Backs:** Chapter 6 — *The New Toolbox* (Table 6.1, Figure 6.1 `fig-6-1-size-tax`).

**Claim tested:** the NIST post-quantum algorithms are real and usable *today*, and
their keys/signatures/ciphertexts are one-to-two orders of magnitude larger than the
classical primitives they replace — the "size tax."

## What it does
Uses OpenSSL to generate keys, then performs a **real** operation (KEM encapsulation
or a signature) and measures the bytes produced:

- Classical: Ed25519, ECDSA P-256, RSA-2048, X25519.
- PQC KEM: ML-KEM-512 / 768 / 1024 (FIPS 203).
- PQC signatures: ML-DSA-44 / 65 / 87 (FIPS 204); SLH-DSA-SHA2-128s / 128f (FIPS 205).

## Requirements
- OpenSSL **≥ 3.5** (native ML-KEM/ML-DSA/SLH-DSA). Tested on **3.6.3**.
- macOS note: the system `openssl` is LibreSSL — use a real OpenSSL 3.5+ (`brew install openssl@3`).

## Run
```bash
./measure_pqc_sizes.sh            # prints a Markdown table
./measure_pqc_sizes.sh > results.md
```

## Result captured (`results.md`, OpenSSL 3.6.3)
Key numbers (bytes on the wire):

| Item | Classical | PQC | Ratio |
|---|---|---|---|
| Key exchange ciphertext | X25519 pubkey 32 | ML-KEM-768 ct **1088** | ~34× |
| Signature | Ed25519 **64** | ML-DSA-44 **2420** | ~38× |
| Conservative signature | RSA-2048 256 | SLH-DSA-128f **17088** | ~67× |

These match the FIPS raw sizes in Table 6.1 (public-key column shows a few extra
bytes of DER/ASN.1 framing over the raw FIPS key, e.g. ML-KEM-768 raw 1184 → DER 1206).

## Notes / caveats
- FN-DSA (Falcon) is not in OpenSSL 3.6 (draft FIPS 206); its ~666 B signature is
  cited from the standard, not measured.
- ECDSA/RSA signatures are DER-encoded (ECDSA P-256 ≈ 70–72 B; raw r‖s is 64 B).
- Public, clean-room: built only from OpenSSL + FIPS 203/204/205. No confidential material.
