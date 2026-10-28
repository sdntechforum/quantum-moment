#!/usr/bin/env python3
"""Chapter 3 lab B - Grover search on an ideal simulator.

Runs Grover's algorithm on a small unstructured search (find one marked item
among N = 2^n) on Aer, illustrating the quadratic query advantage: ~sqrt(N)
oracle calls instead of ~N/2 classical queries. This is not a wall-clock speed
test because Aer runs the quantum circuit on a classical computer. It then
extrapolates to cryptography:
Grover turns a 2^k brute-force into ~2^(k/2), which is why AES keys are simply
*doubled* (AES-256 keeps a 128-bit safety margin) rather than abandoned the way
RSA is under Shor. Prints a Markdown section.
"""
from math import floor, pi, sqrt

from qiskit import QuantumCircuit, transpile
from qiskit_aer import AerSimulator

N_QUBITS = 5      # search space of 32 items
MARKED = 21       # the "needle" (arbitrary fixed target for reproducibility)


def phase_oracle(n, marked):
    qc = QuantumCircuit(n, name="oracle")
    bits = format(marked, f"0{n}b")
    for i, b in enumerate(reversed(bits)):
        if b == "0":
            qc.x(i)
    qc.h(n - 1)
    qc.mcx(list(range(n - 1)), n - 1)
    qc.h(n - 1)
    for i, b in enumerate(reversed(bits)):
        if b == "0":
            qc.x(i)
    return qc.to_gate()


def diffuser(n):
    qc = QuantumCircuit(n, name="diffuser")
    qc.h(range(n))
    qc.x(range(n))
    qc.h(n - 1)
    qc.mcx(list(range(n - 1)), n - 1)
    qc.h(n - 1)
    qc.x(range(n))
    qc.h(range(n))
    return qc.to_gate()


def build_circuit(n, marked, iterations):
    qc = QuantumCircuit(n, n)
    qc.h(range(n))
    oracle = phase_oracle(n, marked)
    diff = diffuser(n)
    for _ in range(iterations):
        qc.append(oracle, range(n))
        qc.append(diff, range(n))
    qc.measure(range(n), range(n))
    return qc


def main():
    n = N_QUBITS
    size = 2 ** n
    iterations = max(1, floor((pi / 4) * sqrt(size)))

    qc = build_circuit(n, MARKED, iterations)
    sim = AerSimulator()
    tqc = transpile(qc, sim, optimization_level=1)
    counts = sim.run(tqc, shots=2048).result().get_counts()

    ranked = sorted(counts.items(), key=lambda kv: -kv[1])
    top_bits, top_freq = ranked[0]
    top_val = int(top_bits, 2)
    prob = top_freq / 2048

    print("## Chapter 3 lab B - Grover's quadratic query advantage")
    print()
    print(f"_Search space N = {size} (n = {n} qubits); Grover iterations run = "
          f"{iterations}; 2048 shots._")
    print()
    print(f"Needle hidden at item **{MARKED}** (`{format(MARKED, f'0{n}b')}`). "
          f"After {iterations} iterations the simulator returns "
          f"**{top_val}** (`{top_bits}`) with probability **{prob:.1%}**.")
    print()
    print("| Approach | Work to find 1 of "
          f"{size} | ")
    print("|---|---|")
    print(f"| Classical (average) | ~{size // 2} guesses |")
    print(f"| Classical (worst case) | {size} guesses |")
    print(f"| Grover (ideal query model) | ~{iterations} oracle queries (about sqrt(N)) |")
    print()
    print("**Why this is the *good* news for symmetric crypto.** Grover shrinks a "
          "brute-force of 2^k to about 2^(k/2) - a square-root, not the collapse "
          "Shor inflicts on RSA. So a key search does not vanish; it *halves in "
          "exponent*:")
    print()
    print("| Cipher | Key bits | Classical effort | Grover effort | Post-quantum margin |")
    print("|---|---|---|---|---|")
    print("| AES-128 | 128 | 2^128 | ~2^64 | thin - avoid for long-lived secrets |")
    print("| AES-256 | 256 | 2^256 | ~2^128 | 128-bit margin - the safe choice |")
    print()
    print("> **Reality check.** Aer classically simulated this circuit, so the run "
          "does not demonstrate a wall-clock quantum speedup. The security lesson "
          "comes from Grover's ideal query complexity: exhaustive key search is "
          "quadratically faster, while Shor changes the asymptotic basis of RSA "
          "and elliptic-curve security. Real cryptanalytic cost also depends on "
          "reversible-oracle construction, circuit depth, error correction, "
          "parallelization, and hardware throughput.")


if __name__ == "__main__":
    main()
