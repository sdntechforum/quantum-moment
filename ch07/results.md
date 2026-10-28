# Chapter 7 reference results

Review environment:

- macOS arm64
- OpenSSL 3.6.4, 25 August 2026
- OpenSSH 10.3p1 with LibreSSL 3.3.6

## TLS ClientHello

| Group | ClientHello | `key_share` extension |
|---|---:|---:|
| `x25519` | 224 B | 38 B |
| `X25519MLKEM768` | 1,402 B | 1,222 B |

The exact ClientHello total is build- and option-dependent. The 1,184-byte
increase in the `key_share` extension is the stable comparison in this run.

## Minimal certificate chains

The root is excluded; each result is leaf DER plus intermediate DER.

| Algorithm | Leaf | Intermediate | Chain sent |
|---|---:|---:|---:|
| ECDSA P-256 | 463 B | 424 B | 887 B |
| RSA-2048 | 857 B | 816 B | 1,673 B |
| ML-DSA-65 | 5,587 B | 5,547 B | 11,134 B |
| SLH-DSA-SHA2-128s | 8,213 B | 8,176 B | 16,389 B |

These minimalist certificates omit production metadata and do not predict the
size of a public Web PKI chain.

## SSH

The loopback test negotiated:

```text
mlkem768x25519-sha256
```

The SSH connection then failed authentication by design. The key exchange had
already completed, which is the evidence the lab is intended to produce.

## October 2, 2026 Ubuntu-host cross-check

The two OpenSSL scripts were rerun on the authorized Ubuntu lab host inside the
network-isolated `quantum-moment-ch11-agility:openssl-3.5.8` image. The TLS
script completed both loopback negotiations. Its ClientHello / `key_share`
lengths were 226 / 38 B for `x25519` and 1,402 / 1,222 B for
`X25519MLKEM768`. The certificate script verified all four chains and returned
888 B (ECDSA P-256), 1,673 B (RSA-2048), 11,134 B (ML-DSA-65), and 16,389 B
(SLH-DSA-SHA2-128s) for leaf plus intermediate DER. These minor differences
from the macOS OpenSSL 3.6.4 reference output are build/encoding variability,
not changed protocol conclusions.

The SSH script was not rerun on the Ubuntu host: its native OpenSSH 9.6p1 does
not provide the required RFC 10042 method. The earlier OpenSSH 10.3p1
loopback result above remains the SSH evidence. None of these local results
measures Cedar's production path or live ML-DSA TLS authentication.
