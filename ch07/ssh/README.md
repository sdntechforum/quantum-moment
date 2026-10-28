# Verify the SSH hybrid key exchange

Run:

```sh
./verify_hybrid_kex.sh
```

The script first confirms that the local client supports
`mlkem768x25519-sha256`. It then starts a loopback-only SSH server and performs
the key exchange. Authentication is intentionally disabled, so the final SSH
exit status is nonzero; the lab succeeds when the debug log confirms the
hybrid key-exchange algorithm.

Override the port if needed:

```sh
PORT=23222 ./verify_hybrid_kex.sh
```
