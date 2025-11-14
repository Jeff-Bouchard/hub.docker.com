# Multi-Architecture Support

All Docker images support multiple CPU architectures for maximum compatibility.

## Supported Platforms

### All Images
- **linux/amd64** (x86_64) - Standard Intel/AMD 64-bit
- **linux/arm64** (aarch64) - ARM 64-bit (Raspberry Pi 4/5, Apple Silicon, ARM servers)
- **linux/arm/v7** (armhf) - ARM 32-bit (Raspberry Pi 3, older ARM devices)

## Architecture Detection

### Emercoin Core
- Runtime detection using `dpkg --print-architecture`
- Downloads correct binary for platform:
  - `amd64` → `x86_64-linux-gnu`
  - `arm64` → `aarch64-linux-gnu`
  - `armhf` → `arm-linux-gnueabihf`

### Go-based Services (Skywire, Yggdrasil, DNS Proxy)
- Cross-compiled at build time using `GOOS` and `GOARCH`
- Native binaries for each platform
- Optimized performance

### Python Services (Privateness, PyUHEPRNG, Privatenumer, Tools)
- Python interpreter is multi-arch by default
- Pure Python code runs on all platforms
- Native dependencies compiled during build

### I2P
- Java-based (platform-independent bytecode)
- `_all.deb` package works on all architectures
- JVM handles platform differences

## Building Multi-Arch Images

### Using Docker Buildx (Recommended)
```bash
# Setup buildx builder
docker buildx create --name ness-builder --use

# Build and push for all platforms
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t ness-network/emercoin-core:latest --push .
```

### Automated Script
```bash
./build-multiarch.sh
```

## Testing on Different Architectures

### Using QEMU
```bash
# Install QEMU for emulation
docker run --privileged --rm tonistiigi/binfmt --install all

# Test ARM64 image on x86_64
docker run --platform linux/arm64 ness-network/emercoin-core:latest
```

## Umbrel Compatibility

Umbrel runs on:
- Raspberry Pi 4/5 (arm64)
- x86_64 servers
- ARM-based NAS devices

All ness-network images work seamlessly across these platforms.

## Performance Notes

- **Native builds** (same arch as host) = best performance
- **Emulated builds** (QEMU) = slower but functional
- **Cross-compilation** (Go) = native performance, fast builds
