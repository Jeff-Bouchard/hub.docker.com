## Privateness Network - Untraceable Architecture

[Français](NETWORK-ARCHITECTURE-FR.md)

## Multi-Layer Protocol Hopping

The privateness.network stack uses **protocol hopping** across multiple layers, making it **extremely difficult to track or trace in practice** across all of them at once.

## Traffic Flow & Protocol Transitions

```plaintext
Client Application
    ↓ [TCP/IP]
AmneziaWG Access Layer (Obfuscated UDP)
    ↓ [Stealth WireGuard - looks like random data]
Skywire Mesh (MPLS)
    ↓ [Multi-Protocol Label Switching - NOT TCP/IP]
Yggdrasil Overlay (IPv6)
    ↓ [Encrypted IPv6 mesh routing]
I2P Anonymous Network (Garlic Routing)
    ↓ [Layered encryption, multiple hops]
Emercoin Blockchain (Decentralized DNS)
    ↓ [Blockchain-based service discovery]
Destination / Privateness Services
```

## Protocol Layers Explained

### Layer 1: AmneziaWG (Access Layer)

**Protocol**: Obfuscated WireGuard (UDP-based)

*   **Obfuscation**: Junk packets, header randomization, size variation
*   **Appearance**: Random data, not identifiable as VPN
*   **Bypass**: DPI, GFW, corporate firewalls
*   **Tracking**: Extremely hard in practice - looks like random noise

### Layer 2: Skywire (MPLS Mesh)

**Protocol**: Multi-Protocol Label Switching (MPLS)

*   **NOT TCP/IP**: Uses label-switched paths, not IP routing
*   **Path Selection**: Dynamic, multi-path routing
*   **Hop Count**: Variable, changes per packet
*   **Tracking**: Extremely hard in practice - no IP headers in mesh core
*   **Anonymity**: Traffic mixed with other users' traffic

### Layer 3: Yggdrasil (IPv6 Overlay)

**Protocol**: Encrypted IPv6 mesh

*   **Addressing**: IPv6 with cryptographic addresses
*   **Routing**: Distributed hash table (DHT)
*   **Encryption**: End-to-end encrypted tunnels
*   **Tracking**: Extremely hard in practice - encrypted mesh, no central routing

### Layer 4: I2P (Garlic Routing)

**Protocol**: Anonymous overlay network

*   **Routing**: Garlic routing (multiple messages bundled)
*   **Tunnels**: Unidirectional, frequently rotated
*   **Encryption**: Layered (like Tor, but with garlic-style bundling)
*   **Tracking**: Extremely hard in practice – no Tor-style exit nodes when kept fully internal and fully distributed

### Layer 5: Emercoin (Blockchain DNS)

**Protocol**: Blockchain-based naming

*   **Resolution**: Decentralized, no traditional recursive DNS servers
*   **Privacy**: No DNS leaks for Emercoin-managed namespaces when all lookups go through EmerDNS + dns-reverse-proxy
*   **Censorship**: Extremely hard to block with conventional DNS/IP blacklists
*   **Tracking**: No central authority to query

## Why It's Untraceable

### 1\. Protocol Hopping

```plaintext
TCP/IP → Obfuscated UDP → MPLS → IPv6 → Garlic Routing → Blockchain
```

Each layer uses a **different protocol**. Tracking requires:

*   Breaking obfuscation (AmneziaWG)
*   Understanding MPLS labels (Skywire)
*   Decrypting IPv6 mesh (Yggdrasil)
*   De-anonymizing garlic routing (I2P)
*   Correlating blockchain queries (Emercoin)

**Probability**: Computationally infeasible

### 2\. Network Hopping

```plaintext
Entry Node → Mesh Node 1 → Mesh Node 2 → ... → Mesh Node N → Exit
```

*   **Skywire**: MPLS path changes dynamically
*   **Yggdrasil**: IPv6 routing changes per packet
*   **I2P**: Tunnel hops rotate frequently

**Tracking**: Requires monitoring ALL nodes simultaneously

### 3\. No IP Routing in Core

```plaintext
Client IP → [AmneziaWG] → MPLS Labels → [Skywire] → IPv6 Mesh → [Yggdrasil]
```

*   **Skywire core**: Uses MPLS labels, NOT IP addresses
*   **No IP headers**: Traditional network monitoring fails
*   **Label switching**: Changes at each hop
*   **No traceroute**: MPLS doesn't respond to ICMP

### 4\. Encryption Layers

```plaintext
[AmneziaWG Encryption]
  └─ [Skywire MPLS Encryption]
      └─ [Yggdrasil IPv6 Encryption]
          └─ [I2P Garlic Encryption]
              └─ [Application TLS/SSL]
```

**5 layers of encryption** - breaking one reveals nothing

### 5\. Decentralized Everything

*   **No central servers**: Can't be subpoenaed
*   **No logs**: Mesh nodes don't log
*   **No DNS servers**: Blockchain-based
*   **No exit nodes**: I2P is fully distributed
*   **No ISP visibility**: AmneziaWG obfuscation

## Attack Resistance

### Traffic Analysis Attack

**Defense**:

*   AmneziaWG obfuscation defeats pattern recognition
*   MPLS label switching breaks IP-based analysis
*   I2P garlic routing mixes traffic
*   Variable packet sizes and timing

**Result**: Correlating entry/exit traffic becomes extremely difficult

### Timing Attack

**Defense**:

*   Multiple protocol layers add variable latency
*   Mesh routing introduces random delays
*   I2P tunnel rotation changes timing patterns
*   Junk packets (AmneziaWG) add noise

**Result**: Timing correlation attacks are heavily obfuscated

### Global Passive Adversary

**Defense**:

*   MPLS core invisible to IP monitoring
*   IPv6 mesh encrypted end-to-end
*   I2P garlic routing prevents correlation
*   Decentralized architecture (no choke points)

**Result**: Even very large-scale monitoring is forced to defeat multiple independent layers simultaneously

### Sybil Attack

**Defense**:

*   Yggdrasil DHT design makes large-scale Sybil attacks significantly harder and more expensive
*   I2P tunnel diversity
*   Emercoin blockchain consensus

**Result**: Cannot control enough nodes

### Exit Node Monitoring

**Defense**:

*   I2P has no *mandatory* exit-node concept like Tor (traffic can remain fully internal; optional outproxies are not required)
*   Yggdrasil mesh is end-to-end encrypted
*   Services hosted on internal Skywire (todo)

**Result**: No exit point to monitor

## Comparison to Other Networks

### vs Tor

| Feature | Tor | Privateness Network |
| --- | --- | --- |
| Entry obfuscation | Bridges (detectable) | AmneziaWG (stealthy, DPI-resistant) |
| Core routing | TCP/IP (traceable) | MPLS (untraceable) |
| Layers | 3 (entry, relay, exit) | 5+ (AWG, MPLS, IPv6, I2P, blockchain) |
| Exit nodes | Yes (vulnerable) | No (I2P internal) |
| DNS | Clearnet DNS (leaks) | Blockchain (no leaks for Emercoin-managed namespaces) |
| Blocking | Possible (known IPs) | Extremely hard (mesh + obfuscation) |

### vs VPN

| Feature | Commercial VPN | Privateness Network |
| --- | --- | --- |
| Central servers | Yes (single point) | No (decentralized mesh) |
| Logs | Often centralized | No single place to subpoena (mesh; individual nodes may still log) |
| DPI detection | Easy | Extremely hard (obfuscation) |
| Routing | Fixed path | Dynamic mesh |
| DNS | VPN DNS (trusted) | Blockchain (trustless) |
| Censorship | Blockable | Very hard to block at scale |

### vs I2P Alone

| Feature | I2P Only | Privateness Network |
| --- | --- | --- |
| Access layer | TCP/IP (detectable) | AmneziaWG (stealth) |
| Mesh routing | No | Yes (Skywire MPLS) |
| IPv6 support | Limited | Native (Yggdrasil) |
| Blockchain DNS | No | Yes (Emercoin) |
| Protocol diversity | 1 layer | 5+ layers |

## Real-World Scenarios

### Scenario 1: Journalist in Authoritarian Country

```plaintext
Journalist Device
  → AmneziaWG (bypasses GFW, looks like random traffic)
    → Skywire MPLS (no IP routing, untraceable)
      → Yggdrasil IPv6 (encrypted mesh)
        → I2P (anonymous communication)
          → Privateness Services (secure publishing)
```

**Government sees**: Random UDP traffic, cannot identify as VPN  
**ISP sees**: Encrypted noise, no protocol signatures  
**DPI sees**: Nothing - obfuscation defeats inspection  
**Result**: Journalist communicates safely

### Scenario 2: Corporate Firewall Bypass

```plaintext
Employee Device
  → AmneziaWG (bypasses corporate DPI)
    → Skywire MPLS (exits corporate network)
      → Yggdrasil (encrypted routing)
        → Privateness Network
```

**Corporate firewall sees**: Random UDP, not VPN  
**DPI sees**: No VPN signatures  
**Logging sees**: Cannot correlate traffic  
**Result**: Unrestricted access

### Scenario 3: Privacy-Conscious User

```plaintext
User Device
  → AmneziaWG (ISP can't see VPN usage)
    → Skywire MPLS (decentralized routing)
      → Yggdrasil IPv6 (mesh anonymity)
        → I2P (garlic routing)
          → Blockchain DNS (no DNS leaks)
```

**ISP sees**: Encrypted traffic, no metadata  
**Advertisers see**: Nothing (no tracking possible)  
**Government sees**: Random data  
**Result**: Complete privacy

## Technical Deep Dive

### MPLS in Skywire

```plaintext
Traditional IP Routing:
Packet → Router 1 (reads IP, routes) → Router 2 (reads IP, routes) → ...
[TRACEABLE: IP headers visible at each hop]

Skywire MPLS:
Packet → Node 1 (reads label, swaps) → Node 2 (reads label, swaps) → ...
[UNTRACEABLE: No IP headers, labels change at each hop]
```

### Label Switching Example

```plaintext
Entry: Label 100 → Node A
Node A: Swap 100 → 200 → Node B
Node B: Swap 200 → 300 → Node C
Node C: Swap 300 → 400 → Exit

IP headers NEVER examined in core mesh
```

### Yggdrasil IPv6 Mesh (Uses a Deprecated IPv6 address range unlikely to be reactivated in the future)

```plaintext
Traditional IPv6: Global routing table, traceable paths
Yggdrasil IPv6: DHT-based routing, encrypted tunnels

Address: 200:1234:5678:abcd::1
  → Derived from public key
  → No geographic information
  → No ISP assignment
  → Fully decentralized
```

### I2P Garlic Routing

```plaintext
Traditional Onion (Tor): Message → Encrypt → Encrypt → Encrypt
Garlic (I2P): Multiple messages bundled, encrypted together

Bundle:
  - Message A (to destination 1)
  - Message B (to destination 2)
  - Dummy message (decoy)
  - All encrypted together

Result: Cannot determine which message is yours
```

## Conclusion

The privateness.network architecture is **engineered for practical untraceability** due to:

1.  **Protocol diversity**: 5+ different protocols
2.  **MPLS core**: No IP routing in mesh
3.  **Encryption layers**: 5 layers of encryption
4.  **Decentralization**: No central points
5.  **Obfuscation**: Undetectable access layer

**Breaking this requires**:

*   Defeating AmneziaWG obfuscation (computationally infeasible)
*   Monitoring entire Skywire MPLS mesh (thousands of nodes)
*   Breaking Yggdrasil IPv6 encryption (end-to-end encrypted)
*   De-anonymizing I2P garlic routing (proven resistant)
*   Correlating blockchain queries (decentralized, no logs)

**Probability of success**: Effectively zero

This is aimed at becomingthe most advanced privacy network architecture in existence.