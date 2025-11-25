FROM python:3.11-slim

ARG TARGETPLATFORM

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    apt-utils \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/NESS-Network/privatenumer.git . \
    && pip install --no-cache-dir -r enum-server/requirements.txt

EXPOSE 3000

CMD ["python", "app.py"]
