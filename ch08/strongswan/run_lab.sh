#!/bin/sh
set -eu

image=${STRONGSWAN_IMAGE:-strongx509/strongswan@sha256:f35be40ef1b2f3a08ab50d2c9d6ee6697d57b00b4e045b2cde15d45b8a6c7e0c}
base_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
mode=${1:-}
if [ -n "$mode" ] && [ "$mode" != "--negative" ]; then
  printf 'Usage: %s [--negative]\n' "$0" >&2
  exit 2
fi
suffix=$$
network="ch08-pq-${suffix}"
initiator="ch08-pq-init-${suffix}"
responder="ch08-pq-resp-${suffix}"
temp_dir=
initiator_config="$base_dir/initiator.conf"
responder_config="$base_dir/responder.conf"

if [ "$mode" = "--negative" ]; then
  temp_dir=$(mktemp -d)
  sed 's/-ke1_mlkem768/-mlkem768/' "$initiator_config" > "$temp_dir/initiator.conf"
  sed 's/-ke1_mlkem768/-mlkem768/' "$responder_config" > "$temp_dir/responder.conf"
  initiator_config="$temp_dir/initiator.conf"
  responder_config="$temp_dir/responder.conf"
fi

cleanup() {
  docker rm -f "$initiator" "$responder" >/dev/null 2>&1 || true
  docker network rm "$network" >/dev/null 2>&1 || true
  if [ -n "$temp_dir" ]; then
    rm -f "$temp_dir/initiator.conf" "$temp_dir/responder.conf"
    rmdir "$temp_dir"
  fi
}
trap cleanup EXIT INT TERM

docker network create --subnet 172.29.8.0/24 "$network" >/dev/null

start_peer() {
  name=$1
  address=$2
  config=$3
  docker run -d --name "$name" --network "$network" --ip "$address" \
    --cap-add NET_ADMIN \
    -v "$config:/etc/swanctl/swanctl.conf:ro" \
    --entrypoint /usr/libexec/ipsec/charon \
    "$image" --debug-ike 2 --debug-net 2 --debug-cfg 1 >/dev/null
}

start_peer "$responder" 172.29.8.3 "$responder_config"
start_peer "$initiator" 172.29.8.2 "$initiator_config"

attempt=0
while [ "$attempt" -lt 20 ]; do
  if docker exec "$initiator" swanctl --version >/dev/null 2>&1 && \
     docker exec "$responder" swanctl --version >/dev/null 2>&1; then
    break
  fi
  attempt=$((attempt + 1))
  sleep 0.25
done

docker exec "$responder" swanctl --load-all >/dev/null
docker exec "$initiator" swanctl --load-all >/dev/null
docker exec "$initiator" swanctl --initiate --child protected-net >/dev/null

sa_output=$(docker exec "$initiator" swanctl --list-sas --pretty)
printf '%s\n' "$sa_output"

printf '%s\n' "$sa_output" | grep -Eq 'state[[:space:]]*=[[:space:]]*ESTABLISHED'
printf '%s\n' "$sa_output" | grep -Eq 'dh-group[[:space:]]*=[[:space:]]*ECP_384'
printf '%s\n' "$sa_output" | grep -Eq 'state[[:space:]]*=[[:space:]]*INSTALLED'
if [ "$mode" = "--negative" ]; then
  if printf '%s\n' "$sa_output" | grep -Eq 'ake1[[:space:]]*='; then
    printf 'Negative control failed: an additional exchange was selected.\n' >&2
    exit 1
  fi
  printf '\nExpected negative control: classical-only SA established; hybrid-policy check FAILED.\n'
else
  printf '%s\n' "$sa_output" | grep -Eq 'ake1[[:space:]]*=[[:space:]]*ML_KEM_768'
  printf '\nVerified hybrid exchange and Child SA: ECP_384 + ML_KEM_768\n'
fi

if [ "${VERBOSE:-0}" = "1" ]; then
  printf '\nInitiator daemon log\n'
  docker logs "$initiator" 2>&1
  printf '\nResponder daemon log\n'
  docker logs "$responder" 2>&1
fi
