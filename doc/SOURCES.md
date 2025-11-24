# External References and Sources

This project makes strong claims about entropy, DNS, and overlay networks. This file collects the **external** documentation and specifications those claims are grounded on.

## 1. Linux RNG, `/dev/random`, `/dev/urandom`

- **Linux RNG man page (`random(4)`)**  
  Describes the kernel entropy pool, blocking behavior of `/dev/random`, and non‑blocking semantics of `/dev/urandom` and `getrandom(2)`. States that `/dev/urandom` is intended to be suitable for most cryptographic purposes once the pool is initialized.  
  <https://man7.org/linux/man-pages/man4/random.4.html>

- **`/dev/random` overview (background reading)**  
  General explanation of how `/dev/random` and `/dev/urandom` behave on Unix‑like systems.  
  <https://en.wikipedia.org/wiki//dev/random>

## 2. UHEPRNG (Ultra High Entropy PRNG)

- **Steve Gibson – Ultra High Entropy PRNG (UHEPRNG)**  
  Original description of the ultra‑high‑entropy PRNG design used as the conceptual basis for the "1536‑bit class" entropy core in this project.  
  <https://www.grc.com/otg/uheprng.htm>

## 3. Emercoin, RC4OK, EmerDNS, EmerNVS

- **Emercoin official site**  
  High‑level overview of the Emercoin platform and its blockchain services.  
  <https://emercoin.com/en/>

- **EmerDNS introduction**  
  Authoritative description of EmerDNS: blockchain‑based, decentralized DNS, recommended zones (`*.emc`, `*.coin`, `*.lib`, `*.bazar`), and censorship‑resistance properties.  
  <https://emercoin.com/en/documentation/blockchain-services/emerdns/emerdns-introduction/>

- **EmerNVS overview (Name–Value Storage)**  
  Documentation for Emercoin's NVS key→value storage, used here for DNS reverse‑proxy config and service manifests.  
  <https://emercoin.com/en/documentation/blockchain-services/emernvs/>

- **EmerDNS + I2P domain names**  
  Shows how EmerDNS names can be mapped to I2P destinations using NVS records.  
  <https://github.com/emercoin/docs/blob/master/en/020_Blockchain_Services/030_EmerDNS/031_I2P_Domain_Name_Registration_based_on_blockchain.md>

- **Emercoin RC4OK reference (release notes)**  
  Emercoin Core release notes where RC4OK is introduced as a replacement for the legacy fast RNG inherited from Bitcoin. Mentions that a scientific article about RC4OK is/was in preparation.  
  <https://github.com/emercoin/emercoin/releases>

## 4. Overlay Networks and Privacy Layers

- **Yggdrasil Network – overview and docs**  
  Experimental end‑to‑end encrypted IPv6 overlay network, DHT‑based routing, public‑key‑derived addresses.  
  <https://yggdrasil-network.github.io/>  
  <https://yggdrasil-network.github.io/documentation.html>

- **I2P – anonymous communication network**  
  General documentation index and technical introduction describing garlic routing, unidirectional tunnels, and anonymity goals.  
  <https://geti2p.net/en/docs>  
  <https://geti2p.net/en/docs/how/tech-intro>

- **WireGuard – protocol and cryptography**  
  Official protocol description used as the baseline for AmneziaWG (which adds obfuscation on top of WireGuard).  
  <https://www.wireguard.com/protocol/>

- **AmneziaWG – obfuscated WireGuard**  
  Documentation of the AmneziaWG protocol, packet‑size/header obfuscation, and DPI‑resistance mechanisms.  
  <https://docs.amnezia.org/documentation/amnezia-wg/>

- **IPFS – InterPlanetary File System**  
  Official documentation for IPFS: content addressing, P2P distribution, pinning, and gateway behavior.  
  <https://docs.ipfs.tech/>

## 5. Windows Name Resolution Policy Table (NRPT)

- **Name Resolution Policy Table (NRPT) – Microsoft**  
  Describes how the NRPT allows domain‑level DNS policy (e.g. per‑TLD forwarding, DNSSEC requirements) on Windows clients. This is what the NRPT/registry examples in this repo build on.  
  <https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/dn593632(v=ws.11)>

## 6. Reproducible Builds

- **Reproducible Builds project**  
  Upstream reference for deterministic build techniques, binary equivalence, and verification workflows. The reproducible‑builds discussion in this repo follows the same general goals and terminology.  
  <https://reproducible-builds.org/>

---

For file‑specific references, see the **"References / Sources"** sections in:

- `CRYPTOGRAPHIC-SECURITY.md`
- `pyuheprng/README.md`
- `NETWORK-ARCHITECTURE.md`
- `ipfs/README.md` (already contains an IPFS resources section)
- `PORTAINER.md`, `INCENTIVE-SECURITY.md`, and other docs where additional external links are appropriate.
