# Chapter 9 verification record

- Verification dates: 2026-09-24; corrected per-Child assertions rerun 2026-10-28
- Host: authorized Ubuntu lab host
- Docker: 29.1.3
- Image: `strongx509/strongswan@sha256:f35be40ef1b2f3a08ab50d2c9d6ee6697d57b00b4e045b2cde15d45b8a6c7e0c`
- strongSwan: 6.0.6
- Result: PASS

## Observed evidence

1. Initial IKE SA: `state = ESTABLISHED`, `dh-group = ECP_384`, `ake1 = ML_KEM_768`.
2. Classical-only Child SA rekey: replacement Child SA installed with `dh-group = ECP_384`; the parent IKE SA remained hybrid.
3. Child SA rekey with fresh PQ input: replacement Child SA installed with `dh-group = ECP_384` and `ake1 = ML_KEM_768`; daemon logs showed `IKE_FOLLOWUP_KE` and encrypted fragmentation.
4. IKE SA rekey under the hybrid profile: replacement IKE SA reported `dh-group = ECP_384` and `ake1 = ML_KEM_768`.
5. Full re-establishment after both peers loaded a classical-only IKE profile: new IKE SA reported `dh-group = ECP_384` and no `ake1` field.

On 2026-10-28 the wrapper added and passed Child-specific acceptance checks:
the installed replacement `retained-dependence` Child SA reported `ECP_384`
without its own `ake1`, while the installed replacement `fresh-pq-child` Child SA
reported both `ECP_384` and `ake1 = ML_KEM_768`. The checks inspect each Child
block, so the parent IKE SA's `ake1` cannot satisfy the fresh-Child assertion.

## Interpretation boundary

The run demonstrates negotiated algorithms and state transitions in this pinned implementation. It does not prove cryptographic security. Per RFC 9370, a Child SA rekey without a fresh ML-KEM exchange still derives key material from the existing IKE SA's `SK_d`; therefore it does not instantly become independent of the earlier hybrid exchange. It does lack a fresh post-quantum contribution for that event. The negative step shows that a later full IKE establishment under a classical-only policy can remove ML-KEM from the new association.
