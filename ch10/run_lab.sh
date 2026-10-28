#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
IMAGE=quantum-moment-ch10-clangover:clang18
RESULTS_DIR="$SCRIPT_DIR/results"
REPOSITORY=https://github.com/pq-crystals/kyber.git
VULNERABLE_COMMIT=b628ba78711bc28327dc7d2d5c074a00f061884e
FIXED_COMMIT=9b8d30698a3e7449aeb34e62339d4176f11e3c6c
WORK_DIR=$(mktemp -d /tmp/quantum-moment-ch10-source.XXXXXX)

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT INT TERM

mkdir -p "$RESULTS_DIR"
git clone --quiet --no-checkout "$REPOSITORY" "$WORK_DIR/kyber"
mkdir -p "$WORK_DIR/sources/vulnerable" "$WORK_DIR/sources/fixed"
git -C "$WORK_DIR/kyber" archive "$VULNERABLE_COMMIT" \
    | tar -x -C "$WORK_DIR/sources/vulnerable"
git -C "$WORK_DIR/kyber" archive "$FIXED_COMMIT" \
    | tar -x -C "$WORK_DIR/sources/fixed"

docker build --platform linux/amd64 -t "$IMAGE" "$SCRIPT_DIR"
docker run --rm \
    --platform linux/amd64 \
    --user "$(id -u):$(id -g)" \
    --network none \
    --read-only \
    --tmpfs /tmp:rw,noexec,nosuid,size=256m \
    --cap-drop ALL \
    --security-opt no-new-privileges \
    --mount "type=bind,src=$WORK_DIR/sources,dst=/sources,readonly" \
    --mount "type=bind,src=$RESULTS_DIR,dst=/results" \
    "$IMAGE"

echo "Results: $RESULTS_DIR"
