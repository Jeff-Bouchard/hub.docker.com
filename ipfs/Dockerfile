FROM golang:1.21-bullseye AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /build

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone IPFS (Kubo) repository
ARG IPFS_VERSION=v0.24.0
RUN git clone --depth 1 --branch ${IPFS_VERSION} https://github.com/ipfs/kubo.git

# Build IPFS with cross-compilation support
WORKDIR /build/kubo
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} make build

# Final stage
FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Copy IPFS binary from builder
COPY --from=builder /build/kubo/cmd/ipfs/ipfs /usr/local/bin/ipfs

# Create IPFS user
RUN useradd -m -u 1000 -s /bin/bash ipfs

# Create IPFS data directory
RUN mkdir -p /data/ipfs && chown -R ipfs:ipfs /data/ipfs

# Set environment
ENV IPFS_PATH=/data/ipfs

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to ipfs user
USER ipfs

# Expose ports
# 4001 - P2P swarm
# 5001 - API
# 8080 - Gateway
# 8081 - WebUI
EXPOSE 4001 5001 8080 8081

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD ipfs id || exit 1

VOLUME /data/ipfs

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
CMD ["daemon", "--migrate=true", "--enable-gc"]
