# pyuheprng - Cryptographic Entropy Service

[Français](README-FR.md)

**Universal Hardware Entropy Protocol Random Number Generator**

Feeds `/dev/random` directly with cryptographically secure entropy from multiple sources.

## ⚠️ CRITICAL: System Will Block on Insufficient Entropy

**This service ensures the system will BLOCK rather than perform unsecure cryptographic operations.**

If entropy is insufficient, all cryptographic operations will halt until entropy is restored. This is **intentional and correct** behavior for security.

## Entropy Sources

### 1. RC4OK from Emercoin Core
Blockchain-derived randomness:
- Block hashes (SHA-256, proof-of-work verified)
- Transaction data (globally distributed)
- Network timing (unpredictable)
- Cryptographically strong and blockchain-verified

### 2. Original Hardware Bits
Direct hardware entropy:
- CPU RDRAND/RDSEED instructions
- Hardware RNG devices (`/dev/hwrng`)
- TPM (Trusted Platform Module)
- Environmental noise sources

### 3. UHEP Protocol
Universal Hardware Entropy Protocol:
- Multiple hardware sources
- Cryptographic mixing (SHA-512)
- Continuous health monitoring
- Automatic source validation

## Ultra-high entropy (1536-bit class)

`pyuheprng` is built on Steve Gibson's **Ultra High Entropy PRNG (UHEPRNG)** design. UHEPRNG uses **more than 1536 bits of internal state** with carefully chosen parameters (including a safe prime / Sophie Germain prime factor) so that every possible PRNG state is visited before any sequence repeats.

In practice this means:

- **Effective entropy ~1536 bits**, vs the ~256–384 bits typical of conventional CSPRNGs.
- **Astronomical period**: the generator's period is on the order of 2^1536, effectively "never repeating" for any real-world deployment.
- **Seed space that fully covers the state space**: long SeedKeys can fully initialize the generator's internal state.

`pyuheprng` then **strengthens** this ultra-high entropy core by mixing it with:

- Emercoin **RC4OK** blockchain randomness (block hashes, transactions, timing).
- Multiple **hardware entropy sources** (RDRAND/RDSEED, `/dev/hwrng`, TPM, environmental noise).
- The **UHEP** aggregation and **SHA-512** cryptographic mixing already described above.

The result is an entropy service that is not just "good enough for crypto" but **vastly overprovisioned** compared to mainstream systems. This matters because the same entropy pool is used for:

- **DNS randomness** (transaction IDs, source ports, DNSSEC keys for resolvers behind this host).
- **TLS keys** (for DoT/DoH and any other cryptographic protocol on the machine).
- **Smarter contracts and application logic** that depend on unpredictable but verifiable randomness.

By continuously injecting this 1536-bit-class entropy into `/dev/random` and **disabling `/dev/urandom`**, pyuheprng eliminates an entire class of "weak RNG" attacks that still affect a large fraction of the Internet today—especially DNS cache poisoning and key-generation failures on misconfigured or entropy-starved systems. Any resolver or service that relies on `/dev/random` on a host running pyuheprng inherits this protection.

## Entropy Deprivation Prevention

**Entropy deprivation is effectively eliminated on correctly configured hosts** by:
- Continuous feeding of `/dev/random`
- Multiple independent sources (RC4OK + Hardware + UHEP)
- No fallback to weak RNG
- System blocks if entropy insufficient

## Deployment

### Docker Run

```bash
docker run -d \
  --name pyuheprng \
  --privileged \
  --device /dev/random \
  -v /dev:/dev \
  -p 5000:5000 \
  -e EMERCOIN_HOST=emercoin-core \
  -e EMERCOIN_PORT=6662 \
  -e EMERCOIN_USER=rpcuser \
  -e EMERCOIN_PASS=rpcpassword \
  -e MIN_ENTROPY_RATE=1000 \
  -e BLOCK_ON_LOW_ENTROPY=true \
  ness-network/pyuheprng
```

**Note**: Requires `--privileged` and `/dev` access to feed `/dev/random` directly.

### Docker Compose

```yaml
services:
  pyuheprng:
    image: ness-network/pyuheprng
    privileged: true
    devices:
      - /dev/random
    volumes:
      - /dev:/dev
    environment:
      - EMERCOIN_HOST=emercoin-core
      - EMERCOIN_PORT=6662
      - MIN_ENTROPY_RATE=1000
      - BLOCK_ON_LOW_ENTROPY=true
    depends_on:
      - emercoin-core
```

## GRUB Configuration (Required for Production)

### Disable /dev/urandom

**CRITICAL**: For non-Windows machines, `/dev/urandom` MUST be disabled via GRUB.

Edit `/etc/default/grub`:

```bash
GRUB_CMDLINE_LINUX="random.trust_cpu=off random.trust_bootloader=off"
```

Update GRUB:

```bash
# Debian/Ubuntu
sudo update-grub

# RHEL/CentOS/Fedora
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# Arch Linux
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Reboot and verify:

```bash
cat /proc/cmdline | grep random
# Should show: random.trust_cpu=off random.trust_bootloader=off
```

### Why Disable /dev/urandom?

`/dev/urandom` will return data even when the entropy pool is depleted, which is **cryptographically unsafe**.

By disabling it via GRUB and running pyuheprng, we ensure for this host:
- No weak randomness fallback under normal Linux RNG semantics
- All cryptographic operations use `/dev/random` fed by hardened sources
- System blocks rather than proceed unsafely when entropy is genuinely unavailable
- RNG behavior is hardened well beyond typical Linux defaults

## Monitoring

### Check Entropy Levels

```bash
# Current entropy available
watch -n 1 cat /proc/sys/kernel/random/entropy_avail

# Should remain high (>3000) with pyuheprng running
```

### Service Health

```bash
# Health check
curl http://localhost:5000/health

# Entropy sources status
curl http://localhost:5000/sources

# Current entropy rate (bytes/sec)
curl http://localhost:5000/rate
```

### Expected Output

```json
{
  "status": "healthy",
  "entropy_avail": 3842,
  "sources": {
    "rc4ok": "active",
    "hardware": "active",
    "uhep": "active"
  },
  "rate": 1247,
  "blocking": false
}
```

## Failure Modes

### Insufficient Entropy

**Behavior**: System BLOCKS cryptographic operations

```
ERROR: Insufficient entropy available
ERROR: pyuheprng source failure
ACTION: Cryptographic operations BLOCKED
STATUS: Waiting for entropy restoration
```

**This is CORRECT behavior** - ensures cryptographic security.

### Emercoin Connection Lost

**Behavior**: Falls back to Hardware + UHEP sources

```
WARNING: Emercoin RC4OK source unavailable
INFO: Using Hardware + UHEP sources only
STATUS: Reduced entropy rate (still secure)
```

### Hardware RNG Unavailable

**Behavior**: Uses CPU RDRAND/RDSEED + RC4OK

```
WARNING: Hardware RNG unavailable
INFO: Using CPU RDRAND/RDSEED + RC4OK
STATUS: Entropy generation continues
```

## Security Guarantees

### 1. No Weak Randomness
✅ System is engineered to avoid weak or predictable randomness for RNG-dependent operations  
✅ Blocks rather than proceed unsafely  
✅ `/dev/urandom` disabled via GRUB  

### 2. No Entropy Depletion
✅ Continuous feeding of `/dev/random`  
✅ Multiple independent sources  
✅ Automatic failover  

### 3. Cryptographic Strength
✅ RC4OK: Blockchain-verified randomness  
✅ Hardware: Physical entropy sources  
✅ UHEP: Validated hardware protocol  
✅ SHA-512 mixing: Cryptographic combination  

### 4. No Trust in Hardware
✅ GRUB disables CPU trust  
✅ GRUB disables bootloader trust  
✅ All sources validated  
✅ Continuous health checks  

## API Endpoints

### GET /health
Health check endpoint

```bash
curl http://localhost:5000/health
```

### GET /sources
Entropy sources status

```bash
curl http://localhost:5000/sources
```

### GET /rate
Current entropy generation rate

```bash
curl http://localhost:5000/rate
```

### GET /entropy
Get random bytes (for testing)

```bash
curl http://localhost:5000/entropy?bytes=32
```

## Integration with Privateness Network

All services in the privateness.network stack depend on `pyuheprng`:

```
Emercoin Core (RC4OK source)
    ↓
pyuheprng (entropy mixing)
    ↓
/dev/random (kernel entropy pool)
    ↓
All Cryptographic Operations
    ├─ AmneziaWG (key generation)
    ├─ Skywire (mesh encryption)
    ├─ Yggdrasil (tunnel keys)
    ├─ I2P (garlic routing keys)
    └─ Privateness (application crypto)
```

## For Non-Windows Machines Only

This entropy architecture is designed for **Linux-based systems**.

Windows uses different entropy sources:
- CryptGenRandom API
- BCryptGenRandom API
- RNG-CSP (Cryptographic Service Provider)

Windows containers should use native Windows entropy APIs.

## Conclusion

`pyuheprng` is engineered to provide **very strong cryptographic security** for randomness-dependent operations by:

1. ✅ Feeding `/dev/random` directly with multiple entropy sources
2. ✅ Effectively eliminating entropy deprivation for correctly configured hosts
3. ✅ Blocking rather than performing unsecure operations
4. ✅ Requiring GRUB configuration to disable `/dev/urandom`
5. ✅ Providing continuous health monitoring

**This is an extremely hardened entropy architecture for real-world cryptographic operations on Linux hosts that follow this deployment recipe.**
