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

# Install Emercoin from our multi-arch image
COPY --from=nessnetwork/emercoin-core:latest /usr/local/bin/emercoind /usr/local/bin/emercoind
COPY --from=nessnetwork/emercoin-core:latest /usr/local/bin/emercoin-cli /usr/local/bin/emercoin-cli
# Try /usr/bin if /usr/local/bin fails? Docker doesn't support conditional copy.
# Assumption: emercoin-core uses /usr/local/bin (based on previous manual install in this file moving to /usr/local/bin)

# Install Yggdrasil from our multi-arch image
COPY --from=nessnetwork/yggdrasil:latest /usr/local/bin/yggdrasil /usr/local/bin/yggdrasil
COPY --from=nessnetwork/yggdrasil:latest /usr/local/bin/yggdrasilctl /usr/local/bin/yggdrasilctl

# Install Skywire from our multi-arch image
COPY --from=nessnetwork/skywire:latest /opt/skywire /opt/skywire
RUN ln -s /opt/skywire/skywire-visor /usr/local/bin/skywire-visor

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
