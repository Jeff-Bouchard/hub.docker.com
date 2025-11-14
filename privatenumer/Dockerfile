FROM python:3.11-slim

ARG TARGETPLATFORM

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ness-network/privatenumer.git . \
    && pip install --no-cache-dir -r requirements.txt

EXPOSE 3000

CMD ["python", "app.py"]
