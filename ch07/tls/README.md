# Lab 2 — Live post-quantum TLS 1.3 handshake

**Backs:** Chapter 7 — *Rebuilding the Plumbing* ("Why size turns into time",
`fig-7-1-initcwnd`); sets up Chapter 8 (ossification).

**Claim tested:** a hybrid post-quantum key exchange (`X25519MLKEM768`) works in a
real TLS 1.3 handshake today, and it makes the very first message — the ClientHello —
balloon, which is what collides with the internet's ~1500-byte packet assumption.

## What it does
Starts a local OpenSSL TLS 1.3 server offering both a classical and a hybrid PQC
group, then runs the client twice and parses `openssl s_client -trace`:

- classical `x25519`
- hybrid `X25519MLKEM768` (X25519 + ML-KEM-768)

and reports the ClientHello size and its `key_share` extension size for each.

## Requirements
- OpenSSL **≥ 3.5** (tested **3.6.3**). No external network — pure loopback.

## Run
```bash
./run_pq_tls.sh            # prints a Markdown summary
./run_pq_tls.sh > results.md
```

## Result captured (`results.md`, OpenSSL 3.6.3)
| Client offered | Negotiated | ClientHello | key_share |
|---|---|---|---|
| x25519 (classical) | ecdh_x25519 | 206 B | 38 B |
| X25519MLKEM768 | X25519MLKEM768 | **1384 B** | **1222 B** |

~6.7× larger ClientHello; the `key_share` alone goes from 38 → 1222 bytes.

Full handshake traces are saved as `trace-x25519.txt` and `trace-X25519MLKEM768.txt`.

## Notes / caveats
- A minimal client ClientHello (1384 B) still fits one 1500-byte packet; a real
  browser's (with SNI/ALPN/GREASE/more sig-algs) plus a PQC key_share does not —
  that overflow is the documented Chrome/Cloudflare ossification issue (ch08).
- `tshark` isn't required; sizes come from OpenSSL's own `-trace`. For packet-level
  framing you could add `tcpdump -i lo0` on the chosen port.
- Public, clean-room: OpenSSL only. No confidential material.
