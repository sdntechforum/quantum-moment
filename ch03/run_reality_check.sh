#!/usr/bin/env bash
# Lab 6 - Quantum reality check (Shor factors 15; Grover's quadratic speedup).
# Builds/uses a local Python 3.12 venv, runs both programs, writes results.md.
#
# Note: Aer uses OpenMP; we pin OMP_NUM_THREADS=1 for deterministic, portable
# runs (and to avoid shared-memory issues in restricted sandboxes).
set -o pipefail
cd "$(dirname "$0")"

PY="${PY:-python3.12}"
if [ ! -d .venv ]; then
  "$PY" -m venv .venv
  . .venv/bin/activate
  pip install --quiet --upgrade pip
  pip install --quiet -r requirements.txt
else
  . .venv/bin/activate
fi

export OMP_NUM_THREADS=1 KMP_INIT_AT_FORK=FALSE

{
  echo "# Lab 6 results - quantum reality check"
  echo
  echo "_$(python -c 'import qiskit,qiskit_aer;print("qiskit",qiskit.__version__,"| qiskit-aer",qiskit_aer.__version__)'), $(date -u +%Y-%m-%dT%H:%M:%SZ), Aer statevector simulator (ideal, noiseless)._"
  echo
  python shor15.py
  echo
  python grover.py
} | tee results.md
