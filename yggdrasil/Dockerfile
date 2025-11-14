FROM debian:bullseye-slim

ARG TARGETPLATFORM

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    iptables \
    tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN set -e; \
    curl -fsSL "https://github.com/yggdrasil-network/yggdrasil-go/releases/download/v0.5.12/yggdrasil-0.5.12-vendored.tar.gz" -o yggdrasil.tar.gz; \
    tar -xzf yggdrasil.tar.gz -C /usr/local/bin; \
    rm yggdrasil.tar.gz

EXPOSE 9001

ENTRYPOINT ["yggdrasil", "-useconffile", "/etc/yggdrasil.conf"]
