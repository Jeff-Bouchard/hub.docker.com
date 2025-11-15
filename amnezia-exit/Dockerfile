# Build amnezia-xray-core
FROM golang:1.25-alpine AS xray-builder

RUN apk add --no-cache git

WORKDIR /src

RUN git clone https://github.com/amnezia-vpn/amnezia-xray-core.git . \
    && CGO_ENABLED=0 go build -o /out/xray -trimpath -buildvcs=false -ldflags="-s -w -buildid=" -v ./main

# Final image: AmneziaWG tools + Xray REALITY
FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    wget \
    iproute2 \
    iptables \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install AmneziaWG userspace tools (no kernel module here)
WORKDIR /build
RUN git clone https://github.com/amnezia-vpn/amneziawg-tools.git . \
    && cd src \
    && make \
    && make install

# Install Xray binary built in the first stage
COPY --from=xray-builder /out/xray /usr/local/bin/xray

# Config mount points
RUN mkdir -p /etc/amneziawg /etc/xray

WORKDIR /etc/amnezia-exit

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 443/TCP for REALITY, 51820/UDP for WG endpoint (host kernel provides module)
EXPOSE 443/tcp 51820/udp

ENTRYPOINT ["/entrypoint.sh"]
