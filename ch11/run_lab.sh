#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
image=quantum-moment-ch11-agility:openssl-3.5.8

mkdir -p "$script_dir/results"
docker build --pull=false -t "$image" "$script_dir"
docker run --rm --network none \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=16m \
  --mount "type=bind,src=$script_dir,dst=/lab,readonly" \
  --mount "type=bind,src=$script_dir/results,dst=/work" \
  "$image"
