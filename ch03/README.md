# Lab 6 - Quantum reality check (Shor + Grover on a simulator)

Backs **Chapter 3 ("Is it real?")** and reinforces **Chapter 4**. Two small,
honest demonstrations that separate what quantum algorithms *actually do today*
from the headlines:

- **`shor15.py`** - Shor's algorithm factoring **15 = 3 x 5** via quantum
  period-finding on an ideal simulator, then finishing classically. Shows the
  algorithm works *and* how far 15 is from RSA-2048.
- **`grover.py`** - Grover's search finding one item among 32 in ~sqrt(N)
  iterations, then extrapolating to why symmetric keys only need to **double**
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
- **Grover(32):** needle recovered with ~99.9% probability in 4 iterations vs
  ~16 classical guesses on average.
- Full captured output in `results.md`.

## The point (for the manuscript)
Both algorithms are genuine, and both are in the book's argument - but they cut
in opposite directions. Shor is *exponential* (catastrophe for public-key, once
the hardware exists), while Grover is only *quadratic* (an inconvenience for
symmetric crypto, fixed by bigger keys). The 12-qubit-to-factor-15 vs
~20-million-qubit-to-break-RSA gap is the concrete version of Chapter 3's
"real, but not imminent."

## Guardrail
Public tooling only (Qiskit/Aer); ideal simulator; no hardware, no accounts,
no secrets. One-off educational lab; not part of the Apparatus.
