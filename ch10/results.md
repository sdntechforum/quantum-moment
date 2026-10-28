# Chapter 10 verification record

Verification date: 2026-09-24

The lab was run twice on the authorized Ubuntu lab host. Security-sensitive execution was confined to that host;
Daybreak remained disabled.

## Environment

- Host architecture: x86-64
- Docker Engine: 29.1.3
- Container image:
  `silkeh/clang@sha256:3914c93a02e866795aafc80737488e515b96390eff3d2787cf8c5095997baea9`
- Clang: 18.1.8
- LLVM: 18.1.8
- Compiler options: `--target=x86_64-linux-gnu -DKYBER_K=2 -Os`
- Vulnerable Kyber revision:
  `b628ba78711bc28327dc7d2d5c074a00f061884e`
- Fixed Kyber revision:
  `9b8d30698a3e7449aeb34e62339d4176f11e3c6c`

## Result

Both runs passed the same assertions:

- The vulnerable `poly_frommsg` object contains the expected `bt` instruction
  followed by a `jae` conditional branch.
- The fixed `poly_frommsg` contains no `jae` pattern; the inspected sequence
  uses `setb` and calls `cmov_int16`.
- The container compiled read-only source snapshots with networking disabled,
  all Linux capabilities dropped, and `no-new-privileges` enabled.

The exact environment report, verification output, and extracted function
disassemblies are retained under `results/`.

## Interpretation boundary

The observation establishes a generated-code difference for the pinned source,
compiler, flags, and x86-64 target. It does not prove that every Clang build is
vulnerable, that key recovery will work on every processor, or that the fixed
implementation is free from every timing channel. The upstream Clangover proof
of concept documents the additional processor, measurement, and noise
conditions for end-to-end key recovery; this book lab does not run that attack.

## Setup findings

The first container-build approach depended on a remote Ubuntu package-index
update and stalled. It was replaced with the already-present digest-pinned
Clang image. The first bounded run then exposed a results-directory ownership
mismatch; `run_lab.sh` now maps the remote host user into the container. These
were environment setup defects, not cryptographic findings, and are not treated
as Five-Part Anomaly Records in the chapter.
