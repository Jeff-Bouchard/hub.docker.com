FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN apk add --no-cache git make

WORKDIR /yggdrasil

RUN git clone https://github.com/yggdrasil-network/yggdrasil-go.git . \
    && ./build

FROM alpine:latest

RUN apk add --no-cache ca-certificates iptables

COPY --from=builder /yggdrasil/yggdrasil /usr/local/bin/
COPY --from=builder /yggdrasil/yggdrasilctl /usr/local/bin/

EXPOSE 9001

ENTRYPOINT ["yggdrasil", "-useconffile", "/etc/yggdrasil.conf"]
