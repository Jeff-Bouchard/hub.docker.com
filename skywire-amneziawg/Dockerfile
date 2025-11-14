FROM alpine:latest AS skywire-downloader

ARG TARGETPLATFORM

RUN apk add --no-cache curl tar

WORKDIR /tmp

RUN set -e; \
    case "${TARGETPLATFORM}" in \
      "linux/amd64")  ARCH="linux-amd64" ;; \
      "linux/arm64")  ARCH="linux-arm64" ;; \
      "linux/arm/v7") ARCH="linux-armhf" ;; \
      "linux/arm/v6") ARCH="linux-arm" ;; \
      "linux/386")    ARCH="linux-386" ;; \
      *) echo "Unsupported TARGETPLATFORM: ${TARGETPLATFORM}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/skycoin/skywire/releases/download/v1.3.31/skywire-v1.3.31-${ARCH}.tar.gz" -o skywire.tar.gz; \
    mkdir -p /opt/skywire; \
    tar -xzf skywire.tar.gz -C /opt/skywire; \
    rm skywire.tar.gz

FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    iproute2 \
    iptables \
    git \
    build-essential \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Skywire prebuilt release
COPY --from=skywire-downloader /opt/skywire /opt/skywire
ENV PATH="/opt/skywire:${PATH}"

# Install AmneziaWG userspace tools only (kernel module must be provided by the host)
WORKDIR /build
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
