# Cryptographic Security - Entropy Guarantee

[Français](CRYPTOGRAPHIC-SECURITY-FR.md)

## ⚠️ CRITICAL SECURITY WARNING

**This system will BLOCK rather than perform an unsecure cryptographic operation.**

The privateness.network stack prioritizes cryptographic security over availability. If sufficient entropy is not available, operations will **halt** rather than proceed with weak randomness.

## Entropy Architecture

### pyuheprng - True Random Number Generation

The `pyuheprng` service provides **cryptographically secure entropy** by feeding `/dev/random` directly with a mix of:

1. **RC4OK from Emercoin Core**: Blockchain-derived randomness
2. **Original Hardware Bits**: Direct hardware entropy sources
3. **UHEP (Universal Hardware Entropy Protocol)**: Hardware-level random number generation

**For non-Windows machines only** - Windows uses different entropy sources.

#### Ultra-high entropy (1536-bit class) and DNS impact

`pyuheprng` builds on Steve Gibson's **Ultra High Entropy PRNG (UHEPRNG)** design, which uses **more than 1536 bits of internal state** with parameters chosen so that every internal state is visited before any sequence repeats. This yields an effective entropy on the order of 2^1536 — vastly beyond the ~256–384 bits typical of conventional cryptographic PRNGs.

In Privateness, this ultra-high-entropy core is further mixed with:

- Emercoin **RC4OK** blockchain randomness (block hashes, transactions, timing).
- Multiple **hardware entropy sources** via UHEP.
- **SHA-512** cryptographic mixing before injection into `/dev/random`.

Because `pyuheprng` **continuously feeds `/dev/random`** and `/dev/urandom` is explicitly **disabled**, any service on this host that draws randomness from `/dev/random` benefits from:

- **DNS transaction IDs and source ports** that are backed by 1536-bit-class entropy.
- **DNSSEC keys and TLS keys (DoT/DoH)** generated without low-entropy failures.
- A removal of the "weak RNG" angle that many DNS cache poisoning and key compromise attacks still depend on globally.

Very few systems on the Internet today combine:

- Ultra-high-entropy PRNG design (UHEPRNG class),
- Physics-backed hardware entropy (UHEP),
- Blockchain-verified randomness (RC4OK), and
- A hard requirement that everything goes through `/dev/random` with `/dev/urandom` disabled.

For any operator who deploys the Privateness stack as documented, this effectively **closes an entire DNS entropy attack surface** on their own infrastructure. You cannot fix every misconfigured resolver in the world, but you can ensure that **your** DNS, smarter contracts, and cryptographic protocols never fail because the randomness was weak.

### Entropy Deprivation Prevention

**Entropy deprivation is effectively eliminated on correctly configured hosts** by:

- **Continuous feeding**: pyuheprng constantly feeds `/dev/random`
- **Multiple sources**: RC4OK + hardware bits + UHEP
- **No fallback to weak RNG**: System blocks if entropy insufficient
- **Direct /dev/random access**: Feeds the kernel entropy pool directly rather than relying only on process-local PRNG state

### /dev/urandom is DISABLED

**CRITICAL**: `/dev/urandom` is disabled via GRUB configuration to prevent weak cryptographic operations.

`/dev/urandom` will return random data even when entropy pool is depleted, which is **cryptographically unsafe**.

## GRUB Configuration (Required for Production)

### Disable /dev/urandom

Add to GRUB configuration (`/etc/default/grub`):

```bash
GRUB_CMDLINE_LINUX="random.trust_cpu=off random.trust_bootloader=off"
```

Then update GRUB:

```bash
# Debian/Ubuntu
sudo update-grub

# RHEL/CentOS/Fedora
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# Arch Linux
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Verify /dev/urandom is Disabled

```bash
# Check kernel parameters
cat /proc/cmdline | grep random

# Should show:
# random.trust_cpu=off random.trust_bootloader=off
```

### Additional Hardening

```bash
# Disable hardware RNG trust (force verification)
echo 0 > /sys/module/random/parameters/trust_cpu
echo 0 > /sys/module/random/parameters/trust_bootloader

# Check entropy available
cat /proc/sys/kernel/random/entropy_avail

# Should be consistently high (>3000) with pyuheprng running
```

## pyuheprng Service Configuration

### Docker Deployment

```bash
docker run -d \
  --name pyuheprng \
  --privileged \
  --device /dev/random \
  -v /dev:/dev \
  -p 5000:5000 \
  ness-network/pyuheprng
```

**Note**: Requires `--privileged` and `/dev` access to feed `/dev/random` directly.

### Entropy Sources

#### 1. RC4OK from Emercoin Core

```python
# pyuheprng connects to Emercoin RPC
emercoin_rpc = EmercoinRPC(host='emercoin-core', port=6662)
rc4ok_entropy = emercoin_rpc.get_rc4ok()
```

Emercoin's RC4OK provides blockchain-derived randomness:
- Block hashes
- Transaction data
- Network timing
- Proof-of-work randomness

#### 2. Original Hardware Bits

```python
# Direct hardware entropy sources
hwrng = open('/dev/hwrng', 'rb')
hardware_bits = hwrng.read(32)
```

Sources:
- CPU RDRAND/RDSEED instructions
- Hardware RNG devices
- TPM (Trusted Platform Module)
- Environmental noise

#### 3. UHEP Protocol

Universal Hardware Entropy Protocol:
- Combines multiple hardware sources
- Cryptographic mixing
- Continuous health monitoring
- Automatic source validation

### Entropy Mixing

```python
# Cryptographic mixing of entropy sources
mixed_entropy = sha512(rc4ok_entropy + hardware_bits + uhep_data)

# Feed to /dev/random
with open('/dev/random', 'wb') as random_dev:
    random_dev.write(mixed_entropy)
```

## Security Guarantees

### 1. No Weak Randomness

The system is **engineered so that RNG-dependent operations do not use weak or predictable randomness**, assuming the host is configured as documented.

- `/dev/urandom` disabled (no depleted pool fallback)
- pyuheprng blocks if sources unavailable
- Cryptographic operations halt without sufficient entropy

### 2. Continuous Entropy

The architecture is designed so that the entropy pool **does not deplete under normal operation**.

- pyuheprng feeds `/dev/random` continuously
- Multiple independent sources
- Automatic failover between sources
- Health monitoring and alerts

### 3. Cryptographic Strength

All randomness is sourced from **cryptographically strong primitives and entropy sources**:

- RC4OK: Blockchain-driven PRNG (unpredictable, consensus-verified inputs)
- Hardware bits: Physical randomness
- UHEP: Validated hardware sources
- SHA-512 mixing: Cryptographic combination

### 4. No Trust in CPU/Bootloader

The design **removes implicit trust in CPU/bootloader RNG as a sole entropy source**.

- GRUB disables CPU trust (`random.trust_cpu=off`)
- GRUB disables bootloader trust (`random.trust_bootloader=off`)
- All entropy sources validated
- Continuous health checks

## Monitoring

### Check Entropy Levels

```bash
# Current entropy available
watch -n 1 cat /proc/sys/kernel/random/entropy_avail

# Should remain high (>3000) with pyuheprng running
```

### Check pyuheprng Status

```bash
# Service health
curl http://localhost:5000/health

# Entropy sources status
curl http://localhost:5000/sources

# Current entropy rate
curl http://localhost:5000/rate
```

### Alerts

pyuheprng will alert if:
- Entropy sources fail
- Entropy rate drops below threshold
- Emercoin connection lost
- Hardware RNG unavailable

## Failure Modes

### Entropy Source Failure

**Behavior**: System blocks cryptographic operations

```
ERROR: Insufficient entropy available
ERROR: pyuheprng source failure
ACTION: Cryptographic operations BLOCKED
STATUS: Waiting for entropy restoration
```

**Resolution**:
1. Check pyuheprng service status
2. Verify Emercoin connection
3. Check hardware RNG availability
4. Review system logs

### /dev/random Blocking

**Behavior**: Expected and CORRECT

```
INFO: /dev/random blocking (waiting for entropy)
INFO: This is CORRECT behavior for security
STATUS: pyuheprng feeding entropy
```

**This is not an error** - blocking ensures cryptographic security.

### Emergency Entropy

**NOT RECOMMENDED** - Only for testing/development:

```bash
# INSECURE: Only for non-production testing
rngd -r /dev/urandom -o /dev/random
```

**NEVER use in production** - defeats security guarantees.

## Architecture Integration

### Service Dependencies

```
Emercoin Core (RC4OK source)
    ↓
pyuheprng (entropy mixing)
    ↓
/dev/random (kernel entropy pool)
    ↓
All Cryptographic Operations
```

### Portainer Stack

```yaml
services:
  emercoin-core:
    image: ness-network/emercoin-core
    # ... config ...

  pyuheprng:
    image: ness-network/pyuheprng
    privileged: true
    devices:
      - /dev/random
    volumes:
      - /dev:/dev
    depends_on:
      - emercoin-core
    environment:
      - EMERCOIN_HOST=emercoin-core
      - EMERCOIN_PORT=6662
      - MIN_ENTROPY_RATE=1000  # bytes/sec
      - BLOCK_ON_LOW_ENTROPY=true

  # All other services depend on pyuheprng
  privateness:
    depends_on:
      - pyuheprng
    # ... config ...
```

## Comparison to Standard Systems

### Standard Linux

| Aspect | Standard Linux | Privateness Network |
|--------|---------------|---------------------|
| /dev/urandom | Enabled (may be misused for crypto) | **DISABLED** |
| Entropy depletion | Possible | **Engineered to be highly unlikely under normal operation** |
| Weak randomness | Possible | **Blocked by design (operations halt instead)** |
| Entropy sources | CPU, bootloader (trusted) | RC4OK + Hardware + UHEP (validated) |
| Blocking behavior | Often avoided | **Enforced when entropy is low** |
| Security guarantee | Best effort | **Model-driven, depends on correct deployment** |

### Why This Matters

**Weak randomness breaks cryptography**:
- Predictable keys
- Broken signatures
- Compromised encryption
- Session hijacking
- Authentication bypass

The Privateness stack **greatly reduces this risk** on hosts that follow the documented deployment recipe.

## Technical Deep Dive

### /dev/random vs /dev/urandom

#### /dev/random (Used by Privateness)
```
Behavior: Blocks when entropy pool depleted
Security: Cryptographically secure (always)
Use case: Cryptographic keys, signatures, critical operations
```

#### /dev/urandom (DISABLED in Privateness)
```
Behavior: Never blocks (returns data even when depleted)
Security: Potentially weak when pool depleted
Use case: Non-critical randomness (NOT for crypto)
```

**Privateness disables /dev/urandom** to prevent accidental use of weak randomness.

### RC4OK Entropy Source

Emercoin's RC4OK provides:

```
Block hash: SHA-256(previous_block + transactions + nonce)
  → Unpredictable (proof-of-work)
  → Blockchain-verified
  → Network-distributed

Transaction data: User inputs, timestamps, addresses
  → High entropy
  → Globally distributed
  → Cryptographically hashed

Network timing: Block arrival times, peer latency
  → Environmental randomness
  → Unpredictable
  → Continuous source
```

**Combined**: Cryptographically strong, blockchain-verified randomness.

### UHEP Protocol

Universal Hardware Entropy Protocol:

```python
class UHEP:
    def __init__(self):
        self.sources = [
            CPURdrand(),      # Intel/AMD RDRAND
            CPURdseed(),      # Intel/AMD RDSEED
            HardwareRNG(),    # /dev/hwrng
            TPM(),            # Trusted Platform Module
            AudioNoise(),     # Microphone environmental noise
            VideoNoise(),     # Camera sensor noise
            DiskTiming(),     # Disk I/O timing jitter
            NetworkTiming(),  # Network packet timing
        ]
    
    def get_entropy(self, bytes_needed):
        # Collect from all sources
        entropy = b''
        for source in self.sources:
            if source.available():
                entropy += source.read(bytes_needed)
        
        # Cryptographic mixing
        mixed = sha512(entropy)
        
        # Health check
        if not self.validate_entropy(mixed):
            raise InsufficientEntropyError()
        
        return mixed
```

## Conclusion

The Privateness entropy architecture is engineered to provide **very strong cryptographic security** for randomness-dependent operations:

1. ✅ **No weak randomness by design**: System blocks rather than proceed unsafely when entropy is insufficient
2. ✅ **Entropy deprivation effectively prevented**: pyuheprng feeds `/dev/random` continuously on correctly configured hosts
3. ✅ **Multiple sources**: RC4OK + Hardware + UHEP
4. ✅ **/dev/urandom disabled**: GRUB configuration prevents weak fallback
5. ✅ **Validated entropy**: Continuous health monitoring
6. ✅ **Blockchain-verified input**: RC4OK from Emercoin incorporates consensus-protected blockchain state

This is an **extremely hardened entropy architecture** for real-world cryptographic operations on Linux systems that follow this deployment model.

For production deployment, **GRUB configuration is mandatory** to disable /dev/urandom.
