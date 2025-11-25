FROM debian:bullseye-slim

ARG TARGETPLATFORM

RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    apt-utils \
    i2pd \
    curl \
    iproute2 \
    iptables \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Install Yggdrasil from vendored tarball
WORKDIR /tmp
RUN set -e; \
    curl -fsSL "https://github.com/yggdrasil-network/yggdrasil-go/releases/download/v0.5.12/yggdrasil-0.5.12-vendored.tar.gz" -o yggdrasil.tar.gz; \
    tar -xzf yggdrasil.tar.gz -C /usr/local/bin; \
    rm yggdrasil.tar.gz

WORKDIR /

EXPOSE 7657 4444 6668 9001 9002

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Enable IPv6 and TUN device support
RUN mkdir -p /dev/net && \
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

ENTRYPOINT ["/entrypoint.sh"]
