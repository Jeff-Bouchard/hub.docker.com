FROM python:3.11-slim

ARG TARGETPLATFORM

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ness-network/ness.git . \
    && pip install --no-cache-dir -r requirements.txt

EXPOSE 8080

CMD ["python", "main.py"]
