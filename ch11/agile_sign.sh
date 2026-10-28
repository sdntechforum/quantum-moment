#!/bin/sh
set -eu

if [ "$#" -ne 3 ]; then
  echo "usage: $0 POLICY_FILE INPUT_FILE OUTPUT_DIRECTORY" >&2
  exit 64
fi

policy_file=$1
input_file=$2
output_dir=$3

# Treat policy as data. Do not source it: a sourced file is executable shell code.
line_count=$(wc -l < "$policy_file" | tr -d ' ')
[ "$line_count" -eq 1 ] || {
  echo "policy must contain exactly one line" >&2
  exit 65
}

policy_line=$(sed -n '1p' "$policy_file")
case "$policy_line" in
  SIG_ALG=ED25519) sig_alg=ED25519 ;;
  SIG_ALG=ML-DSA-65) sig_alg=ML-DSA-65 ;;
  *)
    echo "policy rejected: algorithm is absent from the allowlist" >&2
    exit 66
    ;;
esac

mkdir -p "$output_dir"
private_key=/tmp/agile-private.pem
trap 'rm -f "$private_key"' EXIT HUP INT TERM
openssl genpkey -algorithm "$sig_alg" -out "$private_key"
openssl pkey -in "$private_key" -pubout -out "$output_dir/public.pem"
openssl pkeyutl -sign -inkey "$private_key" -rawin \
  -in "$input_file" -out "$output_dir/signature.bin"
openssl pkeyutl -verify -pubin -inkey "$output_dir/public.pem" -rawin \
  -in "$input_file" -sigfile "$output_dir/signature.bin" >/dev/null

signature_bytes=$(wc -c < "$output_dir/signature.bin" | tr -d ' ')
public_key_bytes=$(wc -c < "$output_dir/public.pem" | tr -d ' ')
private_key_bytes=$(wc -c < "$private_key" | tr -d ' ')
public_key_sha256=$(openssl dgst -sha256 "$output_dir/public.pem" | sed 's/^.*= //')
input_sha256=$(openssl dgst -sha256 "$input_file" | sed 's/^.*= //')

cat > "$output_dir/evidence.txt" <<EOF
mode=agile
algorithm=$sig_alg
verification=PASS
signature_bytes=$signature_bytes
public_key_bytes=$public_key_bytes
private_key_bytes=$private_key_bytes
public_key_sha256=$public_key_sha256
input_sha256=$input_sha256
openssl_version=$(openssl version)
EOF

cat "$output_dir/evidence.txt"
