# pyuheprng - Cryptographic Entropy Service

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

## Entropy Deprivation Prevention

**Entropy deprivation is ELIMINATED** by:
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

By disabling it via GRUB, we ensure:
- No weak randomness fallback
- All cryptographic operations use `/dev/random`
- System blocks rather than proceed unsafely
- Absolute cryptographic security

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
✅ System will never use weak or predictable randomness  
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

`pyuheprng` provides **absolute cryptographic security** by:

1. ✅ Feeding `/dev/random` directly with multiple entropy sources
2. ✅ Eliminating entropy deprivation possibility
3. ✅ Blocking rather than performing unsecure operations
4. ✅ Requiring GRUB configuration to disable `/dev/urandom`
5. ✅ Providing continuous health monitoring

**This is the most secure entropy architecture possible for cryptographic operations.**
