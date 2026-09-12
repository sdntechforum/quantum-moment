#!/usr/bin/env bash
# Lab 2 — Live post-quantum TLS 1.3 handshake
# Stands up a local TLS 1.3 server + client on OpenSSL >= 3.5 and negotiates a
# hybrid post-quantum key exchange (X25519MLKEM768). Measures the ClientHello and
# its key_share extension for classical vs PQC, to show the handshake bloat that
# collides with the internet's ~1500-byte packet assumption.
#
# Public, reproducible: OpenSSL >= 3.5 only (tested 3.6.3). No external network.
# Backs Chapter 7 (ossification, fig-7-1) / Chapter 8.
#
# Usage:  ./run_pq_tls.sh            # prints a Markdown summary
#         ./run_pq_tls.sh > results.md
set -euo pipefail

OSSL="${OSSL:-openssl}"
PORT="${PORT:-44330}"
W="$(mktemp -d)"; trap 'rm -rf "$W"; [ -n "${SPID:-}" ] && kill "$SPID" 2>/dev/null || true' EXIT
ver="$("$OSSL" version)"

# self-signed server cert (classical ECDSA P-256 — the key *exchange* is what is PQC)
"$OSSL" genpkey -algorithm EC -pkeyopt group:P-256 -out "$W/key.pem" 2>/dev/null
"$OSSL" req -x509 -key "$W/key.pem" -out "$W/cert.pem" -subj "/CN=lab2.local" -days 1 2>/dev/null

# server supports both a classical and a hybrid PQC group
"$OSSL" s_server -accept "$PORT" -cert "$W/cert.pem" -key "$W/key.pem" \
  -tls1_3 -groups X25519MLKEM768:x25519 -www >/dev/null 2>&1 &
SPID=$!
sleep 1

probe() { # $1=group label for -groups ; writes trace to $W/$1.trace ; echoes "ch ks negotiated"
  local g="$1" t="$W/$1.trace"
  echo Q | "$OSSL" s_client -connect "localhost:$PORT" -tls1_3 -groups "$g" -trace >"$t" 2>&1 || true
  local ch ks neg
  ch=$(grep -m1 'ClientHello, Length=' "$t" | sed 's/.*Length=//' | tr -d ' ')
  ks=$(awk '/ClientHello, Length=/{f=1} f&&/key_share\(51\), length=/{print $0; exit}' "$t" | sed 's/.*length=//' | tr -d ' ')
  neg=$(awk '/ServerHello, Length=/{f=1} f&&/NamedGroup:/{sub(/.*NamedGroup: /,""); sub(/ \(.*/,""); print; exit}' "$t")
  cp "$t" "./trace-$1.txt"
  echo "$ch $ks $neg"
}

read -r ch_c ks_c neg_c <<<"$(probe x25519)"
read -r ch_p ks_p neg_p <<<"$(probe X25519MLKEM768)"
ratio=$(awk -v a="$ch_p" -v b="$ch_c" 'BEGIN{printf "%.1f", a/b}')

echo "# Lab 2 results — post-quantum TLS 1.3 handshake"
echo
echo "_Measured with: \`${ver}\` on $(date -u +%Y-%m-%dT%H:%M:%SZ), local loopback._"
echo
echo "TLS 1.3 handshake, self-signed ECDSA P-256 server cert; only the **key exchange**"
echo "differs. Sizes are **bytes** parsed from \`openssl s_client -trace\`."
echo
echo "| Client offered | Negotiated group | ClientHello | key_share ext |"
echo "|---|---|---|---|"
printf '| %-16s | %-18s | %11s | %13s |\n' "x25519 (classical)" "$neg_c" "$ch_c" "$ks_c"
printf '| %-16s | %-18s | %11s | %13s |\n' "X25519MLKEM768"     "$neg_p" "$ch_p" "$ks_p"
echo
echo "**Takeaways**"
echo "- The hybrid key_share balloons from **${ks_c} B** (classical) to **${ks_p} B** (PQC) —"
echo "  the ML-KEM-768 encapsulation key riding alongside the 32-byte X25519 share."
echo "- The PQC ClientHello (**${ch_p} B**) is ~${ratio}x the classical one (**${ch_c} B**)."
echo "- A real browser ClientHello carries far more (SNI, ALPN, GREASE, more sig-algs);"
echo "  adding a PQC key_share pushes it past the ~1500-byte Ethernet MTU, so it spans"
echo "  **two packets** — exactly the assumption old middleboxes broke on (see ch07)."
echo
echo "_Full handshake traces: \`trace-x25519.txt\`, \`trace-X25519MLKEM768.txt\`._"
