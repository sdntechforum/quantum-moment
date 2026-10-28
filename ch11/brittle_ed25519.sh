#!/bin/sh
set -eu

input_file=$1
output_dir=$2
sig_alg=ED25519

mkdir -p "$output_dir"
private_key=/tmp/brittle-ed25519-private.pem
trap 'rm -f "$private_key"' EXIT HUP INT TERM
openssl genpkey -algorithm "$sig_alg" -out "$private_key"
openssl pkey -in "$private_key" -pubout -out "$output_dir/public.pem"
openssl pkeyutl -sign -inkey "$private_key" -rawin \
  -in "$input_file" -out "$output_dir/signature.bin"
openssl pkeyutl -verify -pubin -inkey "$output_dir/public.pem" -rawin \
  -in "$input_file" -sigfile "$output_dir/signature.bin" >/dev/null

printf 'mode=brittle\nalgorithm=%s\nverification=PASS\nsignature_bytes=%s\n' \
  "$sig_alg" "$(wc -c < "$output_dir/signature.bin" | tr -d ' ')" \
  > "$output_dir/evidence.txt"
cat "$output_dir/evidence.txt"
