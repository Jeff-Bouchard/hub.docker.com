# Prise en charge multi-architecture

Toutes les images Docker prennent en charge plusieurs architectures CPU pour une compatibilité maximale.

## Plates-formes prises en charge

### Toutes les images
- **linux/amd64** (x86_64) - Architecture standard Intel/AMD 64 bits
- **linux/arm64** (aarch64) - ARM 64 bits (Raspberry Pi 4/5, Apple Silicon, serveurs ARM)
- **linux/arm/v7** (armhf) - ARM 32 bits (Raspberry Pi 3, anciens appareils ARM)

## Détection de l’architecture

### Emercoin Core
- Détection à l’exécution via `dpkg --print-architecture`
- Télécharge le binaire approprié pour la plate-forme :
  - `amd64` → `x86_64-linux-gnu`
  - `arm64` → `aarch64-linux-gnu`
  - `armhf` → `arm-linux-gnueabihf`

### Services basés sur Go (Skywire, Yggdrasil, DNS Proxy)
- Cross-compilés au moment de la construction avec `GOOS` et `GOARCH`
- Binaires natifs pour chaque plate-forme
- Performances optimisées

### Services Python (Privateness, PyUHEPRNG, Privatenumer, Tools)
- L’interpréteur Python est multi-arch par défaut
- Le code Python pur fonctionne sur toutes les plates-formes
- Les dépendances natives sont compilées pendant le build

### I2P
- Basé sur Java (bytecode indépendant de la plate-forme)
- Le paquet `_all.deb` fonctionne sur toutes les architectures
- La JVM gère les différences de plate-forme

## Construction d’images multi-arch

### Utilisation de Docker Buildx (recommandé)

```bash
# Configuration du builder buildx
docker buildx create --name ness-builder --use

# Construire et pousser pour toutes les plates-formes
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t ness-network/emercoin-core:latest --push .
```

### Script automatisé

```bash
./build-multiarch.sh
```

## Tests sur différentes architectures

### Avec QEMU

```bash
# Installer QEMU pour l’émulation
docker run --privileged --rm tonistiigi/binfmt --install all

# Tester une image ARM64 sur x86_64
docker run --platform linux/arm64 ness-network/emercoin-core:latest
```

## Compatibilité Umbrel

Umbrel fonctionne sur :
- Raspberry Pi 4/5 (arm64)
- Serveurs x86_64
- NAS basés sur ARM

Toutes les images ness-network fonctionnent de manière transparente sur ces plates-formes.

## Notes de performance

- **Builds natifs** (même arch que l’hôte) = meilleures performances
- **Builds émulés** (QEMU) = plus lents mais fonctionnels
- **Cross-compilation** (Go) = performances natives, builds rapides
