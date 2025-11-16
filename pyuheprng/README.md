# pyuheprng - Cryptographic Entropy Service

[Français](README-FR.md)

**Universal Hardware Entropy Protocol Random Number Generator**

Feeds `/dev/random` directly with cryptographically secure entropy from multiple sources.

## Behaviour when entropy appears low (experimental)

This service is configured to **block** certain cryptographic operations if it believes that available entropy may be insufficient. This favours perceived cryptographic safety over availability and **may not be appropriate for all deployments**.

This behaviour is **experimental** and has **not** been subject to formal cryptographic review. Operators should review the Linux RNG documentation (for example the `random(4)` man page) and the design notes in `CRYPTOGRAPHIC-SECURITY.md`, and then decide whether this trade-off matches their own threat model and tolerance for blocking.

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

`pyuheprng` is built on Steve Gibson's **Ultra High Entropy PRNG (UHEPRNG)** design (see [GRC UHEPRNG](https://www.grc.com/otg/uheprng.htm)). UHEPRNG uses **more than 1536 bits of internal state** with carefully chosen parameters (including a safe prime / Sophie Germain prime factor) so that every possible PRNG state is visited before any sequence repeats.

In practice this means:

- **Effective entropy ~1536 bits**, vs the ~256–384 bits typical of conventional CSPRNGs.
- **Astronomical period**: the generator's period is on the order of 2^1536, effectively "never repeating" for any real-world deployment.
- **Seed space that fully covers the state space**: long SeedKeys can fully initialize the generator's internal state.

`pyuheprng` then **strengthens** this ultra-high entropy core by mixing it with:

- Emercoin **RC4OK** blockchain randomness (block hashes, transactions, timing).
- Multiple **hardware entropy sources** (RDRAND/RDSEED, `/dev/hwrng`, TPM, environmental noise).
- The **UHEP** aggregation and **SHA-512** cryptographic mixing already described above.

The intent is to provide an entropy service that is **more conservative** than typical mainstream setups. The same entropy pool is used for:

- DNS randomness (transaction IDs, source ports, DNSSEC keys for resolvers behind this host).
- TLS keys (for DoT/DoH and other cryptographic protocols on the machine).
- Smarter contracts and application logic that depend on unpredictable randomness.

By continuously injecting this 1536-bit-class entropy into `/dev/random` and avoiding `/dev/urandom` for cryptographic material by policy, `pyuheprng` aims to **reduce the risk** of "weak RNG" conditions on this particular host (for example, during early boot or under heavy load). It does **not** guarantee the absence of RNG-related attacks, and it does not change how external infrastructure is configured.

## Entropy deprivation mitigation

On correctly configured hosts, the design aims to **reduce the likelihood of entropy starvation** by:
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

## GRUB Configuration (recommended for this profile)

### Disable /dev/urandom

**Note**: For non-Windows machines, `/dev/urandom` is disabled via GRUB as a conservative policy choice, following the Linux RNG documentation (see `random(4)` man page [1]). This is not a claim that `/dev/urandom` is universally unsafe, but rather a design choice for this stack.

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

### Why avoid `/dev/urandom` here?

The Linux RNG documentation (`random(4)`) states that `/dev/urandom` is intended to be suitable for most cryptographic purposes once the kernel entropy pool has been properly initialised. In this project we **choose** to adopt a more conservative policy: avoid `/dev/urandom` for cryptographic material and rely on `/dev/random` fed by `pyuheprng` instead.

The goal is to reduce the chance of using low-entropy randomness on this host, at the cost of potential blocking. This is a design choice for this stack and is **not** a general statement that `/dev/urandom` is universally unsafe.

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

`pyuheprng` is intended to **improve the handling of randomness** for entropy-sensitive operations by:

1. Feeding `/dev/random` directly with multiple entropy sources.
2. Trying to reduce entropy-deprivation situations on correctly configured hosts.
3. Preferring to block rather than proceed when the system believes entropy may be insufficient.
4. Encouraging a conservative `/dev/urandom` policy for this particular profile.
5. Providing basic health monitoring for the entropy feeder.

This should be treated as an **experimental configuration**, not as a claim of proven or absolute cryptographic security. It relies on the correctness of the underlying primitives and on the operator applying the documented deployment steps.

## References / Sources

- **Linux kernel RNG behavior**  
  random(4) man page explaining the kernel entropy pool and the semantics of `/dev/random`, `/dev/urandom`, and `getrandom(2)`:  
  <https://man7.org/linux/man-pages/man4/random.4.html>

- **UHEPRNG (Ultra High Entropy PRNG)**  
  Steve Gibson's description of the ultra-high-entropy PRNG design that this service uses as its conceptual basis for a "1536-bit-class" internal state:  
  <https://www.grc.com/otg/uheprng.htm>

- **Emercoin / RC4OK / EmerDNS / EmerNVS**  
  Emercoin platform overview and blockchain services: <https://emercoin.com/en/>  
  EmerDNS introduction (blockchain-based DNS):  
  <https://emercoin.com/en/documentation/blockchain-services/emerdns/emerdns-introduction/>  
  EmerNVS overview (Name–Value Storage):  
  <https://emercoin.com/en/documentation/blockchain-services/emernvs/>  
  EmerDNS + I2P name mapping example:  
  <https://github.com/emercoin/docs/blob/master/en/020_Blockchain_Services/030_EmerDNS/031_I2P_Domain_Name_Registration_based_on_blockchain.md>  
  RC4OK reference in Emercoin Core release notes:  
  <https://github.com/emercoin/emercoin/releases>

- **Central reference list for this repo**  
  See also `SOURCES.md` at the root of this repository for a consolidated list of external documents used throughout the Privateness Network documentation.
