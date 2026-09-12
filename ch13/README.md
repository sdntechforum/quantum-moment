# Lab 5 — CBOM crypto inventory (CycloneDX from source)

Scan a codebase and emit a **Cryptography Bill of Materials** — a machine-readable
inventory of every cryptographic asset, with file/line evidence — using IBM's
open-source **CBOMkit** (the `cbomkit-action` container wrapping the
CBOMkit-hyperion / sonar-cryptography engine). Backs **Chapter 7** (inventory)
and **Chapter 13** (roadmap/triage); it is Maya's "you can't migrate what you
can't see" step from Chapter 8, made real.

## What it does
Points the scanner at `sample-app/` (a deliberately crypto-laden Python service)
and produces a CycloneDX 1.6 CBOM listing RSA, EC, AES modes, Fernet, HMAC, and
hashes — each tied to the exact source line — then classifies them for a
post-quantum lens (see `results.md`).

## Requirements
- A Linux host with Docker; user in the `docker` group (no `sudo`).
- Image `ghcr.io/cbomkit/cbomkit-action:edge` — the only thing pulled; nothing is
  installed on the host, and Python needs no build step.

## Run (from `labs/lab4-strongswan/`, whose `rsh.sh` wraps SSH to the host)
```
# sample-app already lives at ~/pqc-lab5-cbom/sample-app on the host
./rsh.sh 'mkdir -p ~/pqc-lab5-cbom/sample-app/cbom
  docker run --rm --user "$(id -u):$(id -g)" -w /work \
    -e GITHUB_WORKSPACE=/work -e GITHUB_OUTPUT=/work/gh_output.txt \
    -e CBOMKIT_OUTPUT_DIR=/work/cbom -e CBOMKIT_LANGUAGES=python \
    -e CBOMKIT_WRITE_EMTPY_CBOMS=false \
    -v ~/pqc-lab5-cbom/sample-app:/work \
    ghcr.io/cbomkit/cbomkit-action:edge'
```
Outputs `cbom.json` (consolidated) and `cbom_<module>.json` in `sample-app/cbom/`.
The container is run as your UID so the files stay owned by you.

## Gotchas (see ENGINEERING-LOG.md)
- The output directory must **exist and be given as an absolute path**
  (`CBOMKIT_OUTPUT_DIR=/work/cbom` + `-w /work`); otherwise the scan succeeds but
  the write fails with `FileNotFoundException`.
- The engine models **`pyca/cryptography`**; identical algorithms called via the
  stdlib **`hashlib`** are **not** detected — a real coverage gap, kept in the
  sample on purpose.

## Files
- `sample-app/` — the scan target (Python; RSA, EC, DH/ECDH, AES-GCM/CBC, Fernet,
  HMAC, and MD5/SHA-1 via both pyca *and* hashlib).
- `output/cbom.json`, `output/cbom_vault.json` — the generated CycloneDX 1.6 CBOMs.
- `results.md` — classified inventory + the honest coverage-gap discussion.
- `INSTALL-LOG.md` / `ENGINEERING-LOG.md` — remote changes and full narrative.

## Cleanup
Everything is under `~/pqc-lab5-cbom` on the host and runs in a throwaway
container (`--rm`); nothing else is touched. Remove with
`./rsh.sh 'rm -rf ~/pqc-lab5-cbom'`.
