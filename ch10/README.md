# Chapter 10 companion lab

This directory contains the single experiment used by Chapter 10: a bounded
binary-inspection lab for the Clangover compiler transformation. It compiles two
pinned revisions of the Kyber reference implementation and compares the
generated x86-64 code for `poly_frommsg`.

The lab does **not** run the Clangover key-recovery proof of concept, process
secret keys, or attack another service. Its purpose is to show that source-level
constant-time intent is not sufficient evidence for the emitted binary.

## Run on an isolated Linux Docker host

```sh
cd ch10
./run_lab.sh
```

The build pins the `silkeh/clang` Clang/LLVM 18 image by digest. The host fetches
the Kyber repository and exports two exact source snapshots; the container then
runs with networking disabled and those snapshots mounted read-only. The
inspection script pins both upstream source revisions:

- vulnerable: `b628ba78711bc28327dc7d2d5c074a00f061884e`
- fixed: `9b8d30698a3e7449aeb34e62339d4176f11e3c6c`

The run passes only when the vulnerable object contains the expected `bt`/`jae`
sequence and the fixed `poly_frommsg` does not contain the vulnerable `jae`
pattern. Evidence is written to `results/`.

## Interpretation boundary

A passing run proves the compiler emitted the compared instruction patterns for
the pinned source, flags, target, and toolchain. It does not prove that every
Clang build is vulnerable, that the fixed implementation is free of all timing
leakage, or that key recovery will succeed on a particular processor. Full
key-recovery behavior depends on the CPU, noise, compiler configuration, and
measurement environment documented by the original Clangover researchers.

Upstream sources:

- Kyber reference implementation: <https://github.com/pq-crystals/kyber>
- Clangover proof of concept and scope: <https://github.com/antoonpurnal/clangover>

The lab fetches Kyber at run time; it does not vendor Kyber or the Clangover
proof of concept. The retained `results/*-poly_frommsg.txt` disassemblies are
generated from the pinned Kyber source. See the upstream
[Kyber license](https://github.com/pq-crystals/kyber/blob/main/LICENSE) for
that source and its derived output. The repository's MIT license covers the
book lab scripts and explanatory material.
