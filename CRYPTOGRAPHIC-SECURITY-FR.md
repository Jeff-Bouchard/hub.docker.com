# Sécurité cryptographique – Design d’entropie (expérimental)

[English](CRYPTOGRAPHIC-SECURITY.md)

## ⚠️ AVERTISSEMENT DE SÉCURITÉ CRITIQUE

**Ce système PRÉFÈRE BLOQUER plutôt que d’exécuter une opération cryptographique non sûre.**

La pile privateness.network privilégie la sécurité cryptographique à la disponibilité. Si l’entropie disponible n’est pas suffisante, les opérations **s’arrêtent** plutôt que de continuer avec un aléa faible.

## Architecture d’entropie

### pyuheprng – Générateur de nombres vraiment aléatoires

Le service `pyuheprng` fournit une **entropie cryptographiquement sûre** en alimentant directement `/dev/random` avec un mélange de :

1. **RC4OK depuis Emercoin Core** : aléa dérivé de la blockchain
2. **Bits matériels originaux** : sources d’entropie matérielle directe
3. **UHEP (Universal Hardware Entropy Protocol)** : génération d’aléa au niveau matériel

**Uniquement pour les machines non‑Windows** – Windows utilise d’autres sources d’entropie.

### Prévention de la privation d’entropie

Sur des hôtes correctement configurés, ce design vise à **réduire fortement le risque de privation d’entropie** grâce à :

- **Alimentation continue** : pyuheprng alimente `/dev/random` en continu.
- **Sources multiples** : RC4OK + bits matériels + UHEP.
- **Aucun repli volontaire vers un RNG jugé faible** : le système bloque si l’entropie semble insuffisante.
- **Accès direct à `/dev/random`** : alimente directement le pool d’entropie du noyau.

### Politique sur `/dev/urandom`

Dans ce projet, `/dev/urandom` est désactivé via la configuration GRUB pour éviter qu’il ne soit utilisé comme source d’aléa pour la cryptographie **dans ce profil précis**.

La documentation du RNG Linux (`random(4)`) indique que `/dev/urandom` est prévu pour être adapté à la plupart des usages cryptographiques une fois le pool initialisé. La configuration proposée ici est donc **plus conservatrice que la pratique courante** et peut introduire davantage de blocages sans nécessairement convenir à tous les environnements.

## Configuration GRUB (obligatoire en production)

### Désactiver /dev/urandom

Ajouter dans la configuration GRUB (`/etc/default/grub`) :

```bash
GRUB_CMDLINE_LINUX="random.trust_cpu=off random.trust_bootloader=off"
```

Puis mettre à jour GRUB :

```bash
# Debian/Ubuntu
sudo update-grub

# RHEL/CentOS/Fedora
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# Arch Linux
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Vérifier que /dev/urandom est désactivé

```bash
# Vérifier les paramètres du noyau
cat /proc/cmdline | grep random

# Doit afficher :
# random.trust_cpu=off random.trust_bootloader=off
```

### Renforcement supplémentaire

```bash
# Désactiver la confiance dans le RNG matériel (forcer la vérification)
echo 0 > /sys/module/random/parameters/trust_cpu
echo 0 > /sys/module/random/parameters/trust_bootloader

# Vérifier l’entropie disponible
cat /proc/sys/kernel/random/entropy_avail

# Devrait rester constamment élevée (>3000) avec pyuheprng actif
```

## Configuration du service pyuheprng

### Déploiement Docker

```bash
docker run -d \
  --name pyuheprng \
  --privileged \
  --device /dev/random \
  -v /dev:/dev \
  -p 5000:5000 \
  ness-network/pyuheprng
```

**Remarque** : nécessite `--privileged` et l’accès à `/dev` pour alimenter `/dev/random` directement.

### Sources d’entropie

#### 1. RC4OK depuis Emercoin Core

```python
# pyuheprng se connecte au RPC Emercoin
emercoin_rpc = EmercoinRPC(host='emercoin-core', port=6662)
rc4ok_entropy = emercoin_rpc.get_rc4ok()
```

RC4OK d’Emercoin fournit un aléa dérivé de la blockchain :
- Hashs de blocs
- Données de transaction
- Temporisation réseau
- Aléa de preuve de travail

#### 2. Bits matériels originaux

```python
# Sources d’entropie matérielle directe
hwrng = open('/dev/hwrng', 'rb')
hardware_bits = hwrng.read(32)
```

Sources possibles :
- Instructions CPU RDRAND/RDSEED
- Périphériques RNG matériels
- TPM (Trusted Platform Module)
- Bruit environnemental

#### 3. Protocole UHEP

Universal Hardware Entropy Protocol :
- Combine plusieurs sources matérielles
- Mélange cryptographique
- Supervision continue de l’état
- Validation automatique des sources

### Mélange d’entropie

```python
# Mélange cryptographique des sources d’entropie
mixed_entropy = sha512(rc4ok_entropy + hardware_bits + uhep_data)

# Injection dans /dev/random
with open('/dev/random', 'wb') as random_dev:
    random_dev.write(mixed_entropy)
```

## Propriétés de sécurité (objectifs de conception)

### 1. Réduction de l’aléa faible

Le système est **conçu** pour éviter autant que possible l’utilisation d’un aléa faible ou facilement prévisible, sur un hôte correctement configuré :

- `/dev/urandom` est évité pour la crypto dans ce profil.
- pyuheprng se bloque si les sources configurées sont indisponibles.
- Certaines opérations cryptographiques s’arrêtent si l’entropie semble insuffisante.

### 2. Entropie continue (objectif)

L’architecture **vise** à ce que le pool d’entropie ne se vide pas en fonctionnement normal sur un hôte correctement configuré :

- pyuheprng alimente `/dev/random` en continu.
- Multiples sources indépendantes sont combinées.
- Un basculement simple et une supervision de santé sont en place.

### 3. Robustesse cryptographique (hypothèses)

La robustesse dépend des primitives sous‑jacentes, supposées sûres selon leur propre documentation :

- RC4OK : aléa dérivé de la blockchain (Emercoin), supposé imprévisible selon les spécifications Emercoin.
- Bits matériels : aléa physique issu de périphériques RNG, CPU, TPM, etc.
- UHEP : composition et agrégation de ces sources matérielles.
- Mixage SHA‑512 : combinaison cryptographique des entrées.

### 4. Réduction de la confiance implicite dans CPU / bootloader

La configuration cherche à **réduire** la confiance implicite dans le RNG du CPU ou du bootloader comme source unique :

- GRUB désactive la confiance CPU (`random.trust_cpu=off`).
- GRUB désactive la confiance bootloader (`random.trust_bootloader=off`).
- Les sources d’entropie sont combinées et soumises à des contrôles de santé basiques, sans certification formelle.

## Supervision

### Vérifier les niveaux d’entropie

```bash
# Entropie courante disponible
watch -n 1 cat /proc/sys/kernel/random/entropy_avail

# Devrait rester élevée (>3000) avec pyuheprng actif
```

### Vérifier l’état de pyuheprng

```bash
# Santé du service
curl http://localhost:5000/health

# État des sources d’entropie
curl http://localhost:5000/sources

# Débit d’entropie actuel
curl http://localhost:5000/rate
```

### Alertes

pyuheprng enverra des alertes si :
- Les sources d’entropie échouent
- Le débit d’entropie passe sous un seuil
- La connexion Emercoin est perdue
- Le RNG matériel est indisponible

## Modes de défaillance

### Défaillance d’une source d’entropie

**Comportement** : le système bloque les opérations cryptographiques.

```
ERROR: Insufficient entropy available
ERROR: pyuheprng source failure
ACTION: Cryptographic operations BLOCKED
STATUS: Waiting for entropy restoration
```

**Résolution** :
1. Vérifier l’état du service pyuheprng
2. Vérifier la connexion Emercoin
3. Vérifier la disponibilité du RNG matériel
4. Examiner les journaux système

### Blocage de /dev/random

**Comportement** : attendu et CORRECT.

```
INFO: /dev/random blocking (waiting for entropy)
INFO: This is CORRECT behavior for security
STATUS: pyuheprng feeding entropy
```

**Ce n’est pas une erreur** – le blocage garantit la sécurité cryptographique.

### Entropie d’urgence

**NON RECOMMANDÉ** – uniquement pour tests / développement :

```bash
# INSECURE : à n’utiliser que pour des tests non‑production
rngd -r /dev/urandom -o /dev/random
```

**NE JAMAIS utiliser en production** – annule les propriétés de sécurité recherchées par cette configuration.

## Intégration dans l’architecture

### Dépendances de services

```text
Emercoin Core (source RC4OK)
    ↓
pyuheprng (mélange d’entropie)
    ↓
/dev/random (pool d’entropie du noyau)
    ↓
Toutes les opérations cryptographiques
```

### Stack Portainer

```yaml
services:
  emercoin-core:
    image: ness-network/emercoin-core
    # ... config ...

  pyuheprng:
    image: ness-network/pyuheprng
    privileged: true
    devices:
      - /dev/random
    volumes:
      - /dev:/dev
    depends_on:
      - emercoin-core
    environment:
      - EMERCOIN_HOST=emercoin-core
      - EMERCOIN_PORT=6662
      - MIN_ENTROPY_RATE=1000  # bytes/sec
      - BLOCK_ON_LOW_ENTROPY=true

  # Tous les autres services dépendent de pyuheprng
  privateness:
    depends_on:
      - pyuheprng
    # ... config ...
```

## Comparaison avec les systèmes standards

### Linux standard

| Aspect | Linux standard | Privateness Network |
|--------|----------------|---------------------|
| /dev/urandom | Activé (potentiellement utilisé pour la crypto) | Politique locale : évité pour la crypto dans ce profil |
| Épuisement d’entropie | Possible | Conçu pour être peu probable en fonctionnement normal |
| Aléa faible | Possible | Les opérations sensibles sont bloquées si l’entropie semble insuffisante |
| Sources d’entropie | CPU, bootloader (présumés fiables) | RC4OK + Matériel + UHEP (combinaison validée localement) |
| Comportement en blocage | Souvent évité | Accepté comme coût de sécurité dans ce design |
| Modèle de sécurité | Best effort | Dépend du déploiement correct et des hypothèses sur les primitives |

### Pourquoi c’est important

**Un aléa faible casse la cryptographie** :
- Clés prédictibles
- Signatures compromises
- Chiffrement rompu
- Détournement de session
- Contournement d’authentification

Le design de Privateness Network **vise à réduire fortement ce risque sur l’hôte local**, mais ne supprime pas toutes les possibilités d’erreur de configuration ou d’attaques inédites.

## Analyse technique approfondie

### /dev/random vs /dev/urandom

#### /dev/random (utilisé par Privateness)

```text
Comportement : bloque lorsque le pool d’entropie est épuisé
Sécurité : toujours cryptographiquement sûr
Cas d’usage : clés, signatures, opérations critiques
```

#### /dev/urandom (DÉSACTIVÉ dans Privateness)

```text
Comportement : ne bloque jamais (renvoie des données même avec pool vide)
Sécurité : potentiellement faible quand le pool est épuisé
Cas d’usage : aléa non critique (PAS pour la crypto)
```

**Privateness désactive `/dev/urandom`** pour éviter toute utilisation accidentelle d’un aléa faible.

### Source d’entropie RC4OK

RC4OK d’Emercoin fournit :

```text
Hash de bloc : SHA-256(previous_block + transactions + nonce)
  → Imprévisible (preuve de travail)
  → Vérifié par la blockchain
  → Distribué sur le réseau

Données de transaction : entrées utilisateur, timestamps, adresses
  → Forte entropie
  → Distribuées globalement
  → Hashées cryptographiquement

Temporisation réseau : temps d’arrivée des blocs, latence des pairs
  → Bruit environnemental
  → Imprévisible
  → Source continue
```

**Combiné** : aléa fort, vérifié par la blockchain.

### Protocole UHEP

Universal Hardware Entropy Protocol :

```python
class UHEP:
    def __init__(self):
        self.sources = [
            CPURdrand(),      # Intel/AMD RDRAND
            CPURdseed(),      # Intel/AMD RDSEED
            HardwareRNG(),    # /dev/hwrng
            TPM(),            # Trusted Platform Module
            AudioNoise(),     # Bruit capté par le micro
            VideoNoise(),     # Bruit du capteur caméra
            DiskTiming(),     # Jitter sur les temps d’E/S disque
            NetworkTiming(),  # Jitter sur les temps réseau
        ]
    
    def get_entropy(self, bytes_needed):
        # Collecter auprès de toutes les sources
        entropy = b''
        for source in self.sources:
            if source.available():
                entropy += source.read(bytes_needed)
        
        # Mélange cryptographique
        mixed = sha512(entropy)
        
        # Contrôle de santé
        if not self.validate_entropy(mixed):
            raise InsufficientEntropyError()
        
        return mixed
```

## Conclusion

Ce document décrit un design d’entropie qui **cherche à durcir la production d’aléa** pour les opérations sensibles :

1. Il tente d’éviter l’utilisation d’un aléa manifestement faible en bloquant certaines opérations.
2. Il essaie de maintenir un flux continu vers `/dev/random` via plusieurs sources.
3. Il combine RC4OK, des sources matérielles et UHEP pour diversifier l’entropie.
4. Il applique une politique locale stricte sur `/dev/urandom` dans ce profil.
5. Il fournit une supervision de base de l’état du générateur.
6. Il s’appuie sur Emercoin pour une partie de l’aléa, en héritant des propriétés de sécurité de cette blockchain.

Il s’agit d’un **design expérimental**, pas d’une preuve de sécurité absolue. Il n’a pas été audité par des cryptographes indépendants. Pour toute utilisation en production, il est recommandé de :

- Vérifier soigneusement la configuration de l’hôte.
- Prendre connaissance de la documentation du RNG Linux (`random(4)`).
- Considérer ce profil comme une base de réflexion, pas comme un remplacement automatique des configurations RNG standards.
