# acme-vault (deliberately crypto-laden sample)

A tiny, **intentionally realistic** Python service used only as a scan target for
the Chapter 16 CBOM capstone. It is not meant to be secure or even run in
production — it exists so a Cryptography Bill of Materials tool has something to
find. The crypto is spread across several modules on purpose, including a couple
of places where it hides in plain sight (a weak hash used for "cache keys"),
to make the book's point: *you cannot migrate what you cannot see.*

Deliberate spread of cryptographic assets:
- `vault/keys.py` — RSA-2048 and EC P-256 key generation (both **quantum-vulnerable**).
- `vault/exchange.py` — finite-field Diffie-Hellman and ECDH (**quantum-vulnerable**).
- `vault/storage.py` — AES-GCM, legacy AES-CBC, and Fernet. The AES functions
  accept caller-supplied valid AES key lengths, so neither the function name nor
  the CBOM proves a deployed key size or security category.
- `vault/tokens.py` — HMAC-SHA256 (fine); **MD5/SHA-1 via pyca** hiding as
  "fingerprints"/"tags" (**broken/deprecated**, and this scanner flags these);
  plus the **same MD5/SHA-1 via the stdlib `hashlib`**, which a pyca-focused
  source scanner **misses** — a deliberate demonstration of tool coverage gaps.
- `vault/exchange.py` — finite-field DH and ECDH. The pinned scan also misses
  these uses, showing that support for a library does not imply coverage of every
  API or cryptographic operation within it.

The sample is never executed by the lab. It is mounted read-only as scanner
input, and its comments and function names are not treated as evidence of
runtime key length or deployment state.
