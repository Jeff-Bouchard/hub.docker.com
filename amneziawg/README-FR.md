# AmneziaWG - VPN WireGuard furtif

[English](README.md)

AmneziaWG est la couche d’accès furtive du réseau Privateness : une variante du protocole WireGuard avec une obfuscation avancée pour contourner la DPI (Deep Packet Inspection) et la censure dans des environnements ouvertement hostiles.

## Fonctionnalités

- **Mode furtif** : obfusque le trafic WireGuard pour qu’il ressemble à des données aléatoires
- **Bypass DPI** : contourne les systèmes d’inspection profonde des paquets
- **Paquets de bourrage** : ajoute des paquets aléatoires (Jc, Jmin, Jmax)
- **Obfuscation d’en-têtes** : randomise les en-têtes de paquets (H1-H4)
- **Obfuscation de taille** : randomise la taille des paquets (S1, S2)
- **Compatible WireGuard** : basé sur le protocole WireGuard

## Paramètres d’obfuscation

- **Jc** : nombre de paquets de bourrage (3-10)
- **Jmin** : taille minimale de bourrage (50-1000 octets)
- **Jmax** : taille maximale de bourrage (1000-2000 octets)
- **S1, S2** : randomisation de la taille des paquets (20-100 octets)
- **H1-H4** : valeurs d’obfuscation d’en-têtes

## Utilisation

### Générer la configuration

```bash
docker run --rm ness-network/amneziawg cat /etc/amneziawg/awg0.conf
```

### Lancer le serveur

```bash
docker run -d \
  --name amneziawg \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --device /dev/net/tun \
  -p 51820:51820/udp \
  -v awg-config:/etc/amneziawg \
  ness-network/amneziawg
```

### Ajouter un pair

Modifier `/etc/amneziawg/awg0.conf` :

```ini
[Peer]
PublicKey = <peer_public_key>
AllowedIPs = 10.8.0.2/32
```

Redémarrer le conteneur :

```bash
docker restart amneziawg
```

## Configuration client

Générer une configuration client avec les mêmes paramètres d’obfuscation :

```ini
[Interface]
PrivateKey = <client_private_key>
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <server_public_key>
Endpoint = <server_ip>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
# Doit correspondre aux paramètres du serveur
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

## Avantages par rapport à WireGuard standard

1. **Résistant à la censure** : contourne le GFW et les systèmes DPI
2. **Indétectable** : le trafic ressemble à du bruit, pas à un VPN
3. **Performances similaires** : surcoût minimal par rapport à WireGuard
4. **Compatible** : fonctionne avec les clients WireGuard (avec support de l’obfuscation)

Ces propriétés en font un outil de travail pour opérateurs dans des réseaux surveillés, pas un gadget « privacy » grand public.

## Cas d’usage

- Contourner la censure dans les pays restrictifs
- Éviter la DPI / les pare-feu d’entreprise
- Cacher l’utilisation d’un VPN vis-à-vis du FAI
- Combiner avec Skywire pour former une pile d’accès → mesh intraçable
