#!/bin/sh
# Lab 1 — PQC algorithms & the "size tax"
# Generates classical + NIST PQC keys, performs a real encapsulation (KEM) or
# signature, and measures raw operation outputs or DER public-key files.
#
# Public, reproducible: needs OpenSSL >= 3.5 (tested on 3.5.8 and 3.6.3).
# Backs Chapter 6, Table 6-2 and Figure 6-4 (raw artifact sizes).
#
# Usage:  ./measure_pqc_sizes.sh            # prints a Markdown table
#         ./measure_pqc_sizes.sh > results.md
set -eu

OSSL="${OSSL:-openssl}"
WORK="$(mktemp -d)"
trap 'rm -f "$WORK"/*; rmdir "$WORK"' EXIT
MSG="$WORK/msg.txt"
printf 'The Quantum Moment - lab 1 message.' > "$MSG"

ver="$("$OSSL" version)"
size() { wc -c < "$1" | tr -d ' '; }        # bytes in a file
pub_der() {                                  # DER SubjectPublicKeyInfo size (bytes)
  "$OSSL" pkey -in "$1" -pubout -outform DER -out "$WORK/pub.der" 2>/dev/null
  size "$WORK/pub.der"
}

# --- signatures: sign MSG, measure produced signature -----------------------
sig_size() ( # $1=algorithm name for genpkey -> echoes public DER and signature bytes
  alg="$1" key="$WORK/k.pem" sig="$WORK/s.bin"
  "$OSSL" genpkey -algorithm "$alg" -out "$key" 2>/dev/null
  "$OSSL" pkeyutl -sign -inkey "$key" -rawin -in "$MSG" -out "$sig" 2>/dev/null
  echo "$(pub_der "$key") $(size "$sig")"
)

# --- KEM: encapsulate to the public key, measure ciphertext -----------------
kem_size() ( # $1=algorithm -> echoes "pubDER ciphertext"
  alg="$1" key="$WORK/k.pem" pub="$WORK/k.pub.pem" ct="$WORK/ct.bin" ss="$WORK/ss.bin"
  "$OSSL" genpkey -algorithm "$alg" -out "$key" 2>/dev/null
  "$OSSL" pkey -in "$key" -pubout -out "$pub" 2>/dev/null
  "$OSSL" pkeyutl -encap -inkey "$pub" -pubin -out "$ct" -secret "$ss" 2>/dev/null
  echo "$(pub_der "$key") $(size "$ct")"
)

emit_sig() {
  label="$2" family="$3"
  result=$(sig_size "$1")
  set -- $result
  printf '| %-22s | %-9s | Signature | %8s | %8s |\n' "$label" "$family" "$1" "$2"
}
emit_kem() {
  label="$2" family="$3"
  result=$(kem_size "$1")
  set -- $result
  printf '| %-22s | %-9s | KEM (ct)  | %8s | %8s |\n' "$label" "$family" "$1" "$2"
}

echo "# Lab 1 results — PQC size tax"
echo
echo "_Measured with: \`${ver}\` on $(date -u +%Y-%m-%dT%H:%M:%SZ)._"
echo
echo "Sizes are **bytes**. Public key is DER SubjectPublicKeyInfo (a few bytes of"
echo "ASN.1 framing over the raw FIPS key). Signature / KEM-ciphertext are the raw"
echo "operation outputs; a deployed protocol adds its own framing."
echo
echo "| Algorithm | Family | Job | Public key (DER) | Sig / Ciphertext |"
echo "|---|---|---|---|---|"
# classical baselines
emit_sig ED25519            "Ed25519"        "Classical"
# ECDSA P-256 (DER-encoded signature via dgst)
"$OSSL" genpkey -algorithm EC -pkeyopt group:P-256 -out "$WORK/ec.pem" 2>/dev/null
"$OSSL" dgst -sha256 -sign "$WORK/ec.pem" -out "$WORK/ec.sig" "$MSG" 2>/dev/null
printf '| %-22s | %-9s | Signature | %8s | %8s |\n' "ECDSA P-256" "Classical" "$(pub_der "$WORK/ec.pem")" "$(size "$WORK/ec.sig")"
# RSA-2048 (PKCS#1 v1.5 signature via dgst)
"$OSSL" genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$WORK/rsa.pem" 2>/dev/null
"$OSSL" dgst -sha256 -sign "$WORK/rsa.pem" -out "$WORK/rsa.sig" "$MSG" 2>/dev/null
printf '| %-22s | %-9s | Signature | %8s | %8s |\n' "RSA-2048" "Classical" "$(pub_der "$WORK/rsa.pem")" "$(size "$WORK/rsa.sig")"
# X25519 (ECDH key exchange; the peer's public key is what crosses the wire)
"$OSSL" genpkey -algorithm X25519 -out "$WORK/x.pem" 2>/dev/null
printf '| %-22s | %-9s | ECDH pk   | %8s | %8s |\n' "X25519" "Classical" "$(pub_der "$WORK/x.pem")" "32"
# PQC KEMs
emit_kem ML-KEM-512  "ML-KEM-512"  "Lattice"
emit_kem ML-KEM-768  "ML-KEM-768"  "Lattice"
emit_kem ML-KEM-1024 "ML-KEM-1024" "Lattice"
# PQC signatures
emit_sig ML-DSA-44   "ML-DSA-44"   "Lattice"
emit_sig ML-DSA-65   "ML-DSA-65"   "Lattice"
emit_sig ML-DSA-87   "ML-DSA-87"   "Lattice"
emit_sig SLH-DSA-SHA2-128s "SLH-DSA-128s" "Hash"
emit_sig SLH-DSA-SHA2-128f "SLH-DSA-128f" "Hash"
echo
echo "_Note: FN-DSA (Falcon) is not measured here. As of October 2026,"
echo "NIST lists FIPS 206 as in development rather than final._"
