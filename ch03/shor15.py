#!/usr/bin/env python3
"""Chapter 3 lab A - compiled Shor period finding for 15 on a simulator.

Runs the quantum period-finding core of Shor's algorithm for N = 15, a = 7 on
Qiskit's Aer simulator, reads the period from the measured phases, and finishes
the factoring classically. Prints a Markdown section.

This is a problem-specific circuit for N=15 and a=7, not a general-purpose
implementation of Shor's algorithm. It illustrates the period-finding structure
without demonstrating scalable factoring or a hardware speedup.
"""
from fractions import Fraction
from math import gcd, pi

from qiskit import QuantumCircuit, transpile
from qiskit_aer import AerSimulator

N = 15
A = 7
N_COUNT = 8  # counting qubits -> phase resolution 1/256


def c_amod15(a, power):
    """Controlled multiplication by a^power mod 15 (hand-compiled, textbook)."""
    if a not in (2, 4, 7, 8, 11, 13):
        raise ValueError("a must be one of 2,4,7,8,11,13")
    u = QuantumCircuit(4)
    for _ in range(power):
        if a in (2, 13):
            u.swap(2, 3); u.swap(1, 2); u.swap(0, 1)
        if a in (7, 8):
            u.swap(0, 1); u.swap(1, 2); u.swap(2, 3)
        if a in (4, 11):
            u.swap(1, 3); u.swap(0, 2)
        if a in (7, 11, 13):
            for q in range(4):
                u.x(q)
    gate = u.to_gate()
    gate.name = f"{a}^{power} mod 15"
    return gate.control()


def qft_dagger(n):
    """Inverse Quantum Fourier Transform on n qubits."""
    qc = QuantumCircuit(n)
    for q in range(n // 2):
        qc.swap(q, n - q - 1)
    for j in range(n):
        for m in range(j):
            qc.cp(-pi / 2 ** (j - m), m, j)
        qc.h(j)
    gate = qc.to_gate()
    gate.name = "QFT_dg"
    return gate


def build_circuit():
    qc = QuantumCircuit(N_COUNT + 4, N_COUNT)
    for q in range(N_COUNT):
        qc.h(q)
    qc.x(N_COUNT)  # work register initialised to |1>
    for q in range(N_COUNT):
        qc.append(c_amod15(A, 2 ** q), [q] + [N_COUNT + i for i in range(4)])
    qc.append(qft_dagger(N_COUNT), range(N_COUNT))
    qc.measure(range(N_COUNT), range(N_COUNT))
    return qc


def main():
    qc = build_circuit()
    sim = AerSimulator()
    tqc = transpile(qc, sim, optimization_level=1)
    counts = sim.run(tqc, shots=2048).result().get_counts()

    # Rank the measured outcomes; convert each to a phase and a candidate period.
    ranked = sorted(counts.items(), key=lambda kv: -kv[1])
    peaks = []
    for bitstr, freq in ranked:
        decimal = int(bitstr, 2)
        phase = decimal / (2 ** N_COUNT)
        frac = Fraction(phase).limit_denominator(N)
        peaks.append((bitstr, decimal, phase, frac, freq))

    # Derive factors from any even period r with a^(r/2) != -1 mod N.
    factors = set()
    period = None
    for _, _, _, frac, _ in peaks:
        r = frac.denominator
        if r % 2 != 0:
            continue
        # A measured phase can reduce to a denominator that divides the true
        # order (for example 1/2 when the order is 4). Accept r only if it is
        # actually an order candidate for this base.
        if pow(A, r, N) != 1:
            continue
        x = pow(A, r // 2, N)
        if x == N - 1:
            continue
        candidate_factors = {f for f in (gcd(x - 1, N), gcd(x + 1, N)) if 1 < f < N}
        if len(candidate_factors) == 2 and period is None:
            factors = candidate_factors
            period = r
            break

    print("## Chapter 3 lab A - compiled Shor period finding for 15")
    print()
    print(f"_N = {N}, a = {A}; {N_COUNT} counting qubits + 4 work qubits = "
          f"{qc.num_qubits} qubits; transpiled depth {tqc.depth()}, "
          f"{sum(tqc.count_ops().values())} gates; 2048 shots._")
    print()
    print("Measured phases (top outcomes) - the peaks land on multiples of 1/4, "
          "which is how the machine announces the period r = 4:")
    print()
    print("| Measured (bin) | Decimal | Phase | Nearest fraction | Shots |")
    print("|---|---|---|---|---|")
    for bitstr, decimal, phase, frac, freq in peaks[:4]:
        print(f"| `{bitstr}` | {decimal} | {phase:.3f} | "
              f"{frac.numerator}/{frac.denominator} | {freq} |")
    print()
    if period is None:
        raise RuntimeError("No valid even period producing both factors was recovered")
    r = period
    x = pow(A, r // 2, N)
    print(f"**Classical finish:** period r = {r}, so "
          f"a^(r/2) = {A}^{r // 2} = {x} (mod {N}); "
          f"gcd({x}-1, {N}) = {gcd(x - 1, N)} and gcd({x}+1, {N}) = {gcd(x + 1, N)}.")
    print()
    if factors == {3, 5}:
        print(f"**Result: 15 = 3 x 5.** The simulated period-finding circuit "
              f"identified r = 4; classical arithmetic produced the factors.")
    else:
        print(f"**Factors found:** {sorted(factors)}")
    print()
    print("> **Reality check.** This problem-specific demonstration used a "
          "12-qubit, perfectly noiseless simulator. It does not demonstrate "
          "general or scalable factoring. For RSA-2048, a 2019 estimate used "
          "about 20 million noisy physical qubits for eight hours; a 2025 "
          "preprint reduced the estimate to fewer than one million noisy qubits "
          "with a runtime under one week under the same stated hardware "
          "assumptions. Neither machine exists today, and the estimates are "
          "resource models rather than hardware measurements.")


if __name__ == "__main__":
    main()
