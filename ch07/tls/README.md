# Measure the TLS 1.3 ClientHello

Run:

```sh
./measure_clienthello.sh
```

The script starts a temporary TLS 1.3 server on `127.0.0.1:44330`, connects
twice, and extracts the ClientHello and `key_share` extension lengths from
OpenSSL's trace. Override the port if needed:

```sh
PORT=45430 ./measure_clienthello.sh
```

The result isolates one variable: the selected key-exchange group. A browser's
ClientHello normally contains additional extensions, so do not treat these
values as a browser-wide constant.
