# Chapter 7 — Rebuilding the Plumbing

Three short labs behind the "Try It Yourself" boxes in Chapter 7. They show the
post-quantum migration arriving one protocol at a time — first as raw bytes on
the wire, then as a live key exchange.

| Folder | Lab | Run it to see |
|---|---|---|
| [`cert-chains/`](cert-chains/) | Certificate-chain weight | The DER bytes a TLS server actually sends (intermediate + leaf) per algorithm |
| [`tls/`](tls/) | Hybrid TLS 1.3 handshake | A classical ClientHello vs. `X25519MLKEM768` — the `key_share` swelling in the first packet |
| [`ssh/`](ssh/) | PQC in SSH | A current OpenSSH already advertising ML-KEM key exchange in its default proposal |

**Prerequisites:** OpenSSL 3.5+ and a recent OpenSSH. See each folder's
`README.md` for exact commands and expected output.
