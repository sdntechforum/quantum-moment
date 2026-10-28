# Chapter 9 companion lab

This directory contains only the experiment used by Chapter 9: an IKEv2 lifecycle lab that distinguishes inherited key-schedule dependence from a fresh post-quantum contribution at rekey time. Other repository experiments are outside this chapter's scope.

Run the lab on a Linux Docker host:

```sh
cd strongswan
./run_rekey_lab.sh
```

The script uses an immutable strongSwan 6.0.6 image digest, creates an isolated Docker network, and removes its containers and network on exit. The pre-shared key is lab-only. Do not reuse it in production.

See `results.md` for the verified run and its interpretation.
