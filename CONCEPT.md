# Perception → Reality Concept

[Français](CONCEPT-FR.md)

1. **EmerDNS + EmerNVS** (`dpo:PrivateNESS.Network`, `ness:dns-reverse-proxy-config`) are the only sources of truth for identities, bootstrap info, DNS policy, and service URLs. Anything not reachable from those records is treated as untrusted by default.
2. **DNS enforcement** happens through `dns-reverse-proxy` on `127.0.0.1:53/udp`, which routes Emer-owned TLDs to EmerDNS (`127.0.0.1:5335`) and optionally forwards world TLDs only through trusted upstreams.
3. **Clearnet existence toggle** switches between a hybrid universe (EmerDNS + world DNS) and an Emer-only cosmos where non-Emer domains are NXDOMAIN/blackholed and effectively do not exist.
4. **Transport graph**: `WG-in → Skywire → Yggdrasil → (optional i2pd in Ygg-only mode) → WG/XRAY-out → clearnet`. All visor-to-visor traffic stays inside Ygg, and optional i2p runs strictly within Ygg-only mode using `meshnets.yggdrasil=true`.
5. **Identity-to-config pipeline**: an external orchestrator reads Emercoin/EmerDNS entries, derives `wg.conf`, `xray` `config.json`, Skywire/Ygg config, DNS policy, and writes them into each container, which never contacts untrusted infrastructure directly.
6. **Amnezia exits** are the only clearnet-visible surfaces. The `amnezia-exit` image builds `amnezia-xray-core`, installs `amneziawg-tools`, and expects EmerDNS-derived `wg.conf` + `xray config.json`.
