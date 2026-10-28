#!/bin/sh
set -eu

VULNERABLE_COMMIT=b628ba78711bc28327dc7d2d5c074a00f061884e
FIXED_COMMIT=9b8d30698a3e7449aeb34e62339d4176f11e3c6c
SOURCE_DIR=/sources
OUTPUT_DIR=/results
WORK_DIR=$(mktemp -d /tmp/quantum-moment-ch10.XXXXXX)

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT INT TERM

mkdir -p "$OUTPUT_DIR"
test -f "$SOURCE_DIR/vulnerable/ref/poly.c"
test -f "$SOURCE_DIR/fixed/ref/poly.c"

{
    echo "Chapter 10 Clangover binary-inspection lab"
    echo "repository=https://github.com/pq-crystals/kyber.git"
    echo "vulnerable_commit=$VULNERABLE_COMMIT"
    echo "fixed_commit=$FIXED_COMMIT"
    echo "architecture=$(uname -m)"
    clang --version | sed -n '1p'
    llvm-objdump --version | sed -n '1p'
} > "$OUTPUT_DIR/environment.txt"

compile_and_extract() {
    label=$1
    source_root="$SOURCE_DIR/$label"

    clang \
        --target=x86_64-linux-gnu \
        -DKYBER_K=2 \
        -Os \
        -I"$source_root/ref" \
        -c "$source_root/ref/poly.c" \
        -o "$WORK_DIR/$label.o"

    llvm-objdump \
        -d \
        --no-show-raw-insn \
        --x86-asm-syntax=intel \
        "$WORK_DIR/$label.o" > "$OUTPUT_DIR/$label-full-disassembly.txt"

    sed -n '/<.*poly_frommsg>:/,/^$/p' \
        "$OUTPUT_DIR/$label-full-disassembly.txt" \
        > "$OUTPUT_DIR/$label-poly_frommsg.txt"

    test -s "$OUTPUT_DIR/$label-poly_frommsg.txt"
}

compile_and_extract vulnerable
compile_and_extract fixed

if ! grep -Eq '[[:space:]]bt[[:space:]]' "$OUTPUT_DIR/vulnerable-poly_frommsg.txt"; then
    echo "FAIL: vulnerable build did not contain the expected bt instruction" >&2
    exit 1
fi

if ! grep -Eq '[[:space:]]jae[[:space:]]' "$OUTPUT_DIR/vulnerable-poly_frommsg.txt"; then
    echo "FAIL: vulnerable build did not contain the expected conditional branch" >&2
    exit 1
fi

if grep -Eq '[[:space:]]jae[[:space:]]' "$OUTPUT_DIR/fixed-poly_frommsg.txt"; then
    echo "FAIL: fixed poly_frommsg still contained the vulnerable jae pattern" >&2
    exit 1
fi

{
    echo "PASS"
    echo "The vulnerable object contains the expected bt/jae sequence."
    echo "The fixed object does not contain that jae pattern in poly_frommsg."
    echo "This lab inspects generated code; it does not attempt key recovery."
} > "$OUTPUT_DIR/verification.txt"

cat "$OUTPUT_DIR/environment.txt"
cat "$OUTPUT_DIR/verification.txt"
