#!/bin/sh
set -eu

image=${STRONGSWAN_IMAGE:-strongx509/strongswan@sha256:f35be40ef1b2f3a08ab50d2c9d6ee6697d57b00b4e045b2cde15d45b8a6c7e0c}
base_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
suffix=$$
network="ch09-pq-${suffix}"
initiator="ch09-pq-init-${suffix}"
responder="ch09-pq-resp-${suffix}"

cleanup() {
  docker rm -f "$initiator" "$responder" >/dev/null 2>&1 || true
  docker network rm "$network" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

docker network create --subnet 172.29.9.0/24 "$network" >/dev/null

start_peer() {
  name=$1
  address=$2
  config=$3
  docker run -d --name "$name" --network "$network" --ip "$address" \
    --cap-add NET_ADMIN \
    -v "$config:/etc/swanctl/swanctl.conf:ro" \
    --entrypoint /usr/libexec/ipsec/charon \
    "$image" --debug-ike 2 --debug-net 1 --debug-cfg 1 >/dev/null
}

start_peer "$responder" 172.29.9.3 "$base_dir/responder.conf"
start_peer "$initiator" 172.29.9.2 "$base_dir/initiator.conf"

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

docker exec "$initiator" swanctl --initiate --child retained-dependence >/dev/null
docker exec "$initiator" swanctl --initiate --child fresh-pq-child >/dev/null

printf 'INITIAL STATE\n'
initial=$(docker exec "$initiator" swanctl --list-sas --pretty)
printf '%s\n' "$initial"
printf '%s\n' "$initial" | grep -Eq 'state[[:space:]]*=[[:space:]]*ESTABLISHED'
printf '%s\n' "$initial" | grep -Eq 'ake1[[:space:]]*=[[:space:]]*ML_KEM_768'

printf '\nREKEY CLASSICAL-ONLY CHILD\n'
docker exec "$initiator" swanctl --rekey --child retained-dependence >/dev/null
retained=$(docker exec "$initiator" swanctl --list-sas --pretty)
printf '%s\n' "$retained"
printf '%s\n' "$retained" | grep -Eq 'retained-dependence'

printf '\nREKEY CHILD WITH FRESH ADDITIONAL PQ EXCHANGE\n'
docker exec "$initiator" swanctl --rekey --child fresh-pq-child >/dev/null
fresh=$(docker exec "$initiator" swanctl --list-sas --pretty)
printf '%s\n' "$fresh"
printf '%s\n' "$fresh" | grep -Eq 'fresh-pq-child'

printf '\nREKEY IKE SA WHILE PRESERVING HYBRID POLICY\n'
docker exec "$initiator" swanctl --rekey --ike pq-lifecycle >/dev/null
ike=$(docker exec "$initiator" swanctl --list-sas --pretty)
printf '%s\n' "$ike"
printf '%s\n' "$ike" | grep -Eq 'ake1[[:space:]]*=[[:space:]]*ML_KEM_768'

logs=$(docker logs "$initiator" 2>&1)
printf '\nFOLLOW-UP EXCHANGE EVIDENCE\n'
printf '%s\n' "$logs" | grep -E 'IKE_FOLLOWUP_KE|additional key exchange' || true

printf '\nNEGATIVE TEST: RELOAD CLASSICAL-ONLY POLICY, THEN RE-ESTABLISH\n'
docker cp "$base_dir/initiator-classical.conf" "$initiator:/tmp/swanctl-classical.conf"
docker cp "$base_dir/responder-classical.conf" "$responder:/tmp/swanctl-classical.conf"
docker exec "$responder" swanctl --load-all --file /tmp/swanctl-classical.conf >/dev/null
docker exec "$initiator" swanctl --load-all --file /tmp/swanctl-classical.conf >/dev/null
docker exec "$initiator" swanctl --terminate --ike pq-lifecycle >/dev/null
docker exec "$initiator" swanctl --initiate --child retained-dependence >/dev/null
downgraded=$(docker exec "$initiator" swanctl --list-sas --pretty)
printf '%s\n' "$downgraded"
printf '%s\n' "$downgraded" | grep -Eq 'dh-group[[:space:]]*=[[:space:]]*ECP_384'
if printf '%s\n' "$downgraded" | grep -Eq 'ake1[[:space:]]*='; then
  printf 'FAIL: classical-only re-establishment unexpectedly retained an additional exchange.\n' >&2
  exit 1
fi

printf '\nPASS: initial and rekeyed IKE SAs retain ECP_384 + ML_KEM_768.\n'
printf 'PASS: both Child SAs rekeyed; only fresh-pq-child requests a fresh ML-KEM contribution.\n'
printf 'PASS: full re-establishment dropped ML-KEM after both peers loaded classical-only policy.\n'

# Final acceptance checks the saved Child snapshots, not the parent IKE SA's ake1.
if ! printf '%s\n' "$retained" | awk '
  /^[[:space:]]*retained-dependence-[0-9]+[[:space:]]*\{/ { child = 1; block = ""; next }
  child {
    block = block $0 "\n"
    if ($0 ~ /^[[:space:]]*\}/) {
      if (block ~ /state[[:space:]]*=[[:space:]]*INSTALLED/ &&
          block ~ /dh-group[[:space:]]*=[[:space:]]*ECP_384/ &&
          block !~ /ake1[[:space:]]*=/) found = 1
      child = 0
    }
  }
  END { exit !found }
'; then
  printf 'FAIL: replacement retained-dependence Child SA did not show classical-only fresh input.\n' >&2
  exit 1
fi
if ! printf '%s\n' "$fresh" | awk '
  /^[[:space:]]*fresh-pq-child-[0-9]+[[:space:]]*\{/ { child = 1; block = ""; next }
  child {
    block = block $0 "\n"
    if ($0 ~ /^[[:space:]]*\}/) {
      if (block ~ /state[[:space:]]*=[[:space:]]*INSTALLED/ &&
          block ~ /dh-group[[:space:]]*=[[:space:]]*ECP_384/ &&
          block ~ /ake1[[:space:]]*=[[:space:]]*ML_KEM_768/) found = 1
      child = 0
    }
  }
  END { exit !found }
'; then
  printf 'FAIL: replacement fresh-pq-child Child SA did not show negotiated ML-KEM input.\n' >&2
  exit 1
fi

printf 'PASS: installed replacement Child SAs show the expected per-Child ECP-384 and ML-KEM inputs.\n'
