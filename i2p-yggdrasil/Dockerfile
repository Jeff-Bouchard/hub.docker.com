FROM debian:bullseye-slim

ARG TARGETPLATFORM

ENV I2P_VERSION=2.4.0

RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    openjdk-17-jre-headless \
    git \
    golang-go \
    make \
    iproute2 \
    iptables \
    && rm -rf /var/lib/apt/lists/*

# Install I2P (all.deb is architecture-independent, contains Java)
RUN wget https://github.com/i2p/i2p.i2p/releases/download/i2p-${I2P_VERSION}/i2p-install_${I2P_VERSION}_all.deb \
    && dpkg -i i2p-install_${I2P_VERSION}_all.deb || apt-get install -f -y \
    && rm i2p-install_${I2P_VERSION}_all.deb

# Build Yggdrasil
WORKDIR /tmp/yggdrasil
RUN git clone https://github.com/yggdrasil-network/yggdrasil-go.git . \
    && ./build \
    && mv yggdrasil /usr/local/bin/ \
    && mv yggdrasilctl /usr/local/bin/ \
    && cd / && rm -rf /tmp/yggdrasil

WORKDIR /i2p

# Configure I2P to use Yggdrasil
RUN mkdir -p /var/lib/i2p/config

EXPOSE 7657 4444 6668 9001 9002

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Enable IPv6 and TUN device support
RUN mkdir -p /dev/net && \
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

ENTRYPOINT ["/entrypoint.sh"]
