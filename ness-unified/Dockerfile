FROM golang:1.21-alpine AS dns-builder

# Build dns-reverse-proxy binary with modern Go
RUN apk add --no-cache git
RUN git clone https://github.com/ness-network/dns-reverse-proxy.git /tmp/dns-proxy \
    && cd /tmp/dns-proxy \
    && go build -o /out/dns-reverse-proxy .

FROM debian:bullseye-slim AS base

ARG TARGETPLATFORM

# Install common dependencies
RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    git \
    build-essential \
    golang-go \
    python3 \
    python3-pip \
    openjdk-17-jre-headless \
    supervisor \
    iptables \
    make \
    tar \
    xz-utils \
    i2pd \
    && rm -rf /var/lib/apt/lists/*

ENV GOPATH=/root/go
ENV PATH=$PATH:$GOPATH/bin

WORKDIR /build

# Build Emercoin
ENV EMERCOIN_VERSION=0.8.5
ENV EMERCOIN_TAG=v0.8.5emc
RUN ARCH=$(dpkg --print-architecture) && \
    case ${ARCH} in \
        amd64) EMERCOIN_ARCH="x86_64-linux-gnu" ;; \
        *) echo "Unsupported architecture for prebuilt Emercoin release: ${ARCH}" && exit 1 ;; \
    esac && \
    ARCHIVE_NAME="emercoin-${EMERCOIN_VERSION}-${EMERCOIN_ARCH}.tar.xz" && \
    wget https://github.com/emercoin/emercoin/releases/download/${EMERCOIN_TAG}/${ARCHIVE_NAME} \
    && tar -xJf ${ARCHIVE_NAME} \
    && mv emercoin-${EMERCOIN_VERSION}-${EMERCOIN_ARCH}/emercoind /usr/local/bin/ \
    && mv emercoin-${EMERCOIN_VERSION}-${EMERCOIN_ARCH}/emercoin-qt /usr/local/bin/ \
    && mv emercoin-${EMERCOIN_VERSION}-${EMERCOIN_ARCH}/emercoin-cli /usr/local/bin/ \
    && rm -rf emercoin-${EMERCOIN_VERSION}-${EMERCOIN_ARCH} ${ARCHIVE_NAME}

ENV YGGDRASIL_VERSION=0.5.12

# Install Yggdrasil from vendored tarball (no systemd deps)
RUN set -e; \
    wget -O /tmp/yggdrasil.tar.gz "https://github.com/yggdrasil-network/yggdrasil-go/releases/download/v${YGGDRASIL_VERSION}/yggdrasil-${YGGDRASIL_VERSION}-vendored.tar.gz"; \
    tar -xzf /tmp/yggdrasil.tar.gz -C /usr/local/bin; \
    rm /tmp/yggdrasil.tar.gz

# Install Skywire from prebuilt v1.3.31 release tarball (also keep source under GOPATH)
ENV SKYWIRE_VERSION=1.3.31
RUN set -e; \
    ARCH=$(dpkg --print-architecture); \
    case ${ARCH} in \
        amd64)  SKYWIRE_ARCH="linux-amd64" ;; \
        arm64)  SKYWIRE_ARCH="linux-arm64" ;; \
        armhf)  SKYWIRE_ARCH="linux-armhf" ;; \
        armel)  SKYWIRE_ARCH="linux-arm" ;; \
        i386)   SKYWIRE_ARCH="linux-386" ;; \
        *) echo "Unsupported architecture for Skywire: ${ARCH}" && exit 1 ;; \
    esac; \
    mkdir -p ${GOPATH}/src/github.com/skycoin \
    && git clone https://github.com/skycoin/skywire.git ${GOPATH}/src/github.com/skycoin/skywire \
    && cd ${GOPATH}/src/github.com/skycoin/skywire && go mod download && cd /build; \
    wget -O /tmp/skywire.tar.gz "https://github.com/skycoin/skywire/releases/download/v${SKYWIRE_VERSION}/skywire-v${SKYWIRE_VERSION}-${SKYWIRE_ARCH}.tar.gz"; \
    mkdir -p /opt/skywire; \
    tar -xzf /tmp/skywire.tar.gz -C /opt/skywire; \
    cp /opt/skywire/* /usr/local/bin/; \
    rm -rf /tmp/skywire.tar.gz /opt/skywire

# Install DNS Reverse Proxy binary built in dns-builder stage
COPY --from=dns-builder /out/dns-reverse-proxy /usr/local/bin/dns-reverse-proxy

# Install Ness-network repositories into GOPATH
RUN mkdir -p ${GOPATH}/src/github.com/ness-network \
    && git clone https://github.com/ness-network/ness.git ${GOPATH}/src/github.com/ness-network/ness

RUN mkdir -p ${GOPATH}/src/github.com/ness-network \
    && git clone https://github.com/ness-network/pyuheprng.git ${GOPATH}/src/github.com/ness-network/pyuheprng

RUN mkdir -p ${GOPATH}/src/github.com/ness-network \
    && git clone https://github.com/ness-network/privatenumer.git ${GOPATH}/src/github.com/ness-network/privatenumer

RUN mkdir -p ${GOPATH}/src/github.com/ness-network \
    && git clone https://github.com/ness-network/privatenesstools.git ${GOPATH}/src/github.com/ness-network/privatenesstools

# Create data directories
RUN mkdir -p /data/emercoin /data/yggdrasil /data/i2p /data/skywire

# Supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose all ports
EXPOSE 6661 6662 8775 9001 7657 4444 6668 8000 53/udp 53/tcp 8053 8080 5000 3000 8888

VOLUME ["/data"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
