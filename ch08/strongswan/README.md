# Verify an RFC 9370 hybrid strongSwan tunnel

This lab starts two strongSwan 6.0.6 containers on an isolated Docker bridge.
The peers negotiate ECP-384 during `IKE_SA_INIT` and ML-KEM-768 as the first
additional key exchange during `IKE_INTERMEDIATE`.

## Prerequisites

- Docker Engine with permission to create an isolated bridge network
- Linux containers with the `NET_ADMIN` capability
- Access to the pinned strongSwan image shown in `run_lab.sh`
- A disposable lab host; this script creates and removes a Docker bridge and two containers

Run:

```sh
./run_lab.sh
./run_lab.sh --negative
```

Success requires all of the following in the initiator's `swanctl --list-sas`
output:

- IKE SA state `ESTABLISHED`
- Classical exchange `ECP_384`
- Additional exchange `ML_KEM_768`

The second command is an intentional negative control, not a passing hybrid
result. It creates temporary copies of both peer configurations without the
`ke1_` marker, requires an established ECP-384 SA with no `ake1` value, and
removes the temporary copies and Docker resources on exit. The checked-in peer
files remain unchanged. The marker makes ML-KEM a required additional exchange;
without it, `ecp384` and `mlkem768` are alternatives. Connection success alone
does not prove that ML-KEM contributed.

The example PSK is for the lab only. Use an approved authentication method and
managed credentials in any real deployment.
