#!/bin/sh
set -eu

port=${PORT:-44330}
lab_dir=$(mktemp -d "${TMPDIR:-/tmp}/ch07-tls.XXXXXX")
server_pid=

cleanup() {
    if [ -n "$server_pid" ]; then
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
    fi
    rm -rf -- "$lab_dir"
}
trap cleanup EXIT HUP INT TERM

openssl req -x509 -new -newkey ED25519 \
    -keyout "$lab_dir/server.key" \
    -out "$lab_dir/server.crt" \
    -nodes -days 1 -subj /CN=localhost >/dev/null 2>&1

openssl s_server -www -accept "127.0.0.1:$port" \
    -cert "$lab_dir/server.crt" -key "$lab_dir/server.key" \
    -tls1_3 -groups x25519:X25519MLKEM768 \
    >"$lab_dir/server.log" 2>&1 &
server_pid=$!
sleep 1

printf '%-20s %12s %12s\n' 'GROUP' 'CLIENTHELLO' 'KEY_SHARE'
for group in x25519 X25519MLKEM768; do
    log="$lab_dir/$group.log"
    printf 'GET / HTTP/1.0\r\nHost: localhost\r\n\r\n' | \
        openssl s_client -connect "127.0.0.1:$port" -tls1_3 \
        -groups "$group" -servername localhost -trace -no_ign_eof \
        >"$log" 2>&1

    clienthello=$(awk -F'Length=' '/ClientHello, Length=/{print $2; exit}' "$log")
    keyshare=$(awk -F'length=' '/extension_type=key_share/{print $2; exit}' "$log")
    if [ -z "$clienthello" ] || [ -z "$keyshare" ]; then
        printf '%s\n' "Unable to parse OpenSSL trace for $group" >&2
        sed -n '1,120p' "$log" >&2
        exit 1
    fi
    printf '%-20s %9s B %9s B\n' "$group" "$clienthello" "$keyshare"
done

printf '\nOpenSSL: %s\n' "$(openssl version)"
printf '%s\n' 'These are local trace lengths, not a universal browser ClientHello size.'
