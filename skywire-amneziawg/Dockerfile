FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN apk add --no-cache git make

WORKDIR /skywire

RUN git clone https://github.com/skycoin/skywire.git . \
    && make build-release

FROM debian:bullseye-slim

ARG TARGETPLATFORM

RUN apt-get update && apt-get install -y \
    ca-certificates \
    iproute2 \
    iptables \
    kmod \
    git \
    build-essential \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Skywire
COPY --from=builder /skywire/build/* /usr/local/bin/

# Build AmneziaWG
WORKDIR /build
RUN git clone https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git \
    && cd amneziawg-linux-kernel-module/src \
    && make \
    && make install

RUN git clone https://github.com/amnezia-vpn/amneziawg-tools.git \
    && cd amneziawg-tools/src \
    && make \
    && make install

# Create directories
RUN mkdir -p /etc/amneziawg /root/.skywire

WORKDIR /app

EXPOSE 8000 51820/udp

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
