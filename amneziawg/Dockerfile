FROM debian:bullseye-slim

ARG TARGETPLATFORM

ENV AMNEZIA_VERSION=1.0.0

RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    iproute2 \
    iptables \
    kmod \
    git \
    build-essential \
    linux-headers-generic \
    && rm -rf /var/lib/apt/lists/*

# Build AmneziaWG
WORKDIR /build
RUN git clone https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git \
    && cd amneziawg-linux-kernel-module/src \
    && make \
    && make install

# Install AmneziaWG tools
RUN git clone https://github.com/amnezia-vpn/amneziawg-tools.git \
    && cd amneziawg-tools/src \
    && make \
    && make install

WORKDIR /etc/amneziawg

# Create config directory
RUN mkdir -p /etc/amneziawg

EXPOSE 51820/udp

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
