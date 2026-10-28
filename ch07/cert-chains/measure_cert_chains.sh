#!/bin/sh
set -eu

lab_dir=$(mktemp -d "${TMPDIR:-/tmp}/ch07-cert-chains.XXXXXX")
trap 'rm -rf -- "$lab_dir"' EXIT HUP INT TERM

make_key() {
    alg=$1
    output=$2
    case "$alg" in
        ecdsa-p256) openssl genpkey -algorithm EC -pkeyopt group:P-256 -out "$output" >/dev/null 2>&1 ;;
        rsa-2048) openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$output" >/dev/null 2>&1 ;;
        ml-dsa-65) openssl genpkey -algorithm ML-DSA-65 -out "$output" >/dev/null 2>&1 ;;
        slh-dsa-128s) openssl genpkey -algorithm SLH-DSA-SHA2-128s -out "$output" >/dev/null 2>&1 ;;
        *) printf 'Unknown algorithm: %s\n' "$alg" >&2; exit 2 ;;
    esac
}

printf '%s\n' \
    'basicConstraints=critical,CA:TRUE,pathlen:0' \
    'keyUsage=critical,keyCertSign,cRLSign' \
    'subjectKeyIdentifier=hash' \
    'authorityKeyIdentifier=keyid,issuer' >"$lab_dir/intermediate.ext"

printf '%s\n' \
    'basicConstraints=critical,CA:FALSE' \
    'keyUsage=critical,digitalSignature' \
    'extendedKeyUsage=serverAuth' \
    'subjectAltName=DNS:example.test' \
    'subjectKeyIdentifier=hash' \
    'authorityKeyIdentifier=keyid,issuer' >"$lab_dir/leaf.ext"

printf '%-15s %10s %14s %12s\n' 'ALGORITHM' 'LEAF DER' 'INTERMEDIATE' 'CHAIN SENT'
for alg in ecdsa-p256 rsa-2048 ml-dsa-65 slh-dsa-128s; do
    work="$lab_dir/$alg"
    mkdir "$work"

    make_key "$alg" "$work/root.key"
    make_key "$alg" "$work/intermediate.key"
    make_key "$alg" "$work/leaf.key"

    openssl req -new -x509 -key "$work/root.key" -out "$work/root.crt" \
        -days 1 -subj "/CN=$alg Root" \
        -addext 'basicConstraints=critical,CA:TRUE' \
        -addext 'keyUsage=critical,keyCertSign,cRLSign' >/dev/null 2>&1

    openssl req -new -key "$work/intermediate.key" -out "$work/intermediate.csr" \
        -subj "/CN=$alg Intermediate" >/dev/null 2>&1
    openssl x509 -req -in "$work/intermediate.csr" \
        -CA "$work/root.crt" -CAkey "$work/root.key" -CAcreateserial \
        -days 1 -extfile "$lab_dir/intermediate.ext" \
        -out "$work/intermediate.crt" >/dev/null 2>&1

    openssl req -new -key "$work/leaf.key" -out "$work/leaf.csr" \
        -subj /CN=example.test >/dev/null 2>&1
    openssl x509 -req -in "$work/leaf.csr" \
        -CA "$work/intermediate.crt" -CAkey "$work/intermediate.key" -CAcreateserial \
        -days 1 -extfile "$lab_dir/leaf.ext" \
        -out "$work/leaf.crt" >/dev/null 2>&1

    openssl verify -CAfile "$work/root.crt" -untrusted "$work/intermediate.crt" \
        "$work/leaf.crt" >/dev/null
    openssl x509 -in "$work/intermediate.crt" -outform DER -out "$work/intermediate.der"
    openssl x509 -in "$work/leaf.crt" -outform DER -out "$work/leaf.der"

    leaf_bytes=$(wc -c <"$work/leaf.der" | tr -d ' ')
    intermediate_bytes=$(wc -c <"$work/intermediate.der" | tr -d ' ')
    chain_bytes=$((leaf_bytes + intermediate_bytes))
    printf '%-15s %8s B %12s B %10s B\n' \
        "$alg" "$leaf_bytes" "$intermediate_bytes" "$chain_bytes"
done

printf '\nOpenSSL: %s\n' "$(openssl version)"
printf '%s\n' 'The root certificate is excluded from CHAIN SENT.'
