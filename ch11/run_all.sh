#!/bin/sh
set -eu

work=/work
rm -rf "$work/classical" "$work/post_quantum" "$work/brittle_classical" \
  "$work/brittle_post_quantum" "$work/rejected" "$work/POLICY_EXECUTED"

echo "== Environment =="
openssl version

echo "== One implementation, two data policies =="
agile_hash_before=$(sha256sum /lab/agile_sign.sh | cut -d' ' -f1)
/bin/sh /lab/agile_sign.sh /lab/policies/classical.conf /lab/document.txt "$work/classical"
/bin/sh /lab/agile_sign.sh /lab/policies/post_quantum.conf /lab/document.txt "$work/post_quantum"

classical_bytes=$(sed -n 's/^signature_bytes=//p' "$work/classical/evidence.txt")
post_quantum_bytes=$(sed -n 's/^signature_bytes=//p' "$work/post_quantum/evidence.txt")
[ "$classical_bytes" -eq 64 ]
[ "$post_quantum_bytes" -eq 3309 ]

agile_hash_after=$(sha256sum /lab/agile_sign.sh | cut -d' ' -f1)
[ "$agile_hash_before" = "$agile_hash_after" ]

echo "== Policy is data, not executable shell =="
if /bin/sh /lab/agile_sign.sh /lab/policies/malicious.conf /lab/document.txt "$work/rejected"; then
  echo "malicious policy unexpectedly passed" >&2
  exit 1
fi
[ ! -e "$work/POLICY_EXECUTED" ]

echo "== Hardcoded comparison =="
/bin/sh /lab/brittle_ed25519.sh /lab/document.txt "$work/brittle_classical"
/bin/sh /lab/brittle_mldsa65.sh /lab/document.txt "$work/brittle_post_quantum"
brittle_classical_hash=$(sha256sum /lab/brittle_ed25519.sh | cut -d' ' -f1)
brittle_post_quantum_hash=$(sha256sum /lab/brittle_mldsa65.sh | cut -d' ' -f1)
[ "$brittle_classical_hash" != "$brittle_post_quantum_hash" ]

cat > "$work/verification.txt" <<EOF
verification=PASS
agile_implementation_sha256=$agile_hash_before
agile_classical_policy=ED25519
agile_classical_signature_bytes=$classical_bytes
agile_post_quantum_policy=ML-DSA-65
agile_post_quantum_signature_bytes=$post_quantum_bytes
malicious_policy=REJECTED
policy_executed=NO
brittle_classical_source_sha256=$brittle_classical_hash
brittle_post_quantum_source_sha256=$brittle_post_quantum_hash
EOF

cat "$work/verification.txt"
