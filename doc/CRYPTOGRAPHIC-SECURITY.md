# Cryptographic Security - Entropy Design

[Français](CRYPTOGRAPHIC-SECURITY-FR.md)

## Security behaviour (experimental)

By design, this stack is configured to **block** certain cryptographic operations if it believes that available entropy may be insufficient. This favours perceived cryptographic safety over availability and **may not be appropriate for all deployments**.

This behaviour is **experimental** and has **not** been subject to formal cryptographic review. Operators should review the references at the end of this document (in particular the Linux RNG documentation and UHEPRNG description) and decide whether this trade-off makes sense for their own environment.

## Entropy Architecture

### pyuheprng - entropy feeder for `/dev/random`

The `pyuheprng` service aims to provide **cryptographically strong entropy** by feeding `/dev/random` directly with a mix of:

1. **RC4OK from Emercoin Core**: Blockchain-derived randomness (see Emercoin / RC4OK references below)
2. **Original Hardware Bits**: Direct hardware entropy sources
3. **UHEP aggregation (internal design)**: A project-specific framework that aggregates and mixes hardware-related random sources. This is an internal design choice, not a standardized external protocol.

**For non-Windows machines only** - Windows uses different entropy sources.

#### Ultra-high entropy (1536-bit class) and DNS impact

`pyuheprng` builds on Steve Gibson's **Ultra High Entropy PRNG (UHEPRNG)** design (see [GRC UHEPRNG](https://www.grc.com/otg/uheprng.htm)), which describes **more than 1536 bits of internal state** with parameters chosen so that every internal state is visited before any sequence repeats. In that design this corresponds to an effective entropy on the order of 2^1536, significantly larger than the ~256–384 bits typical of many conventional cryptographic PRNGs. Our implementation adapts these ideas but has **not** been independently analysed.

In Privateness, this ultra-high-entropy core is further mixed with:

- Emercoin **RC4OK** blockchain randomness (block hashes, transactions, timing).
- Multiple **hardware entropy sources** via UHEP aggregation.
- **SHA-512** cryptographic mixing before injection into `/dev/random`.

Because `pyuheprng` **continuously feeds `/dev/random`** and, in the recommended configuration, `/dev/urandom` is not used for cryptographic material on this host, any local service that draws randomness from `/dev/random` is intended to benefit from:

- DNS transaction IDs and source ports that are harder to predict in practice.
- DNSSEC keys and TLS keys (DoT/DoH) that are less likely to be generated under low-entropy conditions on this host.
- A reduced reliance on trivially low-entropy randomness as an attack vector on this host.

This combination of:

- UHEPRNG-style design,
- hardware-related entropy aggregation (UHEP),
- and blockchain-derived randomness (RC4OK),

is relatively uncommon in typical deployments we are aware of. The intent is to **reduce** some DNS entropy-related attack surfaces on the operator's own infrastructure. It does **not** change the behaviour of misconfigured resolvers elsewhere on the Internet, and it should not be treated as a proof that DNS or other protocols are "solved" cryptographically.

### Entropy deprivation mitigation

On correctly configured hosts, this design aims to **reduce the likelihood of entropy starvation** by:

- **Continuous feeding**: pyuheprng constantly feeds `/dev/random`
- **Multiple sources**: RC4OK + hardware bits + UHEP aggregation
- **No fallback to weak RNG**: System blocks if entropy insufficient
- **Direct /dev/random access**: Feeds the kernel entropy pool directly rather than relying only on process-local PRNG state

### `/dev/urandom` policy

In this project we **choose** to avoid `/dev/urandom` for cryptographic material by policy, using only `/dev/random` on Linux hosts.

The Linux RNG documentation ([random(4)](https://man7.org/linux/man-pages/man4/random.4.html)) states that `/dev/urandom` is intended to be suitable for most cryptographic purposes once the entropy pool has been properly initialised. Our configuration is therefore deliberately more conservative than common practice and may introduce additional blocking behaviour without clear benefit in all environments.

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

#### 3. UHEP aggregation (internal design)

This section sketches an internal "UHEP" aggregation pipeline:
- Combines multiple hardware sources
- Cryptographic mixing
- Continuous health monitoring
- Automatic source validation

It is an implementation concept in this project, not a standardized protocol.

### Entropy Mixing

```python
# Cryptographic mixing of entropy sources
mixed_entropy = sha512(rc4ok_entropy + hardware_bits + uhep_data)

# Feed to /dev/random
with open('/dev/random', 'wb') as random_dev:
    random_dev.write(mixed_entropy)
```

## Security Properties (design goals)

### 1. Intended avoidance of weak randomness

The system is **intended** to avoid weak or trivially predictable randomness for RNG-dependent operations, assuming the host is configured as documented.

- `/dev/urandom` is avoided for cryptographic use by policy.
- `pyuheprng` blocks if it cannot obtain entropy from its configured sources.
- Certain cryptographic operations will halt if the system believes there is insufficient entropy.

### 2. Continuous entropy (design goal)

The architecture is designed so that the entropy pool **should not deplete under normal operation** on a correctly configured host, although this has not been formally verified.

- `pyuheprng` feeds `/dev/random` continuously.
- Multiple independent sources are combined.
- There is basic health monitoring and simple failover between sources.

### 3. Cryptographic strength (assumptions)

The design assumes that the underlying primitives and entropy sources are cryptographically strong as described in their own documentation:

- RC4OK: blockchain-driven randomness as implemented by Emercoin (see Emercoin references below).
- Hardware bits: physical entropy devices (e.g. `/dev/hwrng`, RDRAND/RDSEED, TPM).
- UHEP aggregation: aggregation and mixing of hardware-related sources.
- SHA-512 mixing: cryptographic combination function.

### 5. Ed25519 key generation policy (reference implementation)

For Identity Bedrock / Ness identity, the **reference implementation** imposes an additional operational requirement on key generation:

- Ed25519 seeds for long-lived identity keys **MUST** be generated on hosts where:
  - `pyuheprng` is running and reporting healthy status, and
  - `/dev/random` is being continuously fed by `pyuheprng` as described above.
- Key generation code **MUST**:
  - read seed material directly from `/dev/random` (or `getrandom(2)` configured equivalently), and
  - fail fast (refuse to generate a key) if:
    - `pyuheprng` health checks fail, or
    - kernel entropy appears critically low for a sustained period.

This does not claim that keys generated without `pyuheprng` are "insecure" in all environments; it is a **deployment profile** for this stack that treats `pyuheprng`-backed `/dev/random` as the only acceptable entropy source for Ed25519 identity seeds in production.

### 4. Reduced implicit trust in CPU/bootloader

The configuration **tries to reduce implicit trust in CPU/bootloader RNG as a sole entropy source**.

- GRUB is configured to disable CPU trust (`random.trust_cpu=off`).
- GRUB is configured to disable bootloader trust (`random.trust_bootloader=off`).
- Entropy sources are mixed and subject to basic health checks, but not to formal statistical certification.

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

**NEVER use in production** - defeats the intended security properties of this configuration.

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
| Entropy sources | CPU, bootloader (trusted) | RC4OK + Hardware + UHEP aggregation (validated) |
| Blocking behavior | Often avoided | **Enforced when entropy is low** |
| Security model | Best effort | **Model-driven, depends on correct deployment** |

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
Security: Cryptographically secure under standard Linux RNG assumptions once properly initialised
Use case: Cryptographic keys, signatures, critical operations
```

#### /dev/urandom (DISABLED in Privateness)
```
Behavior: Never blocks (returns data even when depleted)
Security: Considered suitable for cryptographic use after initialisation in mainstream Linux guidance; this project disables it by policy to avoid accidental misuse when entropy is low
Use case: Non-critical randomness (NOT for crypto in this stack)
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

### UHEP aggregation (conceptual sketch)

The following shows a conceptual internal UHEP-style aggregator; not all sources are implemented, and this is illustrative rather than a stable API:

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

The Privateness entropy design is intended to **improve the handling of randomness** for entropy-sensitive operations on hosts that follow this deployment model:

1. It attempts to avoid trivially weak randomness by favouring blocking over proceeding when entropy appears low.
2. It tries to keep `/dev/random` supplied via `pyuheprng` on correctly configured hosts.
3. It combines multiple entropy sources (RC4OK + hardware-related inputs + UHEP-style aggregation).
4. It adopts a conservative policy of avoiding `/dev/urandom` for cryptographic material, which is **not** standard Linux practice.
5. It includes basic health monitoring for the entropy feeder.
6. It makes use of Emercoin's RC4OK output as one input, relying on Emercoin's own security properties.

This should be viewed as an **experimental design**, not as a claim of proven or absolute cryptographic security. It has not been audited by external cryptographers. Operators are strongly encouraged to read the external references, consider mainstream guidance around `/dev/urandom` (for example in the Linux `random(4)` man page), and treat this configuration as a set of ideas to evaluate rather than a drop-in replacement for well‑reviewed RNG setups.

## References / Sources

- **Linux kernel random number generator**  
  random(4) man page describing the kernel entropy pool, `/dev/random`, `/dev/urandom`, and `getrandom(2)`:  
  <https://man7.org/linux/man-pages/man4/random.4.html>  
  Background on `/dev/random` and `/dev/urandom` behavior on Unix-like systems:  
  <https://en.wikipedia.org/wiki//dev/random>

- **UHEPRNG (Ultra High Entropy PRNG)**  
  Steve Gibson's description of the ultra-high-entropy PRNG design (1536-bit-class internal state) that this project uses as its conceptual basis:  
  <https://www.grc.com/otg/uheprng.htm>

- **Emercoin / RC4OK / EmerDNS / EmerNVS**  
  Emercoin platform overview: <https://emercoin.com/en/>  
  EmerDNS introduction (blockchain-based DNS, recommended zones):  
  <https://emercoin.com/en/documentation/blockchain-services/emerdns/emerdns-introduction/>  
  EmerNVS overview (Name–Value Storage service):  
  <https://emercoin.com/en/documentation/blockchain-services/emernvs/>  
  EmerDNS + I2P domain name registration example:  
  <https://github.com/emercoin/docs/blob/master/en/020_Blockchain_Services/030_EmerDNS/031_I2P_Domain_Name_Registration_based_on_blockchain.md>  
  RC4OK reference in Emercoin Core release notes (replacement for legacy fast RNG):  
  <https://github.com/emercoin/emercoin/releases>

- **Reproducible builds**  
  Upstream reproducible-builds project describing deterministic builds and binary equivalence:  
  <https://reproducible-builds.org/>
