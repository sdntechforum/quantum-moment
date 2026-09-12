# Lab 1b — Certificate-chain size explosion (classical vs PQC)

The companion to Lab 1. Lab 1 weighed *raw* algorithm artifacts (keys, signatures,
KEM ciphertexts). This lab shows what happens when those artifacts are wrapped in
real **X.509 certificates** and stacked into an authentication **chain** — the
number that hits every TLS handshake. Backs **Chapter 6** (the "size tax") and
**Chapter 7** (PKI / authentication bloat).

## What it does
For each signature algorithm it stands up a realistic 3-tier PKI —
**Root CA → Intermediate CA → leaf/server cert** — and measures the DER bytes of
each certificate plus:
- **chain-on-wire** = intermediate + leaf (what a TLS server actually sends; the
  root is already in the client's trust store), and
- **full chain** = root + intermediate + leaf.

Algorithms: ECDSA P-256 and RSA-2048 (classical baselines) vs ML-DSA-44/65/87
(lattice) and SLH-DSA-128s (hash-based).

## Requirements
- OpenSSL ≥ 3.5 (tested on 3.6.3). On macOS use Homebrew's `openssl@3`, not the
  system LibreSSL. Override the binary with `OSSL=/path/to/openssl` if needed.

## Run
```
./build_cert_chains.sh            # prints the Markdown report
./build_cert_chains.sh > results.md
```
Everything happens in a `mktemp` dir that is deleted on exit; no state is left
behind and nothing is installed.

## Headline result (see results.md)
Chain-on-wire vs ECDSA P-256 (~1.0 KB): RSA-2048 ~1.8×, **ML-DSA-65 ~11×**,
SLH-DSA-128s ~16×. A PQC certificate is fat twice (big public key *and* big
issuer signature), and the chain multiplies it.

## Files
- `build_cert_chains.sh` — the builder/measurer.
- `results.md` — the measured table + "what this means" analysis.
