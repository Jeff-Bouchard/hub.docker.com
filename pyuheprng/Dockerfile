FROM python:3.11-slim

ARG TARGETPLATFORM

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ness-network/pyuheprng.git . \
    && pip install --no-cache-dir -r requirements.txt

EXPOSE 5000

CMD ["python", "server.py"]
