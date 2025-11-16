# Deploy to Docker Hub - nessnetwork

[Français](DEPLOY-FR.md)

## Quick Deploy Guide

### 1. Login to Docker Hub

```bash
docker login
# Username: nessnetwork
# Password: <your-password-or-token>
```

### 2. Build All Images

```bash
./build-all.sh
```

This builds all images tagged as `nessnetwork/<image-name>`.

### 3. Push All Images

```bash
./push-all.sh
```

This pushes all images to https://hub.docker.com/u/nessnetwork

## Individual Image Build & Push

```bash
# Build
docker build -t nessnetwork/emercoin-core ./emercoin-core

# Push
docker push nessnetwork/emercoin-core
```

## Multi-Architecture Build (For Pi4 Support)

### One-time Setup

```bash
# Create buildx builder
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap
```

### Build & Push Multi-Arch

```bash
# Emercoin Core
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t nessnetwork/emercoin-core:latest \
  --push \
  ./emercoin-core

# pyuheprng-privatenesstools (combined)
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t nessnetwork/pyuheprng-privatenesstools:latest \
  --push \
  ./pyuheprng-privatenesstools

# DNS Reverse Proxy
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t nessnetwork/dns-reverse-proxy:latest \
  --push \
  ./dns-reverse-proxy

# Privateness
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t nessnetwork/privateness:latest \
  --push \
  ./privateness
```

## Verify Deployment

```bash
# Check images on Docker Hub
docker search nessnetwork/emercoin-core

# Or visit
# https://hub.docker.com/u/nessnetwork
```

## Pull and Test

```bash
# Pull from Docker Hub
docker pull nessnetwork/emercoin-core

# Test deployment
docker-compose -f docker-compose.ness.yml up -d

# Check status
docker-compose -f docker-compose.ness.yml ps
```

## Image List

All images under `nessnetwork` username:

- `nessnetwork/emercoin-core`
- `nessnetwork/privateness`
- `nessnetwork/skywire`
- `nessnetwork/pyuheprng`
- `nessnetwork/privatenumer`
- `nessnetwork/privatenesstools`
- `nessnetwork/pyuheprng-privatenesstools` (combined)
- `nessnetwork/yggdrasil`
- `nessnetwork/i2p-yggdrasil`
- `nessnetwork/dns-reverse-proxy`
- `nessnetwork/ipfs`
- `nessnetwork/amneziawg`
- `nessnetwork/skywire-amneziawg`
- `nessnetwork/ness-unified`

## Troubleshooting

### Login Issues

```bash
# Use access token instead of password
# Create token at: https://hub.docker.com/settings/security
docker login -u nessnetwork
```

### Build Fails

```bash
# Clean build cache
docker builder prune -a

# Rebuild
./build-all.sh
```

### Push Fails

```bash
# Check you're logged in
docker info | grep Username

# Re-login
docker logout
docker login
```

### Multi-arch Build Issues

```bash
# Remove and recreate builder
docker buildx rm multiarch
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap
```

## Automated CI/CD (Optional)

For automated builds on GitHub:

```yaml
# .github/workflows/docker-publish.yml
name: Docker Publish

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: nessnetwork
          password: ${{ secrets.DOCKER_HUB_TOKEN }}
      
      - name: Build and push
        run: |
          ./build-all.sh
          ./push-all.sh
```

## Notes

- Personal account: `nessnetwork`
- All images are public
- Multi-arch support for Pi4 (arm64)
- Images updated on every push
