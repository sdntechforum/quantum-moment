# Chapter 7 — Rebuilding the Plumbing

These three local-only labs support the chapter's protocol-size and migration
claims. They are the Chapter 7 experiments intended for the book. They do not
benchmark cryptographic security or production throughput.

| Folder | Lab | Evidence produced |
|---|---|---|
| [`tls/`](tls/) | TLS 1.3 ClientHello size | Compares `x25519` with the standardized `X25519MLKEM768` hybrid group |
| [`cert-chains/`](cert-chains/) | X.509 chain size | Builds minimal two-certificate server chains and measures DER bytes |
| [`ssh/`](ssh/) | SSH hybrid key exchange | Negotiates `mlkem768x25519-sha256` against a loopback-only server |

## Prerequisites

- OpenSSL 3.5 or later for the TLS lab
- OpenSSL 3.6 or later for the ML-DSA and SLH-DSA certificate lab
- OpenSSH with `mlkem768x25519-sha256` support for the SSH lab
- A POSIX shell, `awk`, `grep`, `wc`, and standard Unix utilities

Run each script from its own folder. The TLS and SSH scripts bind only to
`127.0.0.1`; they do not contact an external service. If a default port is in
use, set `PORT` before running the script.

Reference output from the review environment is recorded in [`results.md`](results.md).

## Interpretation limits

The byte counts depend on the OpenSSL build, certificate fields, extensions,
and protocol options. The labs demonstrate message growth and threshold risk;
they are not universal Internet latency measurements. Production decisions
also require tests through the organization's browsers, proxies, load
balancers, firewalls, certificate services, and observability stack.
