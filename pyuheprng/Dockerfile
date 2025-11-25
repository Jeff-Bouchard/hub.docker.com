FROM python:3.11-slim

ARG TARGETPLATFORM

WORKDIR /app

# Install dependencies for entropy generation
RUN apt-get update && apt-get install -y \
    apt-utils \
    git \
    rng-tools \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Clone pyuheprng repository and install package
RUN git clone https://github.com/NESS-Network/PyUHEPRNG . \
    && pip install --no-cache-dir .

# Environment variables for Emercoin connection
ENV EMERCOIN_HOST=emercoin-core \
    EMERCOIN_PORT=6662 \
    EMERCOIN_USER=rpcuser \
    EMERCOIN_PASS=rpcpassword \
    MIN_ENTROPY_RATE=1000 \
    BLOCK_ON_LOW_ENTROPY=true

EXPOSE 5000

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health').raise_for_status()"

ENTRYPOINT ["/entrypoint.sh"]
