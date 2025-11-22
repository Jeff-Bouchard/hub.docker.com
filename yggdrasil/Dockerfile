FROM golang:1.22-bullseye AS builder

ARG TARGETOS
ARG TARGETARCH

WORKDIR /build
RUN git clone https://github.com/yggdrasil-network/yggdrasil-go.git . \
    && git checkout v0.5.12

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -ldflags="-w -s" -o /build/yggdrasil ./cmd/yggdrasil
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -ldflags="-w -s" -o /build/yggdrasilctl ./cmd/yggdrasilctl

FROM alpine:latest

RUN apk add --no-cache \
    ca-certificates \
    iptables

COPY --from=builder /build/yggdrasil /usr/local/bin/yggdrasil
COPY --from=builder /build/yggdrasilctl /usr/local/bin/yggdrasilctl

EXPOSE 9001

ENTRYPOINT ["yggdrasil", "-useconffile", "/etc/yggdrasil.conf"]
