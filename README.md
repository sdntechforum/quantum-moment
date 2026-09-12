# The Quantum Moment — Companion Code

Runnable labs for **_The Quantum Moment_** by Amit Singh (Apress, 2026).

Every "Try It Yourself" box in the book points here. The code lets you reproduce
the book's claims first-hand — factor 15 on a simulator, weigh the post-quantum
"size tax" in bytes, watch a hybrid TLS handshake grow fat, and build a
cryptographic bill of materials (CBOM) from a small app.

> Canonical home: <https://github.com/sdntechforum/quantum-moment>
> Apress also mirrors a snapshot on their GitHub organization.

## What's inside — by chapter

| Chapter | Folder | What it demonstrates | Key scripts |
|---|---|---|---|
| 3 — Is It Real? | [`ch03/`](ch03/) | Compiled Shor factors 15; Grover's quadratic (not exponential) speedup | `shor15.py`, `grover.py` |
| 6 — The New Toolbox | [`ch06/`](ch06/) | The PQC "size tax" — ML-KEM / ML-DSA / SLH-DSA sizes vs. classical | `measure_pqc_sizes.sh` |
| 7 — Rebuilding the Plumbing | [`ch07/`](ch07/) | Certificate-chain weight, a hybrid TLS 1.3 handshake, and PQC in SSH | `cert-chains/`, `tls/`, `ssh/` |
| 13 — Your Roadmap | [`ch13/`](ch13/) | Generate a CBOM from a sample app and find quantum-vulnerable crypto | `sample-app/` |

## Prerequisites

These labs are command-line and cross-platform (macOS/Linux; Windows via WSL).

- **Ch 3:** Python 3.10+ and Qiskit — `pip install -r ch03/requirements.txt`
- **Ch 6 & 7:** **OpenSSL 3.5+** (for ML-KEM / ML-DSA and the `X25519MLKEM768`
  hybrid group) and a recent **OpenSSH**. See each folder's `README.md`.
- **Ch 13:** **Docker** (to run the CBOM scanner) and Python 3.10+ for the
  sample app — `pip install -r ch13/sample-app/requirements.txt`.

Each chapter folder has its own `README.md` with exact run steps and the output
you should expect.

## Quick start (Chapter 3)

```bash
cd ch03
pip install -r requirements.txt
python shor15.py     # period r = 4  ->  15 = 3 x 5   (12 qubits, ideal simulator)
python grover.py     # 1 of 32 in ~4 steps (√32), a quadratic speedup
```

## Versions tested

The post-quantum toolchain moves fast. These labs were validated against Qiskit
1.x / qiskit-aer, OpenSSL 3.5+, and OpenSSH 9.x. If a library's API has drifted,
open an issue — this repo is maintained, and fixes land here first.

## License

Sample code is released under the [MIT License](LICENSE). The book's text is
© 2026 Amit Singh, published by Apress.

## About

By Amit Singh — **SDN Tech Forum** (YouTube · Spotify · Medium).
Issues and pull requests welcome.
