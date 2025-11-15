# I2P avec routage Yggdrasil

Ce conteneur exécute I2P (Invisible Internet Project) avec tout le trafic routé via le réseau maillé Yggdrasil.

## Fonctionnement

1. **Yggdrasil** démarre en premier et crée une interface TUN avec adressage IPv6.
2. **I2P** est configuré pour se lier à l’adresse IPv6 Yggdrasil.
3. Tout le trafic I2P circule à travers le réseau maillé chiffré Yggdrasil.
4. Fournit une **double couche de confidentialité** : mesh Yggdrasil + anonymat I2P.

## Architecture

```
Trafic I2P → IPv6 Yggdrasil → Réseau maillé Yggdrasil → Internet
```

## Configuration

### Paramètres Yggdrasil
- **Interface** : périphérique TUN détecté automatiquement
- **Port d’écoute** : 9001
- **Port d’administration** : 9002
- **Multicast** : activé pour la découverte de pairs

### Paramètres I2P
- **Hôte NTCP** : adresse IPv6 Yggdrasil
- **Hôte UDP** : adresse IPv6 Yggdrasil
- **Auto-IP** : désactivé (utilise l’adresse Yggdrasil)
- **IPv6** : préféré

## Ports

- **7657** : console routeur I2P (HTTP)
- **4444** : proxy HTTP I2P
- **6668** : tunnel IRC I2P
- **9001** : connexions de pairs Yggdrasil
- **9002** : API d’administration Yggdrasil

## Prérequis

- Capacité `NET_ADMIN` pour l’interface TUN
- Accès au périphérique `/dev/net/tun`
- Routage IPv6 activé

## Utilisation

### Docker Run

```bash
docker run -d \
  --name i2p-yggdrasil \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun \
  --sysctl net.ipv6.conf.all.forwarding=1 \
  -p 7657:7657 \
  -p 4444:4444 \
  -p 6668:6668 \
  -p 9001:9001 \
  -p 9002:9002 \
  -v i2p-data:/var/lib/i2p \
  ness-network/i2p-yggdrasil
```

### Docker Compose

```yaml
i2p-yggdrasil:
  image: ness-network/i2p-yggdrasil
  cap_add:
    - NET_ADMIN
  devices:
    - /dev/net/tun
  sysctls:
    - net.ipv6.conf.all.forwarding=1
  ports:
    - "7657:7657"
    - "4444:4444"
    - "6668:6668"
    - "9001:9001"
    - "9002:9002"
  volumes:
    - i2p-data:/var/lib/i2p
```

## Accès

- **Console I2P** : http://localhost:7657
- **Proxy HTTP** : configurer le navigateur sur `localhost:4444`
- **Admin Yggdrasil** : `yggdrasilctl -endpoint=localhost:9002 getPeers`

## Avantages

1. **Confidentialité renforcée** : double chiffrement (Yggdrasil + I2P)
2. **Routage en mesh** : trafic routé via un réseau maillé décentralisé
3. **IPv6 natif** : pile réseau moderne
4. **Découverte de pairs** : jonction automatique au réseau maillé
5. **Résistant à la censure** : aucun point central de défaillance

## Vérification

Vérifier le routage Yggdrasil :

```bash
docker exec i2p-yggdrasil ip -6 addr show tun0
docker exec i2p-yggdrasil yggdrasilctl -endpoint=localhost:9002 getSelf
```

Vérifier la configuration I2P :

```bash
docker exec i2p-yggdrasil cat /var/lib/i2p/config/router.config
```
