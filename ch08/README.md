# Chapter 8 — Crossing the Bridge

Chapter 8 uses one reproducible lab and one vendor-platform verification exercise.
The strongSwan lab is the only runnable Chapter 8 experiment intended for the
book. The Cisco material is retained as a documented platform check because it
requires licensed IOS XE hardware or a supported virtual image.

| Folder | Purpose | Verification level |
|---|---|---|
| [`strongswan/`](strongswan/) | Negotiate ECP-384 plus ML-KEM-768 with RFC 9370 multiple key exchanges | Executed in two Linux containers |
| [`cisco-ppk/`](cisco-ppk/) | Validate the required RFC 8784 PPK configuration and operational evidence | Checked against Cisco documentation; not executed without licensed IOS XE |

The lab demonstrates negotiation and configuration behavior. It is not a
throughput benchmark, a production deployment recipe, or evidence that a WAN
path will carry the larger exchange without loss.
