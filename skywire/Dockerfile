FROM alpine:latest AS downloader

ARG TARGETPLATFORM

RUN apk add --no-cache curl tar

WORKDIR /tmp

RUN set -e; \
    if [ -z "${TARGETPLATFORM}" ]; then \
      # Plain `docker build` path: infer ARCH from uname -m
      case "$(uname -m)" in \
        x86_64)  ARCH="linux-amd64" ;; \
        aarch64) ARCH="linux-arm64" ;; \
        armv7l|armv7) ARCH="linux-armhf" ;; \
        armv6l|armv6) ARCH="linux-arm" ;; \
        i386|i686)    ARCH="linux-386" ;; \
        *) echo "Unsupported build architecture: $(uname -m)" >&2; exit 1 ;; \
      esac; \
    else \
      # buildx / multi-arch path: trust TARGETPLATFORM from the builder
      case "${TARGETPLATFORM}" in \
        "linux/amd64")  ARCH="linux-amd64" ;; \
        "linux/arm64")  ARCH="linux-arm64" ;; \
        "linux/arm/v7") ARCH="linux-armhf" ;; \
        "linux/arm/v6") ARCH="linux-arm" ;; \
        "linux/386")    ARCH="linux-386" ;; \
        *) echo "Unsupported TARGETPLATFORM: ${TARGETPLATFORM}" >&2; exit 1 ;; \
      esac; \
    fi; \
    curl -fsSL "https://github.com/skycoin/skywire/releases/download/v1.3.31/skywire-v1.3.31-${ARCH}.tar.gz" -o skywire.tar.gz; \
    mkdir -p /opt/skywire; \
    tar -xzf skywire.tar.gz -C /opt/skywire; \
    # Flatten extracted directory so binaries like skywire-visor live directly under /opt/skywire
    if [ -d /opt/skywire/skywire-v1.3.31-${ARCH} ]; then \
      mv /opt/skywire/skywire-v1.3.31-${ARCH}/* /opt/skywire/; \
      rmdir /opt/skywire/skywire-v1.3.31-${ARCH}; \
    fi; \
    rm skywire.tar.gz

FROM alpine:latest

RUN apk add --no-cache ca-certificates

COPY --from=downloader /opt/skywire /opt/skywire

ENV PATH="/opt/skywire:${PATH}"

EXPOSE 8000

# Generate a default config on first run under /root/.skywire, then start the visor
ENTRYPOINT ["/bin/sh", "-c", "mkdir -p /root/.skywire; if [ ! -f /root/.skywire/skywire-config.json ]; then cd /root/.skywire && skywire-cli config gen; fi; exec skywire visor -c /root/.skywire/skywire-config.json"]
