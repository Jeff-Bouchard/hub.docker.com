# Ness Unified Node

This repository builds the **Ness Unified** image (`nessnetwork/ness-unified`), an "All-in-One" appliance container.

## Architecture: The "Fat Container" Pattern

Unlike the standard Ness stack which follows Docker microservices best practices (one process per container), **Ness Unified** is architected as a **Single-Container Appliance**.

It runs the entire Privateness/Ness stack inside a single isolated environment:

* **Emercoin Core** (Blockchain)
* **Yggdrasil** (Mesh Network)
* **Skywire** (VPN/Mesh)
* **Privateness** (Core Application)
* **DNS Reverse Proxy** (Self-contained Decentralized DNS)
* **Entropy Services** (pyuheprng, privatenumer)

### Why Supervisor?

To manage this complexity reliably, this image uses **Supervisor** (`supervisord`) as its init system (PID 1).

Supervisor is responsible for:

1. **Orchestration:** Starting services in the correct order (where possible) or parallelizing startup.
2. **Process Management:** Monitoring all sub-services and automatically restarting any that crash.
3. **Log Aggregation:** Capturing stdout/stderr from all subprocesses.

### The "Appliance" Model & DNS

For App Stores like **Umbrel**, this Unified image acts as a complete network appliance.

Crucially, it includes **`dns-reverse-proxy`**, allowing the container to resolve decentralized TLDs (like `.lib`, `.coin`, `.emc`) internally. This ensures the node is fully functional "out of the box" without requiring complex host-side DNS configuration.

### Use Case

This architecture is "Normal" and intentional for specific deployment scenarios:

* **Umbrel / App Stores:** Where a single "App" entry is preferred over managing a complex multi-container compose stack.
* **PaaS Deployments:** For cloud providers that offer single-container slots (e.g., Railway, Render) without docker-compose support.
* **Simplified UX:** For users who want a single "Start/Stop" button for their entire node.

## Multi-Architecture Support

This image supports:

* `linux/amd64` (x86_64 PCs/Servers)
* `linux/arm64` (Raspberry Pi 4/5, Apple Silicon)

*Note: 32-bit ARM (armv7) is not supported.*

*Note: Binaries are natively compiled for each architecture to ensure maximum performance and stability.*
