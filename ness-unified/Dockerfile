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
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Build Emercoin
ENV EMERCOIN_VERSION=0.8.5
RUN ARCH=$(dpkg --print-architecture) && \
    case ${ARCH} in \
        amd64) EMERCOIN_ARCH="x86_64-linux-gnu" ;; \
        arm64) EMERCOIN_ARCH="aarch64-linux-gnu" ;; \
        armhf) EMERCOIN_ARCH="arm-linux-gnueabihf" ;; \
        *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
    esac && \
    wget https://github.com/emercoin/emercoin/releases/download/v${EMERCOIN_VERSION}/emercoin-${EMERCOIN_VERSION}-${EMERCOIN_ARCH}.tar.gz \
    && tar -xzf emercoin-${EMERCOIN_VERSION}-${EMERCOIN_ARCH}.tar.gz \
    && mv emercoin-${EMERCOIN_VERSION}/bin/* /usr/local/bin/ \
    && rm -rf emercoin-*

ENV YGGDRASIL_VERSION=0.5.12

# Install Yggdrasil from vendored tarball (no systemd deps)
RUN set -e; \
    wget -O /tmp/yggdrasil.tar.gz "https://github.com/yggdrasil-network/yggdrasil-go/releases/download/v${YGGDRASIL_VERSION}/yggdrasil-${YGGDRASIL_VERSION}-vendored.tar.gz"; \
    tar -xzf /tmp/yggdrasil.tar.gz -C /usr/local/bin; \
    rm /tmp/yggdrasil.tar.gz

# Install Skywire from prebuilt v1.3.31 release tarball
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
    wget -O /tmp/skywire.tar.gz "https://github.com/skycoin/skywire/releases/download/v${SKYWIRE_VERSION}/skywire-v${SKYWIRE_VERSION}-${SKYWIRE_ARCH}.tar.gz"; \
    mkdir -p /opt/skywire; \
    tar -xzf /tmp/skywire.tar.gz -C /opt/skywire; \
    cp /opt/skywire/* /usr/local/bin/; \
    rm -rf /tmp/skywire.tar.gz /opt/skywire

# Build DNS Reverse Proxy
RUN git clone https://github.com/ness-network/dns-reverse-proxy.git /tmp/dns-proxy \
    && cd /tmp/dns-proxy \
    && go build -o /usr/local/bin/dns-reverse-proxy . \
    && cd / && rm -rf /tmp/dns-proxy

# Install I2P
ENV I2P_VERSION=2.4.0
RUN wget https://github.com/i2p/i2p.i2p/releases/download/i2p-${I2P_VERSION}/i2p-install_${I2P_VERSION}_all.deb \
    && dpkg -i i2p-install_${I2P_VERSION}_all.deb || apt-get install -f -y \
    && rm i2p-install_${I2P_VERSION}_all.deb

# Install Python services
RUN git clone https://github.com/ness-network/ness.git /opt/privateness \
    && cd /opt/privateness \
    && pip3 install --no-cache-dir -r requirements.txt

RUN git clone https://github.com/ness-network/pyuheprng.git /opt/pyuheprng \
    && cd /opt/pyuheprng \
    && pip3 install --no-cache-dir -r requirements.txt

RUN git clone https://github.com/ness-network/privatenumer.git /opt/privatenumer \
    && cd /opt/privatenumer \
    && pip3 install --no-cache-dir -r requirements.txt

RUN git clone https://github.com/ness-network/privatenesstools.git /opt/privatenesstools \
    && cd /opt/privatenesstools \
    && pip3 install --no-cache-dir -r requirements.txt

# Create data directories
RUN mkdir -p /data/emercoin /data/yggdrasil /data/i2p /data/skywire

# Supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose all ports
EXPOSE 6661 6662 8775 9001 7657 4444 6668 8000 53/udp 53/tcp 8053 8080 5000 3000 8888

VOLUME ["/data"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
