FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN apk add --no-cache git make

WORKDIR /skywire

RUN git clone https://github.com/skycoin/skywire.git . \
    && make build-release

FROM alpine:latest

RUN apk add --no-cache ca-certificates

COPY --from=builder /skywire/build/* /usr/local/bin/

EXPOSE 8000

ENTRYPOINT ["skywire-visor"]
