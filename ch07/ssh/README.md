# Lab 7 — Post-quantum key exchange in SSH

Show that a current OpenSSH already carries **post-quantum key exchange** — the
same ML-KEM-768 + X25519 hybrid as the TLS lab — and negotiate it live on
loopback. A companion to Lab 2 (PQ-TLS): PQC is spreading beyond the web.

## What it does
Spins an ephemeral `sshd` on `127.0.0.1:2222` (throwaway host key, auth disabled)
and connects to it four ways, capturing the **negotiated** KEX from `ssh -vv`
(the key exchange finishes before authentication, so no login is needed):

1. **default** (no override) — what your client picks on its own.
2. **curve25519-sha256** — classical control.
3. **mlkem768x25519-sha256** — ML-KEM-768 + X25519 hybrid (PQC).
4. **sntrup761x25519** — Streamlined NTRU Prime + X25519 (a second PQC family).

## Requirements
- System OpenSSH client **and** `sshd` (tested: OpenSSH_10.2p1, LibreSSL 3.3.6).
- No network beyond loopback; runs unprivileged (`sshd -d` debug mode).

## Run
```
./run_ssh_pqc.sh            # prints a Markdown summary
./run_ssh_pqc.sh > results.md
```

## What we measured (this machine)
- The client **advertises** PQC KEX in its default proposal (`mlkem768x25519`,
  `sntrup761x25519`), but this build orders `ecdh-sha2-nistp256` first, so the
  **default negotiated KEX was classical** — a one-line `KexAlgorithms` setting
  flips it to PQC.
- When asked, **`mlkem768x25519-sha256`** and **`sntrup761x25519`** both
  negotiate cleanly — real post-quantum key exchange, no extra software.
- Full traces in `client-*.log`; summary in `results.md`.

## Note
The default KEX order is build/policy dependent. Upstream OpenSSH (>=9.9) prefers
`mlkem768x25519-sha256` by default; some downstream builds (like this one) still
list a classical group first. The point holds either way: the PQC plumbing is
already present — enabling/preferring it is a config line, not an upgrade.

## Guardrail
Public tooling only; loopback only; the throwaway host key is generated per run
and discarded. No real secrets.
