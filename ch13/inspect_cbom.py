#!/usr/bin/env python3
"""Check the bounded evidence produced by the Chapter 16 CBOM lab."""

from __future__ import annotations

import json
from pathlib import Path
import sys


REQUIRED_ALGORITHMS = {
    "RSA-2048",
    "EC-secp256r1",
    "HMAC-SHA-256",
    "MD5",
    "SHA-1",
    "AES-GCM",
    "AES-CBC",
    "Fernet",
}


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: inspect_cbom.py OUTPUT/cbom.json")

    path = Path(sys.argv[1])
    document = json.loads(path.read_text(encoding="utf-8"))
    if document.get("bomFormat") != "CycloneDX":
        fail("bomFormat is not CycloneDX")
    if document.get("specVersion") != "1.6":
        fail("expected CycloneDX specVersion 1.6")

    components = document.get("components", [])
    names = {component.get("name", "") for component in components}
    missing = sorted(REQUIRED_ALGORITHMS - names)
    if missing:
        fail("expected detections are missing: " + ", ".join(missing))

    occurrences = []
    for component in components:
        for occurrence in component.get("evidence", {}).get("occurrences", []):
            occurrences.append(
                (
                    component.get("name", ""),
                    occurrence.get("location", ""),
                    occurrence.get("line"),
                )
            )

    locations = {location for _, location, _ in occurrences}
    if "vault/exchange.py" in locations:
        fail("expected the current source scanner to miss exchange.py, but it was reported")

    raw = path.read_text(encoding="utf-8")
    if "hashlib" in raw or "cache_key" in raw or "dedup_id" in raw:
        fail("expected the current pyca-focused scan to miss stdlib hashlib calls")

    print("PASS: valid CycloneDX 1.6 document")
    print(f"PASS: {len(components)} components and {len(occurrences)} evidence occurrences")
    print("PASS: expected source detections: " + ", ".join(sorted(REQUIRED_ALGORITHMS)))
    print("EXPECTED GAP: finite-field DH and ECDH uses in vault/exchange.py were not reported")
    print("EXPECTED GAP: stdlib hashlib MD5 and SHA-1 uses were not reported")
    print("INTERPRETATION: absence from this CBOM is not evidence of absence from the codebase")


if __name__ == "__main__":
    main()
