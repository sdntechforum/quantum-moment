#!/bin/sh
set -eu

kex=mlkem768x25519-sha256
port=${PORT:-2222}
sshd_bin=$(command -v sshd || true)
if [ -z "$sshd_bin" ]; then
    printf '%s\n' 'sshd is required for this lab.' >&2
    exit 1
fi
if ! ssh -Q kex | grep -qx "$kex"; then
    printf 'This OpenSSH build does not support %s.\n' "$kex" >&2
    exit 1
fi

lab_dir=$(mktemp -d "${TMPDIR:-/tmp}/ch07-ssh.XXXXXX")
sshd_pid=
cleanup() {
    if [ -n "$sshd_pid" ]; then
        kill "$sshd_pid" 2>/dev/null || true
        wait "$sshd_pid" 2>/dev/null || true
    fi
    rm -rf -- "$lab_dir"
}
trap cleanup EXIT HUP INT TERM

ssh-keygen -q -t ed25519 -f "$lab_dir/hostkey" -N ''
"$sshd_bin" -D -e -p "$port" -h "$lab_dir/hostkey" \
    -o ListenAddress=127.0.0.1 \
    -o KexAlgorithms="$kex" \
    -o PasswordAuthentication=no \
    -o PubkeyAuthentication=no \
    -o UsePAM=no \
    -o PidFile="$lab_dir/sshd.pid" >"$lab_dir/server.log" 2>&1 &
sshd_pid=$!
sleep 1

set +e
ssh -vv -p "$port" \
    -o KexAlgorithms="$kex" \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o PreferredAuthentications=none \
    nobody@127.0.0.1 true >"$lab_dir/client.log" 2>&1
ssh_status=$?
set -e

negotiated=$(sed -n 's/^debug1: kex: algorithm: //p' "$lab_dir/client.log" | tr -d '\r' | head -1)
if [ "$negotiated" != "$kex" ]; then
    printf '%s\n' 'Hybrid key exchange was not negotiated.' >&2
    sed -n '1,160p' "$lab_dir/client.log" >&2
    exit 1
fi

printf 'Negotiated key exchange: %s\n' "$negotiated"
printf 'SSH client: %s\n' "$(ssh -V 2>&1)"
printf 'Final SSH status: %s (authentication failure is expected after KEX)\n' "$ssh_status"
