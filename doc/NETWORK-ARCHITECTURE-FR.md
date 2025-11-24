# Réseau Privateness – Architecture intraçable

[English](NETWORK-ARCHITECTURE.md)

## Hopping multi‑couches de protocoles

La pile privateness.network utilise un **hopping de protocoles** sur plusieurs couches, ce qui la rend **impossible à suivre ou tracer**.

## Flux de trafic et transitions de protocoles

```text
Client
    ↓ [TCP/IP]
Couche d’accès AmneziaWG (UDP obfusqué)
    ↓ [WireGuard furtif – ressemble à des données aléatoires]
Mesh Skywire (MPLS)
    ↓ [Multi‑Protocol Label Switching – PAS du TCP/IP]
Surcouche Yggdrasil (IPv6)
    ↓ [Routage maillé chiffré IPv6]
Réseau anonyme I2P (routage garlic)
    ↓ [Chiffrement en couches, multiples sauts]
Blockchain Emercoin (DNS décentralisé)
    ↓ [Découverte de services basée blockchain]
Destination / Services Privateness
```

## Description des couches de protocole

### Couche 1 : AmneziaWG (accès)

**Protocole** : WireGuard obfusqué (UDP)

- **Obfuscation** : paquets de bourrage, randomisation d’en‑tête, variation de taille
- **Apparence** : données aléatoires, non identifiables comme VPN
- **Contournement** : DPI, GFW, pare‑feux d’entreprise
- **Traçage** : impossible – ressemble à du bruit

### Couche 2 : Skywire (mesh MPLS)

**Protocole** : Multi‑Protocol Label Switching (MPLS)

- **Pas de TCP/IP** : chemins commutés par labels, pas de routage IP
- **Sélection de chemin** : routage dynamique multi‑chemins
- **Nombre de sauts** : variable, change par paquet
- **Traçage** : impossible – pas d’en‑têtes IP dans le cœur du mesh
- **Anonymat** : trafic mélangé avec celui d’autres utilisateurs

### Couche 3 : Yggdrasil (overlay IPv6)

**Protocole** : mesh IPv6 chiffré

- **Adressage** : IPv6 dérivé de clés cryptographiques
- **Routage** : DHT distribuée
- **Chiffrement** : tunnels chiffrés de bout en bout
- **Traçage** : impossible – mesh chiffré, aucun routage centralisé

### Couche 4 : I2P (routage garlic)

**Protocole** : réseau anonyme en surcouche

- **Routage** : garlic (plusieurs messages regroupés)
- **Tunnels** : unidirectionnels, rotés fréquemment
- **Chiffrement** : en couches (type Tor, mais plus avancé)
- **Traçage** : impossible – pas de nœuds de sortie, architecture totalement distribuée

### Couche 5 : Emercoin (DNS blockchain)

**Protocole** : nommage basé blockchain

- **Résolution** : décentralisée, aucun serveur DNS central
- **Confidentialité** : pas de fuite DNS
- **Censure** : impossible à bloquer
- **Traçage** : aucune autorité centrale à interroger

## Pourquoi c’est intraçable

### 1. Hopping de protocoles

```text
TCP/IP → UDP obfusqué → MPLS → IPv6 → Garlic → Blockchain
```

Chaque couche utilise un **protocole différent**. Pour tracer, il faudrait :

- Casser l’obfuscation (AmneziaWG)
- Comprendre les labels MPLS (Skywire)
- Déchiffrer le mesh IPv6 (Yggdrasil)
- Dé‑anonymiser le routage garlic (I2P)
- Corréler les requêtes blockchain (Emercoin)

**Probabilité de réussite** : infime / infaisable.

### 2. Hopping de réseau

```text
Nœud d’entrée → Nœud mesh 1 → Nœud mesh 2 → ... → Nœud mesh N → Sortie
```

- **Skywire** : chemins MPLS changent dynamiquement
- **Yggdrasil** : routage IPv6 évolutif par paquet
- **I2P** : rotation fréquente des tunnels

**Traçage** : nécessiterait de surveiller TOUS les nœuds simultanément.

### 3. Aucun routage IP dans le cœur

```text
IP client → [AmneziaWG] → labels MPLS → [Skywire] → mesh IPv6 → [Yggdrasil]
```

- **Cœur Skywire** : utilise des labels MPLS, PAS d’adresses IP
- **Pas d’en‑têtes IP** : la surveillance réseau classique échoue
- **Commutation de labels** : changement à chaque saut
- **Pas de traceroute** : MPLS ne répond pas à l’ICMP

### 4. Couches de chiffrement

```text
[Chiffrement AmneziaWG]
  └─ [Chiffrement MPLS Skywire]
      └─ [Chiffrement IPv6 Yggdrasil]
          └─ [Chiffrement garlic I2P]
              └─ [TLS/SSL applicatif]
```

**5 couches de chiffrement** – casser une couche ne révèle rien des autres.

### 5. Tout est décentralisé

- **Aucun serveur central** : rien à saisir / subpoena
- **Pas de logs** : les nœuds mesh ne journalisent pas
- **Pas de serveurs DNS** : tout passe par la blockchain
- **Pas de nœuds de sortie** : I2P est entièrement interne
- **Aucune visibilité FAI** : obfuscation AmneziaWG

## Résistance aux attaques

### Analyse de trafic

**Défense** :

- Obfuscation AmneziaWG → détruit les motifs de paquets
- Commutation MPLS → casse toute analyse basée sur IP
- Routage garlic I2P → mélange de trafic
- Tailles/temps de paquets variables

**Résultat** : corrélation entrée/sortie impossible.

### Attaques de timing

**Défense** :

- Multiples couches ajoutent une latence variable
- Routage en mesh introduit des délais aléatoires
- Rotation des tunnels I2P change les patterns de timing
- Paquets de bourrage AmneziaWG ajoutent du bruit

**Résultat** : les corrélations de timing échouent.

### Adversaire passif global

**Défense** :

- Cœur MPLS invisible à la surveillance IP
- Mesh IPv6 Yggdrasil chiffré de bout en bout
- Routage garlic I2P empêche la corrélation
- Architecture décentralisée (pas de goulot d’étranglement)

**Résultat** : même une surveillance type NSA échoue.

### Attaque Sybil

**Défense** :

- Mesh Skywire avec système de réputation
- DHT Yggdrasil résistante aux Sybil
- Diversité des tunnels I2P
- Consensus blockchain Emercoin

**Résultat** : impossible de contrôler suffisamment de nœuds.

### Surveillance de nœud de sortie

**Défense** :

- I2P n’a pas de nœuds de sortie (tout est interne)
- Mesh Yggdrasil chiffré de bout en bout
- Services hébergés au sein de privateness.network

**Résultat** : aucun point de sortie à surveiller.

## Comparaison avec d’autres réseaux

### vs Tor

| Fonctionnalité | Tor | Privateness Network |
|---------------|-----|---------------------|
| Obfuscation d’entrée | Bridges (détectables) | AmneziaWG (indétectable) |
| Routage cœur | TCP/IP (traçable) | MPLS (intraçable) |
| Couches | 3 (entrée, relais, sortie) | 5+ (AWG, MPLS, IPv6, I2P, blockchain) |
| Nœuds de sortie | Oui (vulnérables) | Non (I2P interne) |
| DNS | DNS clearnet (fuites) | Blockchain (pas de fuites) |
| Blocage | Possible (IPs connues) | Impossible (mesh + obfuscation) |

### vs VPN

| Fonctionnalité | VPN commercial | Privateness Network |
|---------------|----------------|---------------------|
| Serveurs centraux | Oui (SPoF) | Non (mesh décentralisé) |
| Logs | Possibles | Impossibles (pas de serveurs) |
| Détection DPI | Facile | Impossible (obfuscation) |
| Routage | Chemin fixe | Mesh dynamique |
| DNS | DNS VPN (de confiance) | Blockchain (sans confiance) |
| Censure | Bloquable | Imbloquable |

### vs I2P seul

| Fonctionnalité | I2P uniquement | Privateness Network |
|---------------|---------------|---------------------|
| Couche d’accès | TCP/IP (détectable) | AmneziaWG (furtif) |
| Routage mesh | Non | Oui (Skywire MPLS) |
| Support IPv6 | Limité | Natif (Yggdrasil) |
| DNS blockchain | Non | Oui (Emercoin) |
| Diversité protocolaire | 1 couche | 5+ couches |

## Scénarios réels

### Scénario 1 : Journaliste sous régime autoritaire

```text
Appareil du journaliste
  → AmneziaWG (contourne GFW, semble être du trafic aléatoire)
    → Skywire MPLS (pas de routage IP, intraçable)
      → Yggdrasil IPv6 (mesh chiffré)
        → I2P (communication anonyme)
          → Services Privateness (publication sécurisée)
```

**Ce que voit le gouvernement** : UDP aléatoire, impossible à identifier comme VPN  
**Ce que voit le FAI** : bruit chiffré, aucun motif de protocole  
**Ce que voit la DPI** : rien – l’obfuscation brouille l’inspection  
**Résultat** : communication sûre pour le journaliste.

### Scénario 2 : Contournement de pare‑feu d’entreprise

```text
Appareil employé
  → AmneziaWG (contourne la DPI d’entreprise)
    → Skywire MPLS (sort du réseau de l’entreprise)
      → Yggdrasil (routage chiffré)
        → Réseau Privateness
```

**Pare‑feu d’entreprise** : ne voit que de l’UDP aléatoire, non identifié comme VPN  
**DPI** : aucun motif VPN  
**Logging** : incapacité à corréler le trafic  
**Résultat** : accès non restreint.

### Scénario 3 : Utilisateur très soucieux de sa vie privée

```text
Appareil utilisateur
  → AmneziaWG (le FAI ne voit pas le VPN)
    → Skywire MPLS (routage décentralisé)
      → Yggdrasil IPv6 (anonymat mesh)
        → I2P (routage garlic)
          → DNS blockchain (pas de fuite DNS)
```

**FAI** : ne voit que du trafic chiffré, sans métadonnées  
**Annonceurs** : zéro visibilité, pas de tracking possible  
**État** : voit seulement des données aléatoires  
**Résultat** : confidentialité totale.

## Analyse technique

### MPLS dans Skywire

```text
Routage IP traditionnel :
Paquet → Routeur 1 (lit IP, route) → Routeur 2 (lit IP, route) → ...
[TRAÇABLE : en‑têtes IP visibles à chaque saut]

MPLS Skywire :
Paquet → Nœud 1 (lit label, remplace) → Nœud 2 (lit label, remplace) → ...
[INTRAÇABLE : pas d’en‑têtes IP, labels changent à chaque saut]
```

### Exemple de commutation de labels

```text
Entrée : Label 100 → Nœud A
Nœud A : remplace 100 → 200 → Nœud B
Nœud B : remplace 200 → 300 → Nœud C
Nœud C : remplace 300 → 400 → Sortie

Les en‑têtes IP ne sont JAMAIS examinés dans le cœur du mesh.
```

### Mesh IPv6 Yggdrasil

```text
IPv6 traditionnel : table de routage globale, chemins traçables
Yggdrasil IPv6 : routage basé DHT, tunnels chiffrés

Adresse : 200:1234:5678:abcd::1
  → Dérivée d’une clé publique
  → Aucune info géographique
  → Aucun lien avec un FAI
  → Totalement décentralisée
```

### Routage garlic I2P

```text
Onion classique (Tor) : Message → Chiffre → Chiffre → Chiffre
Garlic (I2P) : plusieurs messages regroupés et chiffrés ensemble

Paquet :
  - Message A (destination 1)
  - Message B (destination 2)
  - Message factice (leurre)
  - Le tout chiffré ensemble

Résultat : impossible de déterminer quel message est le vôtre.
```

## Conclusion

L’architecture privateness.network est **mathématiquement intraçable** grâce à :

1. **Diversité des protocoles** : 5+ protocoles différents
2. **Cœur MPLS** : aucun routage IP dans le mesh
3. **Couches de chiffrement multiples** : 5 niveaux
4. **Décentralisation** : pas de points centraux
5. **Obfuscation** : couche d’accès indétectable

**Pour la casser, il faudrait** :

- Briser l’obfuscation AmneziaWG (infaisable en pratique)
- Surveiller l’intégralité du mesh Skywire (milliers de nœuds)
- Casser le chiffrement IPv6 Yggdrasil (tunnels E2E)
- Dé‑anonymiser I2P (routage garlic éprouvé)
- Corréler les requêtes blockchain (décentralisées, sans logs)

**Probabilité de succès** : pratiquement nulle.

C’est l’architecture réseau orientée confidentialité la plus avancée actuellement.
