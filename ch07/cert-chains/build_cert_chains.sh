#!/usr/bin/env bash
# Lab 1b - Certificate-chain "size explosion": classical vs PQC X.509 chains.
#
# For each signature algorithm we build a realistic 3-tier PKI
#   Root CA (self-signed) -> Intermediate CA -> leaf/server cert
# and measure the DER bytes of each certificate plus the two numbers that
# actually matter on a TLS connection:
#   * chain-on-wire = intermediate + leaf   (what a server sends; the root is
#                                            already in the client's trust store)
#   * full chain    = root + intermediate + leaf
#
# A PQC certificate is fat twice over: it carries a large *public key* AND is
# signed with a large *signature* by its issuer - and the chain multiplies both.
#
# Public, reproducible: needs only OpenSSL >= 3.5 (tested on 3.6.3).
# Backs Chapter 6 (the "size tax") and Chapter 7 (PKI / authentication bloat).
#
# Usage:  ./build_cert_chains.sh            # prints a Markdown report
#         ./build_cert_chains.sh > results.md
set -euo pipefail

OSSL="${OSSL:-openssl}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ver="$("$OSSL" version)"

size() { wc -c < "$1" | tr -d ' '; }
der()  { "$OSSL" x509 -in "$1" -outform DER -out "$2" 2>/dev/null; size "$2"; }

# extension files (identical across algorithms, so comparisons are apples-to-apples)
cat > "$WORK/ca.ext" <<'EOF'
basicConstraints=critical,CA:TRUE
keyUsage=critical,keyCertSign,cRLSign
EOF
cat > "$WORK/leaf.ext" <<'EOF'
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=serverAuth
subjectAltName=DNS:vault.example.com
EOF

genkey() { # $1=dir  $2..=genpkey args
  local out="$1"; shift
  "$OSSL" genpkey "$@" -out "$out" 2>/dev/null
}

# build_chain <label> <genpkey-args...>  -> echoes a Markdown table row
build_chain() {
  local label="$1"; shift
  local d="$WORK/${label// /_}"; mkdir -p "$d"

  # keys (all three tiers use the same algorithm)
  genkey "$d/root.key" "$@"
  genkey "$d/int.key"  "$@"
  genkey "$d/leaf.key" "$@"

  # root: self-signed CA
  "$OSSL" req -x509 -new -key "$d/root.key" -days 3650 \
    -subj "/C=US/O=Acme/CN=Acme $label Root CA" \
    -addext "basicConstraints=critical,CA:TRUE" \
    -addext "keyUsage=critical,keyCertSign,cRLSign" \
    -out "$d/root.crt" 2>/dev/null

  # intermediate: CSR signed by root
  "$OSSL" req -new -key "$d/int.key" \
    -subj "/C=US/O=Acme/CN=Acme $label Intermediate CA" -out "$d/int.csr" 2>/dev/null
  "$OSSL" x509 -req -in "$d/int.csr" -CA "$d/root.crt" -CAkey "$d/root.key" \
    -CAcreateserial -days 1825 -extfile "$WORK/ca.ext" -out "$d/int.crt" 2>/dev/null

  # leaf: CSR signed by intermediate
  "$OSSL" req -new -key "$d/leaf.key" \
    -subj "/C=US/O=Acme/CN=vault.example.com" -out "$d/leaf.csr" 2>/dev/null
  "$OSSL" x509 -req -in "$d/leaf.csr" -CA "$d/int.crt" -CAkey "$d/int.key" \
    -CAcreateserial -days 397 -extfile "$WORK/leaf.ext" -out "$d/leaf.crt" 2>/dev/null

  local r i l wire full
  r=$(der "$d/root.crt" "$d/root.der")
  i=$(der "$d/int.crt"  "$d/int.der")
  l=$(der "$d/leaf.crt" "$d/leaf.der")
  wire=$(( i + l ))
  full=$(( r + i + l ))
  printf '| %-14s | %6s | %8s | %6s | %14s | %11s |\n' \
    "$label" "$r" "$i" "$l" "$wire" "$full"
}

echo "# Lab 1b results - certificate-chain size explosion"
echo
echo "_Measured with: \`${ver}\` on $(date -u +%Y-%m-%dT%H:%M:%SZ)._"
echo
echo "Each row is a full **Root CA -> Intermediate CA -> leaf** chain built with a"
echo "single signature algorithm. Sizes are **DER bytes** (what actually crosses the"
echo "wire). **Chain-on-wire** = intermediate + leaf (a TLS server does not send the"
echo "root); **full chain** = all three."
echo
echo "| Algorithm | Root | Intermed | Leaf | Chain-on-wire | Full chain |"
echo "|---|--:|--:|--:|--:|--:|"
build_chain "ECDSA P-256" -algorithm EC  -pkeyopt group:P-256
build_chain "RSA-2048"    -algorithm RSA -pkeyopt rsa_keygen_bits:2048
build_chain "ML-DSA-44"   -algorithm ML-DSA-44
build_chain "ML-DSA-65"   -algorithm ML-DSA-65
build_chain "ML-DSA-87"   -algorithm ML-DSA-87
build_chain "SLH-DSA-128s" -algorithm SLH-DSA-SHA2-128s

echo
echo "_Note: leaf/intermediate carry SAN + key-usage + basic-constraints extensions"
echo "(identical across algorithms), so the deltas are pure algorithm cost. FN-DSA"
echo "(Falcon, ~666 B sigs) is not in OpenSSL 3.6, so it is omitted here._"
