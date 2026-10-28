# Chapter 8 reference results

Review environment:

- Remote Linux x86-64 Docker host
- Docker Engine 29.1.3
- strongSwan 6.0.6
- Container image `strongx509/strongswan` pinned by digest in `run_lab.sh`

## Required hybrid proposal

With this proposal on both peers:

```text
aes256gcm16-prfsha384-ecp384-ke1_mlkem768
```

the initiator reported:

```text
state = ESTABLISHED
dh-group = ECP_384
ake1 = ML_KEM_768
state = INSTALLED
```

The daemon log recorded a 312-byte `IKE_SA_INIT` request, an
`IKE_INTERMEDIATE` request carrying the additional key exchange, and a
subsequent `IKE_AUTH` request and an installed Child SA. The final script asserts
all four fields above. strongSwan reported a 1,249-byte `IKE_INTERMEDIATE`
message before fragmentation and outgoing encrypted IKE fragment packet lengths
of 1,248 and 66 bytes. The packet lengths include separate IKE framing and
encryption/authentication overhead, so they are not two byte ranges that sum to
the pre-fragment length. This is implementation and path evidence, not a
universal packet count.

## Negative proposal test

On 2 October 2026, the designated Ubuntu Docker host reran the positive command
and `./run_lab.sh --negative`. The latter used temporary copies of both peer
configurations without the `ke1_` marker, producing:

```text
aes256gcm16-prfsha384-ecp384-mlkem768
```

Both peers still established an SA, but it reported only `dh-group = ECP_384`
and no `ake1`. The algorithms had become alternatives and the classical method
was selected. The acceptance check must inspect the negotiated additional key
exchange rather than treating tunnel establishment as proof of hybrid use.
The script reported `Expected negative control: classical-only SA established;
hybrid-policy check FAILED.` The positive rerun reported the required `ake1`
value and an installed Child SA. Both checked-in configurations retained
`ecp384-ke1_mlkem768` afterward. No Chapter 8 container or bridge remained;
the temporary transfer directory on the remote host was removed.

## Cisco RFC 8784 PPK exercise

The commands were checked against Cisco's current IOS XE configuration guide.
They were not executed because the review environment does not include a
licensed IOS XE image or supported Cisco router. The book labels the output as
an example and requires verification on the reader's exact platform and release.
