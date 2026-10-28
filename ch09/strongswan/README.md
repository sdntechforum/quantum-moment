# strongSwan rekey lifecycle lab

## What the lab proves

The lab creates one hybrid IKE SA using ECP-384 plus ML-KEM-768 and two Child SAs:

- `retained-dependence` uses ECP-384 during Child SA rekey. Its new key material still depends on the existing hybrid IKE SA's `SK_d`, but the rekey adds no fresh ML-KEM secret.
- `fresh-pq-child` uses ECP-384 plus ML-KEM-768 during Child SA rekey. The daemon reports `IKE_FOLLOWUP_KE`, and the installed Child SA reports `ake1 = ML_KEM_768`.

The script then rekeys the IKE SA under the hybrid policy and verifies the new IKE SA still reports `ake1 = ML_KEM_768`. Finally, it loads a classical-only IKE policy, fully terminates the IKE SA, re-establishes it, and verifies that the new SA no longer reports an additional ML-KEM exchange. This last step demonstrates the true policy-drift boundary in the lab: a fresh establishment, not merely the first Child SA rekey.

## Requirements

- Linux Docker host with permission to create networks and containers
- outbound access for the pinned image if it is not already cached
- POSIX shell, `grep`, and standard Docker CLI

## Run

```sh
./run_rekey_lab.sh
```

Expected final lines:

```text
PASS: initial and rekeyed IKE SAs retain ECP_384 + ML_KEM_768.
PASS: both Child SAs rekeyed; only fresh-pq-child requests a fresh ML-KEM contribution.
PASS: full re-establishment dropped ML-KEM after both peers loaded classical-only policy.
PASS: installed replacement Child SAs show the expected per-Child ECP-384 and ML-KEM inputs.
```

The image is pinned by digest. Override `STRONGSWAN_IMAGE` only when deliberately validating another build. The sample identities, traffic selectors, and pre-shared key are synthetic.
