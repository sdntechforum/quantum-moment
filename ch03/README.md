# Chapter 3 lab - Quantum reality check (Shor + Grover on a simulator)

Backs **Chapter 3 ("Is it real?")** and reinforces **Chapter 4**. Two small,
honest demonstrations that separate what quantum algorithms *actually do today*
from the headlines:

- **`shor15.py`** - a problem-specific, compiled demonstration of Shor's
  period-finding routine for **15 = 3 x 5** on an ideal simulator, followed by
  classical post-processing. It is not a general-purpose factoring program.
- **`grover.py`** - Grover's search finding one item among 32 in ~sqrt(N)
  oracle queries, then extrapolating to why symmetric keys generally **double**
  (AES-256) while RSA/ECC must be **replaced**.

## Requirements
- Python 3.12 (Qiskit wheels; the repo default 3.14 has no Aer wheel yet).
- `qiskit==2.5.2`, `qiskit-aer==0.17.2` (see `requirements.txt`).

## Run
```
./run_reality_check.sh          # creates .venv on first run, writes results.md
```
Or manually:
```
python3.12 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
OMP_NUM_THREADS=1 python shor15.py
OMP_NUM_THREADS=1 python grover.py
```

## What we measured
- **Shor(15):** measured phases peak at 0, 1/4, 1/2, 3/4 -> period r = 4 ->
  gcd(7^2 +/- 1, 15) = {3, 5}. Cost: **12 qubits, ideal/noiseless**, to factor 15.
- **Grover(32):** needle recovered with probability close to 1 in four ideal
  Grover iterations. The comparison with ~16 classical guesses is a query-model
  comparison, not a wall-clock speed test on this classical simulator.
- Full captured output in `results.md`.

## The point (for the manuscript)
Both algorithms are genuine, and both are in the book's argument - but they cut
in opposite directions. Shor gives a polynomial-time factoring algorithm
(catastrophic for RSA once sufficiently capable fault-tolerant hardware exists),
while Grover gives a quadratic query speedup. The 12-qubit ideal demonstration
must not be compared directly with one universal RSA qubit count: published
resource estimates depend on the error-correction code, gate error, cycle time,
decoder, architecture, runtime target, and algorithmic assumptions. Under a
shared set of assumptions, a widely cited 2019 estimate used about 20 million
noisy qubits for eight hours, while a 2025 preprint reduced the estimate to fewer
than one million noisy qubits with a runtime under one week.

## Guardrail
Public tooling only (Qiskit/Aer); ideal simulator; no hardware, no accounts,
no secrets. One-off educational lab; not part of the Apparatus.
