FROM alpine:latest AS downloader

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

FROM alpine:latest

RUN apk add --no-cache ca-certificates

COPY --from=downloader /opt/skywire /opt/skywire

ENV PATH="/opt/skywire:${PATH}"

EXPOSE 8000

ENTRYPOINT ["skywire-visor"]
