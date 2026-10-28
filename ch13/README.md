# Chapter 16 lab — CBOM evidence and coverage gaps

Scan a bounded Python sample and emit a **Cryptography Bill of Materials** using
the open-source **CBOMkit** action. The lab supports canonical **Chapter 16**,
*Your Roadmap*. The `ch13/` directory name is retained only for compatibility
with the early companion-repository layout.

The result is discovery evidence, not a completeness certificate. The positive
findings show what this scanner can see through its current Python rules. The
negative controls show cryptography that remains in the source but absent from
the generated CBOM.

## What it does
`run_lab.sh` points the scanner at `sample-app/`, writes a CycloneDX 1.6 CBOM,
validates it with the official CycloneDX CLI, and runs bounded assertions over
the positive findings and deliberate misses. The containers have no network,
the source mount is read-only, and both images are pinned by digest.

## Requirements
- A Linux host with Docker; user in the `docker` group (no `sudo`).
- Python 3.10+ for the standard-library evidence checker.
- Network access is needed only to obtain the two pinned images before the lab;
  the scan and schema validation run with container networking disabled.

## Run

```bash
cd ch13
./run_lab.sh
```

Outputs are written under `output/`: consolidated `cbom.json`, module-level
`cbom_vault.json`, the action output marker, `summary.txt`, and `environment.txt`.
The environment record contains the UTC run date, Docker server version, pinned
image references and resolved image IDs, and SHA-256 values for the four scanned
Python files. It identifies the bounded run; it is not a completeness certificate.

## What the result means

- The CBOM proves which findings the pinned scanner emitted from these four
  source files during this run.
- The official CLI proves that the output conforms to the CycloneDX 1.6 schema.
- Neither result proves discovery completeness, deployment state, runtime use,
  key length, certificate population, protocol negotiation, or secret handling.
- Current negative controls are `hashlib` MD5/SHA-1 and the DH/ECDH operations
  in `vault/exchange.py`. If a later scanner begins reporting them, the evidence
  checker stops so the book result can be reviewed rather than silently drift.

## Files
- `sample-app/` — bounded scan target with positive and negative controls.
- `run_lab.sh` — digest-pinned, network-disabled scan and validation workflow.
- `inspect_cbom.py` — evidence assertions and coverage-gap checks.
- `results.md` — verified environment, observed result, and interpretation limits.

## Cleanup
The containers use `--rm`. The generated files remain only under `ch13/output/`
until you remove that directory's contents.
