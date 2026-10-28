FROM silkeh/clang@sha256:3914c93a02e866795aafc80737488e515b96390eff3d2787cf8c5095997baea9

COPY inspect_clangover.sh /usr/local/bin/inspect-clangover
RUN chmod 0755 /usr/local/bin/inspect-clangover

ENTRYPOINT ["/usr/local/bin/inspect-clangover"]
