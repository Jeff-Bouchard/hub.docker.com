FROM golang:1.21-bullseye AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /build

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone Ness blockchain repository
RUN git clone https://github.com/ness-network/ness.git

# Build Privateness blockchain
WORKDIR /build/ness
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -trimpath -ldflags="-s -w" -o /usr/local/bin/privateness ./cmd/privateness
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -trimpath -ldflags="-s -w" -o /usr/local/bin/privateness-cli ./cmd/privateness-cli

# Final stage
FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy binaries from builder
COPY --from=builder /usr/local/bin/privateness /usr/local/bin/privateness
COPY --from=builder /usr/local/bin/privateness-cli /usr/local/bin/privateness-cli

# Create ness user
RUN useradd -m -u 1000 -s /bin/bash ness

# Create data directory
RUN mkdir -p /data && chown -R ness:ness /data

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to ness user
USER ness

# Expose ports
# 6006 - P2P
# 6660 - RPC
EXPOSE 6006 6660

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD privateness-cli status || exit 1

VOLUME /data

ENTRYPOINT ["/entrypoint.sh"]
CMD ["privateness"]
