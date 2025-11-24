# Déploiement sur Docker Hub - nessnetwork

[English](DEPLOY.md)

## Guide de déploiement rapide

### 1. Connexion à Docker Hub

```bash
docker login
# Nom d’utilisateur : nessnetwork
# Mot de passe : <votre-mot-de-passe-ou-token>
```

### 2. Construire toutes les images

```bash
./build-all.sh
```

Ce script construit toutes les images avec le tag `nessnetwork/<nom-image>`.

### 3. Pousser toutes les images

```bash
./push-all.sh
```

Ce script pousse toutes les images vers https://hub.docker.com/u/nessnetwork

## Construction et push d’une image individuelle

```bash
# Build
docker build -t nessnetwork/emercoin-core ./emercoin-core

# Push
docker push nessnetwork/emercoin-core
```

## Build multi‑architecture (pour support Pi4)

### Configuration initiale (une seule fois)

```bash
# Créer le builder buildx
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap
```

### Build & push multi‑arch

```bash
# Emercoin Core
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t nessnetwork/emercoin-core:latest \
  --push \
  ./emercoin-core

# pyuheprng-privatenesstools (conteneur combiné)
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t nessnetwork/pyuheprng-privatenesstools:latest \
  --push \
  ./pyuheprng-privatenesstools

# DNS Reverse Proxy
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t nessnetwork/dns-reverse-proxy:latest \
  --push \
  ./dns-reverse-proxy

# Privateness
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t nessnetwork/privateness:latest \
  --push \
  ./privateness
```

## Vérifier le déploiement

```bash
# Vérifier les images sur Docker Hub
docker search nessnetwork/emercoin-core

# Ou visiter
# https://hub.docker.com/u/nessnetwork
```

## Pull et tests

```bash
# Récupérer depuis Docker Hub
docker pull nessnetwork/emercoin-core

# Tester le déploiement
docker-compose -f docker-compose.ness.yml up -d

# Vérifier l’état
docker-compose -f docker-compose.ness.yml ps
```

## Liste des images

Toutes les images sous le compte `nessnetwork` :

- `nessnetwork/emercoin-core`
- `nessnetwork/privateness`
- `nessnetwork/skywire`
- `nessnetwork/pyuheprng`
- `nessnetwork/privatenumer`
- `nessnetwork/privatenesstools`
- `nessnetwork/pyuheprng-privatenesstools` (combiné)
- `nessnetwork/yggdrasil`
- `nessnetwork/i2p-yggdrasil`
- `nessnetwork/dns-reverse-proxy`
- `nessnetwork/ipfs`
- `nessnetwork/amneziawg`
- `nessnetwork/skywire-amneziawg`
- `nessnetwork/ness-unified`

## Dépannage

### Problèmes de connexion (login)

```bash
# Utiliser un token d’accès plutôt qu’un mot de passe
# Créer un token ici : https://hub.docker.com/settings/security
docker login -u nessnetwork
```

### Échec de build

```bash
# Nettoyer le cache de build
docker builder prune -a

# Rebuild
./build-all.sh
```

### Échec de push

```bash
# Vérifier que vous êtes connecté
docker info | grep Username

# Se reconnecter
docker logout
docker login
```

### Problèmes avec le build multi‑arch

```bash
# Supprimer et recréer le builder
docker buildx rm multiarch
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap
```

## CI/CD automatisé (optionnel)

Pour des builds automatisés via GitHub :

```yaml
# .github/workflows/docker-publish.yml
name: Docker Publish

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: nessnetwork
          password: ${{ secrets.DOCKER_HUB_TOKEN }}
      
      - name: Build and push
        run: |
          ./build-all.sh
          ./push-all.sh
```

## Notes

- Compte personnel : `nessnetwork`
- Toutes les images sont publiques
- Support multi‑arch pour Pi4 (arm64)
- Les images sont mises à jour à chaque push
