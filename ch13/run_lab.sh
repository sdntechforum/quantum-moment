#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$SCRIPT_DIR/sample-app"
OUTPUT_DIR="$SCRIPT_DIR/output"

# The legacy folder name is retained for repository compatibility. This lab
# supports canonical Chapter 16 in the manuscript.
CBOM_IMAGE="ghcr.io/cbomkit/cbomkit-action@sha256:7dfc905c614549fdb630d41a33b34a039af7f60c982501c6d74dfc63ef700512"
VALIDATOR_IMAGE="cyclonedx/cyclonedx-cli@sha256:252c2e26f468c25fea1e63ecde1bc3198ad6e9dbb57f5ed3236bddcb2281b3a7"

command -v docker >/dev/null 2>&1 || {
  echo "docker is required" >&2
  exit 1
}
command -v python3 >/dev/null 2>&1 || {
  echo "python3 is required for the evidence check" >&2
  exit 1
}

mkdir -p "$OUTPUT_DIR"

{
  printf 'UTC run date: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf 'Docker server version: %s\n' "$(docker version --format '{{.Server.Version}}')"
  printf 'CBOMkit image reference: %s\n' "$CBOM_IMAGE"
  printf 'CycloneDX CLI image reference: %s\n' "$VALIDATOR_IMAGE"
  printf 'Sample Python file SHA-256 values:\n'
  (cd "$SAMPLE_DIR" && sha256sum vault/*.py)
} > "$OUTPUT_DIR/environment.txt"

echo "Generating a CycloneDX 1.6 CBOM from the sample source"
docker run --rm \
  --network none \
  --read-only \
  --tmpfs /tmp:rw,nosuid,nodev,size=64m \
  --user "$(id -u):$(id -g)" \
  -w /src \
  -e GITHUB_WORKSPACE=/src \
  -e GITHUB_OUTPUT=/out/github-output.txt \
  -e CBOMKIT_OUTPUT_DIR=/out \
  -e CBOMKIT_LANGUAGES=python \
  -e CBOMKIT_GENERATE_MODULE_CBOMS=true \
  -e CBOMKIT_WRITE_EMTPY_CBOMS=false \
  -v "$SAMPLE_DIR:/src:ro" \
  -v "$OUTPUT_DIR:/out" \
  "$CBOM_IMAGE"

echo "Validating the generated document against CycloneDX 1.6"
docker run --rm \
  --network none \
  --read-only \
  --tmpfs /tmp:rw,nosuid,nodev,size=32m \
  -v "$OUTPUT_DIR:/work:ro" \
  "$VALIDATOR_IMAGE" \
  validate \
  --input-file /work/cbom.json \
  --input-format json \
  --input-version v1_6 \
  --fail-on-errors

echo "Checking detections and deliberate coverage gaps"
python3 "$SCRIPT_DIR/inspect_cbom.py" "$OUTPUT_DIR/cbom.json" | tee "$OUTPUT_DIR/summary.txt"

{
  printf 'CBOMkit resolved image ID: %s\n' "$(docker image inspect --format '{{.Id}}' "$CBOM_IMAGE")"
  printf 'CycloneDX CLI resolved image ID: %s\n' "$(docker image inspect --format '{{.Id}}' "$VALIDATOR_IMAGE")"
} >> "$OUTPUT_DIR/environment.txt"
