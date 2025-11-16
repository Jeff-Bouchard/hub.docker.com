# Couche d’accès Skywire-AmneziaWG

[English](README.md)

Skywire-AmneziaWG est la porte d’entrée du réseau Privateness : AmneziaWG fournit la **couche d’accès** avec des capacités de VPN furtif, connectant directement les clients au mesh Skywire.

## Architecture

```text
Appareil client (TCP/IP)
    ↓
Couche d’accès AmneziaWG (UDP obfusqué)
    ↓ [Transition de protocole : UDP → MPLS]
Mesh Skywire (commutation de labels MPLS – PAS du TCP/IP)
    ↓ [Transition de protocole : MPLS → IPv6]
Surcouche Yggdrasil (mesh IPv6 chiffré)
    ↓ [Transition de protocole : IPv6 → routage garlic]
Réseau anonyme I2P (chiffrement en couches)
    ↓
Services Privateness / Internet
```

### Pourquoi c’est intraçable

1. **Hopping de protocoles** : TCP/IP → UDP → MPLS → IPv6 → Garlic.
2. **Pas d’IP au cœur du réseau** : Skywire MPLS utilise des labels, pas le routage IP.
3. **Hopping de réseau** : chemins dynamiques, changeant par paquet.
4. **Couches de chiffrement** : 5+ couches.
5. **Décentralisation** : aucun serveur central à surveiller.

**Résultat** : traçage et corrélation de trafic pratiquement impossibles.

Pour les équipes réseau, considérez cette couche comme une DMZ chiffrée mouvante : l’adversaire voit passer du trafic, mais ne peut ni le classifier proprement, ni le rattacher à un service interne précis.

## Flux de trafic

1. **Le client se connecte** à AmneziaWG (VPN furtif avec obfuscation).
2. **AmneziaWG route** tout le trafic vers l’interface mesh Skywire.
3. **Skywire distribue** le trafic dans le mesh décentralisé.
4. **Sortie via le mesh** vers la destination ou les services privateness.network.

## Composants clés

### Couche d’accès AmneziaWG

- **VPN furtif** : obfuscation résistante à la DPI.
- **Gateway client** : réseau 10.8.0.0/24.
- **Auto‑configuration** des paramètres d’obfuscation.
- **Traversée NAT** : fonctionne derrière pare‑feu.

### Intégration mesh Skywire

- **Binding direct** : Skywire se lie à l’interface AmneziaWG.
- **Routage mesh** : sélection de chemin décentralisée.
- **Load balancing** : trafic distribué sur plusieurs nœuds.
- **Tolérance aux pannes** : reroutage automatique en cas de défaillance.

## Configuration

### Serveur

```bash
docker run -d \
  --name skywire-amneziawg \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --device /dev/net/tun \
  --sysctl net.ipv4.ip_forward=1 \
  -p 8001:8000 \
  -p 51821:51820/udp \
  ness-network/skywire-amneziawg
```

### Clé publique du serveur

```bash
docker exec skywire-amneziawg cat /etc/amneziawg/awg0.conf | grep -A 20 "Interface"
```

### Configuration client

Créer un fichier de config client WireGuard/AmneziaWG avec les **mêmes paramètres d’obfuscation** que le serveur :

```ini
[Interface]
PrivateKey = <client_private_key>
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <server_public_key>
Endpoint = <server_ip>:51821
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25

# CRITIQUE : Doit correspondre exactement aux paramètres du serveur
Jc = <server_Jc>
Jmin = <server_Jmin>
Jmax = <server_Jmax>
S1 = <server_S1>
S2 = <server_S2>
H1 = <server_H1>
H2 = <server_H2>
H3 = <server_H3>
H4 = <server_H4>
```

## Cas d’usage

### 1. Contournement de censure

- Client dans un pays restrictif.
- AmneziaWG contourne la DPI et les blocages.
- Skywire fournit un routage décentralisé.
- Aucun point unique de censure.

### 2. Accès orienté confidentialité

- Trafic client obfusqué (AmneziaWG).
- Routage décentralisé (Skywire).
- Aucun fournisseur VPN central.
- Anonymat via le mesh.

### 3. Accès réseau d’entreprise

- Contourner la DPI d’entreprise.
- Accéder aux services privateness.network même derrière un pare‑feu strict.
- Le mode furtif empêche de détecter le VPN.

### 4. Gateway pour IoT

- Les appareils IoT se connectent via AmneziaWG.
- Trafic routé via le mesh Skywire.
- Réseau IoT décentralisé, sans cloud central.

## Supervision

### État AmneziaWG

```bash
docker exec skywire-amneziawg awg show awg0
```

### Peers Skywire

```bash
docker exec skywire-amneziawg skywire-cli visor info
```

### Table de routage

```bash
docker exec skywire-amneziawg ip route show table 100
```

### Monitoring du trafic

```bash
docker exec skywire-amneziawg iftop -i awg0
```

## Sécurité

### Couche d’accès

- **Handshake obfusqué** : indétectable par la DPI.
- **Timing aléatoire** : empêche l’analyse de timing.
- **Randomisation d’en‑têtes** : trafic visuellement aléatoire.
- **Obfuscation de taille** : tailles de paquets variées.

### Couche mesh

- **Chiffrement de bout en bout** dans Skywire/Yggdrasil.
- **Aucune autorité centrale**.
- **Multi‑chemins** : trafic réparti.
- **Routage en couches** (type onion) dans le cœur du réseau.

## Performances

- **Latence** : +10–30 ms (AmneziaWG) + overhead du mesh.
- **Débit** : proche de WireGuard natif.
- **Overhead** : ~5–10 % dû à l’obfuscation.
- **Scalabilité** : le mesh s’améliore avec le nombre de nœuds.

## Dépannage

### AmneziaWG ne démarre pas

```bash
# Vérifier le module noyau
docker exec skywire-amneziawg lsmod | grep amneziawg

# Vérifier l’interface
docker exec skywire-amneziawg ip link show awg0
```

### Skywire ne route pas

```bash
# Statut Skywire
docker exec skywire-amneziawg skywire-cli visor info

# Routes
docker exec skywire-amneziawg ip route
```

### Le client ne se connecte pas

1. Vérifier que les paramètres d’obfuscation (Jc, Jmin, Jmax, S1, S2, H1–H4) correspondent.
2. Vérifier que le firewall autorise l’UDP sur 51821.
3. Vérifier la clé publique du serveur.
4. Vérifier que `AllowedIPs` inclut `0.0.0.0/0` côté client.

## Intégration avec Privateness Network

Cette couche d’accès s’intègre avec :

- **Emercoin** : découverte de services via la blockchain.
- **Yggdrasil** : mesh IPv6 chiffré.
- **I2P** : couche d’anonymat.
- **DNS Proxy** : résolution DNS décentralisée.

Elle fournit une chaîne complète, de la couche d’accès jusqu’aux services applicatifs, avec confidentialité et décentralisation de bout en bout.
