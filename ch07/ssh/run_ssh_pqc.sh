#!/usr/bin/env bash
# Lab 7 — Post-quantum key exchange in SSH
# Stands up an ephemeral OpenSSH server on loopback and connects to it, capturing
# the *negotiated* key-exchange algorithm for four cases: the client's DEFAULT,
# forced classical (curve25519), and two post-quantum hybrids (ML-KEM-768 and
# Streamlined NTRU Prime). The key exchange completes before authentication, so
# we disable auth and still capture the KEX from `ssh -vv`.
#
# Point of the lab: on current OpenSSH (>=9.9 / here 10.x) the *default* SSH key
# exchange is already post-quantum (mlkem768x25519-sha256). The migration the
# book describes for TLS has, quietly, already shipped in your SSH client.
#
# Public, reproducible: needs only the system OpenSSH (client + sshd). No network
# beyond loopback. Backs Chapter 7 (rebuilding the plumbing) / Chapter 8.
#
# Usage:  ./run_ssh_pqc.sh            # prints a Markdown summary
#         ./run_ssh_pqc.sh > results.md
set -o pipefail

SSHD="${SSHD:-/usr/sbin/sshd}"
PORT="${PORT:-2222}"
OUT="$(cd "$(dirname "$0")" && pwd)"      # where to drop captured logs
W="$(mktemp -d)"
trap 'pkill -f "sshd -d -p $PORT" 2>/dev/null || true; rm -rf "$W"' EXIT

ver_client="$(ssh -V 2>&1)"
ver_server="$("$SSHD" -V 2>&1 | head -1 || true)"
ssh-keygen -t ed25519 -f "$W/hostkey" -N '' -q

# probe <label> <kex-or-empty>  -> echoes the negotiated kex; writes client log
probe() {
  local label="$1" kex="${2:-}" sopt=() copt=()
  if [ -n "$kex" ]; then sopt=(-o "KexAlgorithms=$kex"); copt=(-o "KexAlgorithms=$kex"); fi
  pkill -f "sshd -d -p $PORT" 2>/dev/null || true; sleep 0.3
  "$SSHD" -d -p "$PORT" -h "$W/hostkey" \
    -o PasswordAuthentication=no -o PubkeyAuthentication=no \
    -o KbdInteractiveAuthentication=no ${sopt[@]+"${sopt[@]}"} \
    >"$W/sshd-$label.log" 2>&1 &
  sleep 1
  ssh -vv -p "$PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o PreferredAuthentications=none -o BatchMode=yes ${copt[@]+"${copt[@]}"} \
    nobody@127.0.0.1 true 2>"$OUT/client-$label.log" || true
  pkill -f "sshd -d -p $PORT" 2>/dev/null || true
  grep -m1 'kex: algorithm:' "$OUT/client-$label.log" | sed 's/.*algorithm: //' | tr -d '\r'
}

neg_default=$(probe default "")
neg_classic=$(probe classical "curve25519-sha256")
neg_mlkem=$(probe mlkem "mlkem768x25519-sha256")
neg_ntru=$(probe ntruprime "sntrup761x25519-sha512@openssh.com")

# the client's default proposal (what algorithms it advertises, in order)
offer=$(grep -m1 'KEX algorithms:' "$OUT/client-default.log" 2>/dev/null | sed 's/.*algorithms: //' | tr -d '\r' || true)
# does the default proposal include PQC families?
pqc_offered=no
case "$offer" in *mlkem*|*sntrup*) pqc_offered=yes;; esac
# was the *negotiated* default a PQC hybrid?
default_is_pqc=no
case "$neg_default" in *mlkem*|*sntrup*) default_is_pqc=yes;; esac

echo "# Lab 7 results — post-quantum key exchange in SSH"
echo
echo "_Client: \`${ver_client}\`  Server: \`${ver_server}\`_"
echo "_$(date -u +%Y-%m-%dT%H:%M:%SZ), local loopback (ephemeral sshd), auth disabled_"
echo "_(KEX completes before authentication, so the negotiated algorithm is captured even with no login.)_"
echo
echo "| Client asked for | Negotiated key exchange |"
echo "|---|---|"
printf '| %-28s | %s |\n' "*(default, no override)*" "\`${neg_default}\`"
printf '| %-28s | %s |\n' "curve25519-sha256 (classical)" "\`${neg_classic}\`"
printf '| %-28s | %s |\n' "mlkem768x25519-sha256 (PQC)" "\`${neg_mlkem}\`"
printf '| %-28s | %s |\n' "sntrup761x25519 (PQC)" "\`${neg_ntru}\`"
echo
echo "**Takeaways**"
if [ "$default_is_pqc" = yes ]; then
  echo "- The **default** SSH key exchange negotiated here is **\`${neg_default}\`** — a"
  echo "  post-quantum hybrid, chosen with no flags and no opt-in. The migration the"
  echo "  book describes for TLS has quietly already shipped as the SSH default."
else
  echo "- The **default** negotiated here is **\`${neg_default}\`** — still *classical*."
  echo "  Post-quantum KEX is present but not first in this build's preference order,"
  echo "  so turning it on is a one-line \`KexAlgorithms\` setting rather than an upgrade."
fi
if [ "$pqc_offered" = yes ]; then
  echo "- Even so, the client already **advertises** post-quantum KEX in its default"
  echo "  proposal (ML-KEM and/or NTRU-Prime are in the list below) — the plumbing is"
  echo "  in place, waiting to be preferred."
fi
echo "- Explicitly asking for **\`mlkem768x25519-sha256\`** negotiates cleanly"
echo "  (**\`${neg_mlkem}\`**): a real ML-KEM-768 + X25519 hybrid key exchange, the same"
echo "  construction as the TLS \`X25519MLKEM768\` from Lab 2."
echo "- Forcing legacy \`curve25519-sha256\` still works (**\`${neg_classic}\`**) — the"
echo "  classical path stays for old peers, exactly the hybrid/fallback stance ch08 argues for."
echo "- OpenSSH ships **two independent** PQC KEX families (ML-KEM and Streamlined NTRU"
echo "  Prime: **\`${neg_ntru}\`**), so the ecosystem is not betting on one hard problem."
if [ -n "${offer:-}" ]; then
  echo
  echo "_Client's default KEX proposal (in order):_ \`${offer}\`"
fi
echo
echo "_Full client debug traces: \`client-default.log\`, \`client-classical.log\`,"
echo "\`client-mlkem.log\`, \`client-ntruprime.log\`._"
