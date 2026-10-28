# The Quantum Moment — Companion Code

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Runnable labs for **_The Quantum Moment_** by Amit Singh (Apress, 2026).

The production map below lists only experiments assigned to a reviewed chapter.
It lets you reproduce bounded observations—such as factoring 15 on an ideal
simulator, measuring post-quantum artifact sizes, inspecting hybrid protocol
negotiation, and exercising IKEv2 lifecycle events—without treating unrelated
repository experiments as book dependencies. Only labs mapped during the
completed chapter reviews appear in this table.

> Canonical home: <https://github.com/sdntechforum/quantum-moment>
> Historical v1.0.0 archive (not this reviewed lab set): <https://doi.org/10.5281/zenodo.22721221>
> Edition-specific release and DOI: pending publication review. Do not use the historical archive as evidence for Chapters 8–11 or the hardened Chapter 16 lab.
> Apress also mirrors a snapshot on their GitHub organization.

## What's inside — by chapter

| Chapter | Folder | What it demonstrates | Key scripts |
|---|---|---|---|
| 3 — Is It Real? | [`ch03/`](ch03/) | Compiled Shor factors 15; Grover's quadratic (not exponential) speedup | `shor15.py`, `grover.py` |
| 6 — The New Toolbox | [`ch06/`](ch06/) | The PQC "size tax" — ML-KEM / ML-DSA / SLH-DSA sizes vs. classical | `measure_pqc_sizes.sh` |
| 7 — Rebuilding the Plumbing | [`ch07/`](ch07/) | Certificate-chain weight, a hybrid TLS 1.3 handshake, and PQC in SSH | `cert-chains/`, `tls/`, `ssh/` |
| 8 — Crossing the Bridge | [`ch08/`](ch08/) | RFC 9370 hybrid IKEv2 negotiation and classical-only negative control; Cisco platform-verification boundary | `strongswan/`, `cisco-ppk/` |
| 9 — Quantum-Safe Networking | [`ch09/`](ch09/) | Child SA and IKE SA lifecycle events, fresh versus inherited key input, and clean-policy re-establishment | `strongswan/run_rekey_lab.sh` |
| 10 — When Good Crypto Goes Bad | [`ch10/`](ch10/) | Clangover binary inspection across pinned vulnerable and fixed Kyber revisions | `run_lab.sh`, `inspect_clangover.sh` |
| 11 — Crypto-Agility and the Inventory Problem | [`ch11/`](ch11/) | Safe policy parsing, Ed25519-to-ML-DSA-65 signature transition, public-key verification, and brittle-code comparison | `run_lab.sh`, `run_all.sh`, `agile_sign.sh` |
| 16 — Your Roadmap | [`ch13/`](ch13/) (legacy path) | Digest-pinned CBOM scan, schema validation, and deliberate discovery gaps | `run_lab.sh`, `inspect_cbom.py`, `sample-app/` |

## Prerequisites

These labs are command-line. The Python and local cryptography exercises can run on a suitable macOS or Linux workstation (or Windows via a compatible Linux environment). The Docker networking and security-sensitive labs require an authorized Linux host as specified below.

- **Ch 3:** Python 3.12 and the pinned Qiskit environment — `cd ch03 && ./run_reality_check.sh`
- **Ch 6 & 7:** **OpenSSL 3.5+** for ML-KEM / ML-DSA and the `X25519MLKEM768`
  hybrid group. The Chapter 7 certificate-chain lab requires **OpenSSL 3.6+**;
  the SSH lab requires an OpenSSH build that lists `mlkem768x25519-sha256`.
  See each folder's `README.md`.
- **Ch 8 & 9:** **Docker** on a Linux host. The verified lifecycle labs pin their
  strongSwan container image; see each folder's `README.md` for exact steps.
- **Ch 10:** **Docker**, Git, and an x86-64 Linux host. The verified lab pins a
  Clang/LLVM 18 container image and inspects generated code without running the
  upstream key-recovery proof of concept.
- **Ch 11:** **Docker** on a Linux host. The verified lab pins Alpine 3.22.1 by
  digest, installs OpenSSL 3.5.8, runs with container networking disabled, and
  retains public verification evidence without retaining private keys.
- **Ch 16:** **Docker** and Python 3.10+. The sample app is mounted read-only and
  is not executed; `ch13/run_lab.sh` runs the pinned scanner, validates the
  CycloneDX output, and checks both positive findings and deliberate misses.

Each chapter folder has its own `README.md` with exact run steps and the output
you should expect.

## Quick start (Chapter 3)

```bash
cd ch03
./run_reality_check.sh
```

## Versions tested

The post-quantum toolchain moves fast. Reviewed labs record their exact tested
versions and evidence in the chapter directory. Current verified environments
include Qiskit 2.5.2 / qiskit-aer 0.17.2, OpenSSL 3.5+ (3.6+ for the certificate-chain lab), a capable OpenSSH build, and strongSwan
6.0.6 in a digest-pinned container. Chapter 11 records its exact OpenSSL 3.5.8
container environment and signature-size assertions. If an API or command has drifted, open an
issue and include the chapter, platform, version, and observed output.

## License

Sample code is released under the [MIT License](LICENSE). The book's text is
© 2026 Amit Singh, published by Apress.

## About

By Amit Singh — **SDN Tech Forum** (YouTube · Spotify · Medium).
Issues and pull requests welcome.
