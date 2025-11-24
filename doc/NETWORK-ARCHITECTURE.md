## Privateness Network - Network Architecture (experimental)

[Français](NETWORK-ARCHITECTURE-FR.md)

## Multi-Layer Protocol Hopping

The privateness.network stack uses **protocol hopping** across multiple layers. The design aim is to make traffic analysis and tracking harder in practice across all of them at once, but there are **no formal anonymity proofs** and the real-world effect depends on deployment.

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

**Protocol**: Obfuscated WireGuard (UDP-based) (see AmneziaWG docs in *References / Sources*)

*   **Obfuscation**: Junk packets, header randomization, size variation
*   **Appearance**: Random-looking data intended to avoid obvious VPN signatures
*   **Bypass**: Can help with DPI, GFW, and some corporate firewalls (see AmneziaWG documentation for details)
*   **Tracking**: Aims to make protocol classification and tracking harder in practice

### Layer 2: Skywire (MPLS Mesh)

**Protocol**: Multi-Protocol Label Switching (MPLS)-style mesh (see Skywire docs in *References / Sources*)

*   **NOT TCP/IP**: Uses label-switched paths in the mesh core instead of ordinary IP routing
*   **Path Selection**: Dynamic, multi-path routing
*   **Hop Count**: Variable, changes per packet
*   **Tracking**: Removes IP headers in the mesh core, which is intended to make conventional IP-based tracking harder
*   **Anonymity**: Traffic may be mixed with other users' traffic depending on topology and usage

### Layer 3: Yggdrasil (IPv6 Overlay)

**Protocol**: Encrypted IPv6 mesh (see Yggdrasil docs in *References / Sources*)

*   **Addressing**: IPv6 with cryptographic addresses
*   **Routing**: Distributed hash table (DHT)
*   **Encryption**: End-to-end encrypted tunnels
*   **Tracking**: Encrypted mesh with no central routing, intended to make path reconstruction harder compared to a single centralised network

### Layer 4: I2P (Garlic Routing)

**Protocol**: Anonymous overlay network (see I2P docs in *References / Sources*)

*   **Routing**: Garlic routing (multiple messages bundled)
*   **Tunnels**: Unidirectional, frequently rotated
*   **Encryption**: Layered (like Tor, but with garlic-style bundling)
*   **Tracking**: Designed to make correlation and tracking harder; if traffic stays fully internal and fully distributed there is no mandatory Tor-style exit-node concept

### Layer 5: Emercoin (Blockchain DNS)

**Protocol**: Blockchain-based naming (see EmerDNS/EmerNVS docs in *References / Sources*)

*   **Resolution**: Decentralized, using blockchain records instead of traditional recursive DNS servers
*   **Privacy**: Avoids traditional DNS leaks for Emercoin-managed namespaces when all lookups go through EmerDNS + dns-reverse-proxy
*   **Censorship**: Harder to block with conventional DNS/IP blacklists compared to a single centralised resolver
*   **Tracking**: No single central authority to query for all lookups

## How it aims to hinder tracking

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

There is **no formal bound** claimed here on the difficulty of tracking across all layers. The intent is simply to increase the amount of work and visibility an attacker would need across several independent systems.

### 2\. Network Hopping

```plaintext
Entry Node → Mesh Node 1 → Mesh Node 2 → ... → Mesh Node N → Exit
```

*   **Skywire**: MPLS path changes dynamically
*   **Yggdrasil**: IPv6 routing changes per packet
*   **I2P**: Tunnel hops rotate frequently

**Tracking (high-level)**: May require monitoring many nodes across multiple overlays; this has not been formally analysed.

### 3\. Reduced IP visibility in core

```plaintext
Client IP → [AmneziaWG] → MPLS Labels → [Skywire] → IPv6 Mesh → [Yggdrasil]
```

*   **Skywire core**: Uses MPLS-like labels, not IP addresses, in the mesh core
*   **No IP headers in core**: Traditional IP-layer monitoring is less informative
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

**Result**: Correlating entry/exit traffic should become more difficult in practice, but no anonymity proof is claimed.

### Timing Attack

**Defense**:

*   Multiple protocol layers add variable latency
*   Mesh routing introduces random delays
*   I2P tunnel rotation changes timing patterns
*   Junk packets (AmneziaWG) add noise

**Result**: Timing correlation attacks may be harder, but this depends on real-world deployment and has not been formally evaluated.

### Global Passive Adversary

**Defense**:

*   MPLS core invisible to IP monitoring
*   IPv6 mesh encrypted end-to-end
*   I2P garlic routing prevents correlation
*   Decentralized architecture (no choke points)

**Result**: A large-scale adversary would need to observe and analyse several independent layers; this is a design goal rather than a proven property.

### Sybil Attack

**Defense**:

*   Yggdrasil DHT design makes large-scale Sybil attacks significantly harder and more expensive
*   I2P tunnel diversity
*   Emercoin blockchain consensus

**Result**: Intended to make large-scale Sybil control more difficult and expensive; this does not prove that such attacks are impossible.

### Exit Node Monitoring

**Defense**:

*   I2P has no *mandatory* exit-node concept like Tor (traffic can remain fully internal; optional outproxies are not required)
*   Yggdrasil mesh is end-to-end encrypted
*   Services hosted on internal Skywire (todo)

**Result**: When traffic remains internal, there is no single Tor-style exit point; however, other attack surfaces may still exist.

## Comparison to Other Networks

### vs Tor (informal comparison)

| Feature | Tor | Privateness Network |
| --- | --- | --- |
| Entry obfuscation | Bridges (detectable) | AmneziaWG (stealthy, DPI-resistant in many cases) |
| Core routing | TCP/IP | MPLS-style mesh core |
| Layers | 3 (entry, relay, exit) | 5+ (AWG, MPLS, IPv6, I2P, blockchain) |
| Exit nodes | Yes (vulnerable) | No (I2P internal) |
| DNS | Clearnet DNS (leaks) | Blockchain DNS for Emercoin-managed namespaces |
| Blocking | Possible (known IPs) | Harder in practice (mesh + obfuscation) |

### vs VPN (informal comparison)

| Feature | Commercial VPN | Privateness Network |
| --- | --- | --- |
| Central servers | Yes (single point) | No (decentralized mesh) |
| Logs | Often centralized | No single place to subpoena (mesh; individual nodes may still log) |
| DPI detection | Easy | Harder in practice (obfuscation) |
| Routing | Fixed path | Dynamic mesh |
| DNS | VPN DNS (trusted) | Blockchain (trustless) |
| Censorship | Blockable | Harder to block at scale |

### vs I2P Alone (informal comparison)

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

The privateness.network architecture combines several well-known overlay and privacy technologies in a layered way:

1.  **Protocol diversity**: 5+ different protocols.
2.  **MPLS-style core**: Label-based forwarding in the Skywire mesh core instead of ordinary IP routing.
3.  **Encryption layers**: Multiple independent encryption layers.
4.  **Decentralization**: No single central routing point by design.
5.  **Obfuscation**: An access layer that aims to reduce the visibility of VPN usage.

The goal is to **increase the effort required** for large-scale traffic analysis and simple blocking, not to provide mathematically proven untraceability. This should be treated as an **experimental architecture** whose real-world privacy properties depend heavily on deployment details, correct configuration, and the evolving behaviour of the underlying projects referenced below.

## References / Sources

- **Yggdrasil Network**  
  Official overview and documentation for the encrypted IPv6 overlay used as the mesh layer here:  
  <https://yggdrasil-network.github.io/>  
  <https://yggdrasil-network.github.io/documentation.html>

- **I2P Anonymous Network**  
  Technical introduction to I2P, garlic routing, and unidirectional tunnels:  
  <https://geti2p.net/en/docs/how/tech-intro>

- **WireGuard / AmneziaWG**  
  WireGuard protocol and cryptography (baseline VPN tunnel):  
  <https://www.wireguard.com/protocol/>  
  AmneziaWG documentation describing the obfuscation and DPI-resistance layer used as the access protocol:  
  <https://docs.amnezia.org/documentation/amnezia-wg/>

- **Skywire**  
  Skywire node implementation and overview of the MPLS-like mesh routing used here as the label-switched core:  
  <https://github.com/skycoin/skywire>

- **Emercoin / EmerDNS / EmerNVS**  
  EmerDNS introduction (blockchain-based DNS) and EmerNVS overview (Name–Value Storage) as used for decentralized naming and policy:  
  <https://emercoin.com/en/documentation/blockchain-services/emerdns/emerdns-introduction/>  
  <https://emercoin.com/en/documentation/blockchain-services/emernvs/>

- **IPFS**  
  IPFS documentation for content-addressed storage and gateway behavior, referenced where content distribution is involved:  
  <https://docs.ipfs.tech/>

- **Central reference list**  
  See `SOURCES.md` at the root of this repository for a consolidated list of external documents underpinning the Privateness Network documentation.