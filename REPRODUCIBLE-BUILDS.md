# Reproducible Builds - Binary Equivalence

## ⚠️ CRITICAL REQUIREMENT

**All nodes MUST be binary equivalent, otherwise it's bullshit.**

In a truly decentralized network, every node must be able to verify that:
1. All other nodes are running **identical binaries**
2. No node has been compromised or modified
3. Network consensus is based on **verified identical code**

## The Problem with Non-Reproducible Builds

### Without Binary Equivalence
```
Node A builds from source → Binary A (hash: abc123...)
Node B builds from source → Binary B (hash: def456...)
Node C builds from source → Binary C (hash: 789xyz...)

Result: DIFFERENT BINARIES
- Cannot verify network integrity
- Cannot detect compromised nodes
- Cannot trust consensus
- Decentralization is FAKE
```

### With Binary Equivalence (Reproducible Builds)
```
Node A builds from source → Binary (hash: abc123...)
Node B builds from source → Binary (hash: abc123...)
Node C builds from source → Binary (hash: abc123...)

Result: IDENTICAL BINARIES
✓ Network integrity verified
✓ Compromised nodes detectable
✓ Consensus trustworthy
✓ TRUE decentralization
```

## Reproducible Build Requirements

### 1. Deterministic Compilation

All builds must produce **bit-for-bit identical** binaries:

```dockerfile
# WRONG - Non-deterministic
FROM ubuntu:latest
RUN apt-get update && apt-get install -y build-essential
RUN git clone https://github.com/repo/project.git
RUN cd project && make

# RIGHT - Deterministic
FROM ubuntu:22.04@sha256:ac58ff7fe7... 
ENV SOURCE_DATE_EPOCH=1609459200
RUN apt-get update && apt-get install -y \
    build-essential=12.9ubuntu3 \
    git=1:2.34.1-1ubuntu1
RUN git clone --depth 1 --branch v1.0.0 https://github.com/repo/project.git
RUN cd project && make CFLAGS="-ffile-prefix-map=$(pwd)=."
```

### 2. Fixed Dependencies

**All dependencies must be pinned to exact versions:**

```dockerfile
# Python - WRONG
RUN pip install requests flask

# Python - RIGHT
RUN pip install --no-cache-dir \
    requests==2.28.1 \
    flask==2.2.2
```

```dockerfile
# Go - WRONG
RUN go get github.com/package/module

# Go - RIGHT
RUN go install github.com/package/module@v1.2.3
# Or use go.mod with exact versions
```

```dockerfile
# Debian/Ubuntu - WRONG
RUN apt-get install -y package

# Debian/Ubuntu - RIGHT
RUN apt-get install -y package=1.2.3-4ubuntu1
```

### 3. Timestamp Normalization

**Remove build timestamps:**

```bash
# Set fixed timestamp for all files
export SOURCE_DATE_EPOCH=1609459200

# Strip timestamps from binaries
strip --strip-all --remove-section=.comment --remove-section=.note binary

# Normalize file modification times
find . -exec touch -d "@${SOURCE_DATE_EPOCH}" {} +
```

### 4. Path Normalization

**Remove build path dependencies:**

```makefile
# WRONG - Embeds build path
CFLAGS = -g -O2

# RIGHT - Strips build path
CFLAGS = -g -O2 -ffile-prefix-map=$(PWD)=.
```

### 5. Locale/Environment Normalization

```dockerfile
# Set fixed locale
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TZ=UTC

# Disable randomization
ENV PYTHONHASHSEED=0
```

## Privateness Network Implementation

### Emercoin Core

```dockerfile
FROM debian:bullseye-20231009-slim@sha256:...

ENV SOURCE_DATE_EPOCH=1609459200
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Fixed version download
ARG EMERCOIN_VERSION=0.8.5
RUN wget https://github.com/emercoin/emercoin/releases/download/v${EMERCOIN_VERSION}/emercoin-${EMERCOIN_VERSION}-x86_64-linux-gnu.tar.gz
RUN echo "expected_sha256_hash  emercoin-${EMERCOIN_VERSION}-x86_64-linux-gnu.tar.gz" | sha256sum -c

# Verify binary hash
RUN sha256sum emercoind > /emercoin.hash
```

### Skywire

```dockerfile
FROM golang:1.21.3-bullseye@sha256:...

ENV SOURCE_DATE_EPOCH=1609459200
ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=amd64

# Fixed version
ARG SKYWIRE_VERSION=v0.6.0
RUN git clone --depth 1 --branch ${SKYWIRE_VERSION} https://github.com/skycoin/skywire.git

# Reproducible build flags
RUN cd skywire && go build \
    -trimpath \
    -ldflags="-s -w -buildid=" \
    -o /usr/local/bin/skywire-visor \
    ./cmd/skywire-visor

# Verify binary hash
RUN sha256sum /usr/local/bin/skywire-visor > /skywire.hash
```

### pyuheprng

```dockerfile
FROM python:3.11.6-slim-bullseye@sha256:...

ENV SOURCE_DATE_EPOCH=1609459200
ENV PYTHONHASHSEED=0
ENV LANG=C.UTF-8

# Fixed versions
RUN pip install --no-cache-dir \
    flask==2.3.3 \
    requests==2.31.0 \
    pycryptodome==3.19.0

# Fixed commit hash
ARG PYUHEPRNG_COMMIT=abc123def456...
RUN git clone https://github.com/ness-network/pyuheprng.git && \
    cd pyuheprng && \
    git checkout ${PYUHEPRNG_COMMIT}

# Normalize timestamps
RUN find /app -exec touch -d "@${SOURCE_DATE_EPOCH}" {} +
```

## Verification Process

### 1. Build Hash Manifest

Each image must publish its binary hashes:

```bash
# Generate manifest
docker run ness-network/emercoin-core sha256sum /usr/local/bin/emercoind > emercoin.manifest
docker run ness-network/skywire sha256sum /usr/local/bin/skywire-visor > skywire.manifest
docker run ness-network/pyuheprng find /app -type f -exec sha256sum {} \; > pyuheprng.manifest
```

### 2. Manifest Signing

Sign manifests with Emercoin blockchain:

```bash
# Sign manifest
emercoin-cli signmessage <address> $(cat emercoin.manifest)

# Store in blockchain
emercoin-cli name_new "ness:manifest:emercoin:0.8.5" \
    '{"hash":"abc123...","signature":"xyz789...","timestamp":1609459200}'
```

### 3. Node Verification

Every node verifies binary equivalence:

```bash
#!/bin/bash
# verify-node.sh

# Get expected hash from blockchain
EXPECTED_HASH=$(emercoin-cli name_show "ness:manifest:emercoin:0.8.5" | jq -r '.hash')

# Calculate actual hash
ACTUAL_HASH=$(sha256sum /usr/local/bin/emercoind | cut -d' ' -f1)

# Compare
if [ "$EXPECTED_HASH" != "$ACTUAL_HASH" ]; then
    echo "ERROR: Binary hash mismatch!"
    echo "Expected: $EXPECTED_HASH"
    echo "Actual:   $ACTUAL_HASH"
    echo "NODE IS COMPROMISED OR RUNNING WRONG VERSION"
    exit 1
fi

echo "✓ Binary verified - node is legitimate"
```

### 4. Network Consensus

Nodes only accept connections from verified nodes:

```python
def verify_peer(peer_address):
    # Get peer's binary hash
    peer_hash = peer.get_binary_hash()
    
    # Get expected hash from blockchain
    expected_hash = emercoin.name_show("ness:manifest:emercoin:0.8.5")['hash']
    
    # Verify signature
    if not emercoin.verifymessage(expected_hash, signature):
        return False
    
    # Compare hashes
    if peer_hash != expected_hash:
        print(f"REJECTED: Peer {peer_address} has different binary")
        return False
    
    return True
```

## Multi-Architecture Considerations

**Each architecture must have its own manifest:**

```
ness:manifest:emercoin:0.8.5:amd64   → hash: abc123...
ness:manifest:emercoin:0.8.5:arm64   → hash: def456...
ness:manifest:emercoin:0.8.5:armv7   → hash: 789xyz...
```

Nodes verify against their architecture's manifest.

## Docker Image Verification

### Image Digests (Content-Addressable)

```bash
# Build with digest
docker build -t ness-network/emercoin-core:0.8.5 .
docker push ness-network/emercoin-core:0.8.5

# Get digest
DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' ness-network/emercoin-core:0.8.5)
# ness-network/emercoin-core@sha256:abc123...

# Store digest in blockchain
emercoin-cli name_new "ness:image:emercoin:0.8.5" \
    '{"digest":"sha256:abc123...","arch":"amd64"}'
```

### Pull by Digest (Not Tag)

```yaml
# docker-compose.yml
services:
  emercoin-core:
    # WRONG - tag can be changed
    image: ness-network/emercoin-core:0.8.5
    
    # RIGHT - digest is immutable
    image: ness-network/emercoin-core@sha256:abc123def456...
```

## Build Verification Script

```bash
#!/bin/bash
# verify-reproducible-build.sh

set -e

IMAGE=$1
EXPECTED_MANIFEST=$2

echo "Building image: $IMAGE"
docker build -t $IMAGE .

echo "Extracting binaries..."
CONTAINER=$(docker create $IMAGE)
docker cp $CONTAINER:/usr/local/bin ./verify-bin
docker rm $CONTAINER

echo "Calculating hashes..."
find ./verify-bin -type f -exec sha256sum {} \; | sort > actual.manifest

echo "Comparing with expected manifest..."
if diff -u $EXPECTED_MANIFEST actual.manifest; then
    echo "✓ BUILD IS REPRODUCIBLE - Binary equivalent verified"
    exit 0
else
    echo "✗ BUILD IS NOT REPRODUCIBLE - Binaries differ"
    echo "This is BULLSHIT - fix the build process"
    exit 1
fi
```

## Continuous Verification

### Automated Build Verification

```yaml
# .github/workflows/verify-reproducible.yml
name: Verify Reproducible Builds

on:
  push:
    branches: [main]
  pull_request:

jobs:
  verify:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        image: [emercoin-core, skywire, pyuheprng, privateness]
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Build image (attempt 1)
        run: docker build -t test-${{ matrix.image }}-1 ./${{ matrix.image }}
      
      - name: Extract binaries (attempt 1)
        run: |
          docker create --name test1 test-${{ matrix.image }}-1
          docker cp test1:/usr/local/bin ./bin1
          docker rm test1
      
      - name: Build image (attempt 2)
        run: docker build -t test-${{ matrix.image }}-2 ./${{ matrix.image }}
      
      - name: Extract binaries (attempt 2)
        run: |
          docker create --name test2 test-${{ matrix.image }}-2
          docker cp test2:/usr/local/bin ./bin2
          docker rm test2
      
      - name: Compare binaries
        run: |
          diff -r ./bin1 ./bin2
          if [ $? -eq 0 ]; then
            echo "✓ Reproducible build verified"
          else
            echo "✗ Build is not reproducible - FAIL"
            exit 1
          fi
```

## Why This Matters

### Without Binary Equivalence
- ❌ Cannot verify node integrity
- ❌ Cannot detect compromised nodes
- ❌ Cannot trust network consensus
- ❌ Centralized trust in image publisher
- ❌ **Decentralization is fake**

### With Binary Equivalence
- ✅ Every node verifies every other node
- ✅ Compromised nodes instantly detected
- ✅ Network consensus mathematically trustworthy
- ✅ No trust in any central authority
- ✅ **TRUE decentralization**

## Implementation Checklist

For each service in privateness.network:

- [ ] Pin all base images to digest (not tag)
- [ ] Pin all dependencies to exact versions
- [ ] Set `SOURCE_DATE_EPOCH` for timestamp normalization
- [ ] Use `-trimpath` and `-ffile-prefix-map` for path normalization
- [ ] Set fixed locale/environment variables
- [ ] Generate and publish binary hash manifest
- [ ] Sign manifest with Emercoin blockchain
- [ ] Implement node verification on startup
- [ ] Implement peer verification before connection
- [ ] Add automated reproducible build verification
- [ ] Document exact build environment

## Conclusion

**Binary equivalence is not optional - it's the foundation of decentralization.**

Without it, you're just running a distributed system with centralized trust. With it, you have a truly trustless, verifiable, decentralized network.

**All nodes must be binary equivalent, or it's bullshit.** ✓

## Bonus: Incentive Security

Binary equivalence enables **trustless incentivization of hostile nodes**.

You can securely pay node operators (even if they're actively hostile) because:
1. Binary verification proves they're running legitimate code
2. Challenge-response proves they're actually executing it
3. Proof-of-work proves they did the work
4. Payment only happens if all verifications pass

**Result**: Even hostile actors are economically incentivized to run legitimate code.

See [INCENTIVE-SECURITY.md](INCENTIVE-SECURITY.md) for complete details on rewarding hostile nodes.
