#!/usr/bin/env python3
"""Lab 6a - Shor's algorithm factoring 15 on a simulator (reality check for ch03).

Runs the quantum period-finding core of Shor's algorithm for N = 15, a = 7 on
Qiskit's Aer simulator, reads the period from the measured phases, and finishes
the factoring classically. Prints a Markdown section.

The point is honesty about scale: this works, but it takes a 12-qubit,
ideal (noiseless) simulator to factor the number 15. RSA-2048 is a 617-digit
number; credible estimates put its cost at ~20 million noisy physical qubits
running for hours - hardware that does not exist. "It works on 15" and "it
threatens RSA" are separated by that gap, and this lab makes the gap concrete.
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
        x = pow(A, r // 2, N)
        if x == N - 1:
            continue
        f1, f2 = gcd(x - 1, N), gcd(x + 1, N)
        for f in (f1, f2):
            if 1 < f < N:
                factors.add(f)
        if factors and period is None:
            period = r

    print("## Lab 6a - Shor's algorithm factors 15 (ideal simulator)")
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
    r = period or 4
    x = pow(A, r // 2, N)
    print(f"**Classical finish:** period r = {r}, so "
          f"a^(r/2) = {A}^{r // 2} = {x} (mod {N}); "
          f"gcd({x}-1, {N}) = {gcd(x - 1, N)} and gcd({x}+1, {N}) = {gcd(x + 1, N)}.")
    print()
    if factors == {3, 5}:
        print(f"**Result: 15 = 3 x 5.** The quantum part found the period; the "
              f"factors fall out with grade-school arithmetic.")
    else:
        print(f"**Factors found:** {sorted(factors)}")
    print()
    print("> **Reality check.** Factoring the number 15 took a 12-qubit, perfectly "
          "noiseless simulator. RSA-2048 is a 617-digit number; the most-cited "
          "estimate puts its cost near 20 million *noisy* physical qubits for "
          "several hours. The algorithm is real and the threat is real - but the "
          "distance between this demonstration and a broken RSA key is the whole "
          "story of Chapter 3.")


if __name__ == "__main__":
    main()
