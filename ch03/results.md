# Chapter 3 lab results - quantum reality check

_qiskit 2.5.2 | qiskit-aer 0.17.2, 2026-09-24T16:45:58Z, Aer statevector simulator (ideal, noiseless)._

## Chapter 3 lab A - compiled Shor period finding for 15

_N = 15, a = 7; 8 counting qubits + 4 work qubits = 12 qubits; transpiled depth 3298, 3372 gates; 2048 shots._

Measured phases (top outcomes) - the peaks land on multiples of 1/4, which is how the machine announces the period r = 4:

| Measured (bin) | Decimal | Phase | Nearest fraction | Shots |
|---|---|---|---|---|
| `10000000` | 128 | 0.500 | 1/2 | 528 |
| `11000000` | 192 | 0.750 | 3/4 | 519 |
| `00000000` | 0 | 0.000 | 0/1 | 511 |
| `01000000` | 64 | 0.250 | 1/4 | 490 |

**Classical finish:** period r = 4, so a^(r/2) = 7^2 = 4 (mod 15); gcd(4-1, 15) = 3 and gcd(4+1, 15) = 5.

**Result: 15 = 3 x 5.** The simulated period-finding circuit identified r = 4; classical arithmetic produced the factors.

> **Reality check.** This problem-specific demonstration used a 12-qubit, perfectly noiseless simulator. It does not demonstrate general or scalable factoring. For RSA-2048, a 2019 estimate used about 20 million noisy physical qubits for eight hours; a 2025 preprint reduced the estimate to fewer than one million noisy qubits with a runtime under one week under the same stated hardware assumptions. Neither machine exists today, and the estimates are resource models rather than hardware measurements.

## Chapter 3 lab B - Grover's quadratic query advantage

_Search space N = 32 (n = 5 qubits); Grover iterations run = 4; 2048 shots._

Needle hidden at item **21** (`10101`). After 4 iterations the simulator returns **21** (`10101`) with probability **99.9%**.

| Approach | Work to find 1 of 32 |
|---|---|
| Classical (average) | ~16 guesses |
| Classical (worst case) | 32 guesses |
| Grover (ideal query model) | ~4 oracle queries (about sqrt(N)) |

**Why this is the *good* news for symmetric crypto.** Grover shrinks a brute-force of 2^k to about 2^(k/2) - a square-root, not the collapse Shor inflicts on RSA. So a key search does not vanish; it *halves in exponent*:

| Cipher | Key bits | Classical effort | Grover effort | Post-quantum margin |
|---|---|---|---|---|
| AES-128 | 128 | 2^128 | ~2^64 | thin - avoid for long-lived secrets |
| AES-256 | 256 | 2^256 | ~2^128 | 128-bit margin - the safe choice |

> **Reality check.** Aer classically simulated this circuit, so the run does not demonstrate a wall-clock quantum speedup. The security lesson comes from Grover's ideal query complexity: exhaustive key search is quadratically faster, while Shor changes the asymptotic basis of RSA and elliptic-curve security. Real cryptanalytic cost also depends on reversible-oracle construction, circuit depth, error correction, parallelization, and hardware throughput.
