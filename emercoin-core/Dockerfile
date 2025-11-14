FROM emercoin/core:latest

ENV EMERCOIN_DATA=/data

VOLUME ${EMERCOIN_DATA}

EXPOSE 6661 6662 8775

ENTRYPOINT ["emercoind", "-datadir=/data"]
