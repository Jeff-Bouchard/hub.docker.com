FROM python:3.11-slim

ARG TARGETPLATFORM

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    apt-utils \
    build-essential \
    python3-dev \
    libxml2-dev \
    libxslt1-dev \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ness-network/privatenesstools.git . \
    && pip install --no-cache-dir -r requirements.txt

EXPOSE 8888

CMD ["python", "main.py"]
