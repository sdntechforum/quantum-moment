#!/usr/bin/env bash
# Chapter 3 lab - Quantum reality check (Shor factors 15; Grover's query speedup).
# Builds/uses a local Python 3.12 venv, runs both programs, writes results.md.
#
# Note: Aer uses OpenMP; we pin OMP_NUM_THREADS=1 for deterministic, portable
# runs (and to avoid shared-memory issues in restricted sandboxes).
set -euo pipefail
cd "$(dirname "$0")"

PY="${PY:-python3.12}"
if [ ! -x .venv/bin/python ]; then
  "$PY" -m venv .venv
fi
. .venv/bin/activate

if ! python -c 'import qiskit, qiskit_aer' >/dev/null 2>&1; then
  python -m pip install --quiet --upgrade pip
  python -m pip install --quiet -r requirements.txt
fi

export OMP_NUM_THREADS=1 KMP_INIT_AT_FORK=FALSE

RESULTS_TMP="$(mktemp "${TMPDIR:-/tmp}/quantum-reality-check.XXXXXX")"
trap 'rm -f "$RESULTS_TMP"' EXIT

{
  echo "# Chapter 3 lab results - quantum reality check"
  echo
  echo "_$(python -c 'import qiskit,qiskit_aer;print("qiskit",qiskit.__version__,"| qiskit-aer",qiskit_aer.__version__)'), $(date -u +%Y-%m-%dT%H:%M:%SZ), Aer statevector simulator (ideal, noiseless)._"
  echo
  python shor15.py
  echo
  python grover.py
} | tee "$RESULTS_TMP"

chmod 0644 "$RESULTS_TMP"
mv "$RESULTS_TMP" results.md
trap - EXIT
