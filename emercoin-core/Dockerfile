FROM ubuntu:16.04

LABEL name="Emercoin 0.8.5" maintainer="nessnetwork"

RUN apt update && \
    apt install -y wget xz-utils ca-certificates && \
    apt clean -y && rm -rf /var/lib/apt/lists/*

ENV EMER_DISTR_VERSION=0.8.5

WORKDIR /tmp/emer

RUN wget https://github.com/emercoin/emercoin/releases/download/v${EMER_DISTR_VERSION}emc/emercoin-${EMER_DISTR_VERSION}-x86_64-linux-gnu.tar.xz && \
    tar xf emercoin-${EMER_DISTR_VERSION}-x86_64-linux-gnu.tar.xz && \
    cp emercoin-${EMER_DISTR_VERSION}-x86_64-linux-gnu/emercoind /usr/local/bin/ && \
    cp emercoin-${EMER_DISTR_VERSION}-x86_64-linux-gnu/emercoin-cli /usr/local/bin/ && \
    rm -rf emercoin-${EMER_DISTR_VERSION}-x86_64-linux-gnu* 

ENV EMERCOIN_DATA=/data

VOLUME ${EMERCOIN_DATA}

EXPOSE 6661 6662 8775

ENTRYPOINT ["emercoind", "-datadir=/data"]
