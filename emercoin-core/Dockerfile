FROM debian:bullseye-slim

ARG TARGETPLATFORM

ENV EMERCOIN_VERSION=0.8.5
ENV EMERCOIN_DATA=/data

RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Detect architecture and download appropriate binary
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

RUN mkdir -p ${EMERCOIN_DATA}

VOLUME ${EMERCOIN_DATA}

EXPOSE 6661 6662 8775

ENTRYPOINT ["emercoind", "-datadir=/data"]
