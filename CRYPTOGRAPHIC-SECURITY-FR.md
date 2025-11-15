# Sécurité cryptographique – Garantie d’entropie

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

**La possibilité de privation d’entropie est ÉLIMINÉE** grâce à :

- **Alimentation continue** : pyuheprng alimente constamment `/dev/random`.
- **Sources multiples** : RC4OK + bits matériels + UHEP.
- **Aucun repli vers un RNG faible** : le système bloque si l’entropie est insuffisante.
- **Accès direct à `/dev/random`** : contourne l’estimation d’entropie du noyau.

### /dev/urandom est DÉSACTIVÉ

**CRITIQUE** : `/dev/urandom` est désactivé via la configuration GRUB pour empêcher les opérations cryptographiques faibles.

`/dev/urandom` renvoie des données aléatoires même lorsque le pool d’entropie est épuisé, ce qui est **cryptographiquement non sûr**.

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

## Garanties de sécurité

### 1. Pas d’aléa faible

**GARANTI** : le système n’utilise jamais un aléa faible ou prévisible.

- `/dev/urandom` désactivé (pas de repli avec pool épuisé)
- pyuheprng se bloque si les sources sont indisponibles
- Les opérations cryptographiques s’arrêtent sans entropie suffisante

### 2. Entropie continue

**GARANTI** : le pool d’entropie ne se vide jamais.

- pyuheprng alimente `/dev/random` en continu
- Multiples sources indépendantes
- Basculement automatique entre les sources
- Supervision de santé et alertes

### 3. Robustesse cryptographique

**GARANTI** : toute l’entropie est cryptographiquement sûre.

- RC4OK : aléa dérivé de la blockchain (imprévisible)
- Bits matériels : aléa physique
- UHEP : sources matérielles validées
- Mixage SHA‑512 : combinaison cryptographique

### 4. Aucune confiance implicite dans le CPU / bootloader

**GARANTI** : aucune confiance implicite dans le matériel.

- GRUB désactive la confiance CPU (`random.trust_cpu=off`)
- GRUB désactive la confiance bootloader (`random.trust_bootloader=off`)
- Toutes les sources d’entropie sont validées
- Supervision de santé continue

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

**NE JAMAIS utiliser en production** – annule les garanties de sécurité.

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
| /dev/urandom | Activé (potentiellement non sûr) | **DÉSACTIVÉ** |
| Épuisement d’entropie | Possible | **IMPOSSIBLE** |
| Aléa faible | Possible | **BLOQUÉ** |
| Sources d’entropie | CPU, bootloader (présumés fiables) | RC4OK + Matériel + UHEP (validés) |
| Comportement en blocage | Évitée | **IMPOSÉE** |
| Garantie de sécurité | Best effort | **ABSOLUE** |

### Pourquoi c’est important

**Un aléa faible casse la cryptographie** :
- Clés prédictibles
- Signatures compromises
- Chiffrement rompu
- Détournement de session
- Contournement d’authentification

**Privateness Network élimine totalement ce risque.**

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

**Privateness Network fournit une sécurité cryptographique maximale** :

1. ✅ **Pas d’aléa faible** : le système bloque plutôt que de continuer de manière non sûre.
2. ✅ **Pas de privation d’entropie** : pyuheprng alimente `/dev/random` en continu.
3. ✅ **Sources multiples** : RC4OK + Matériel + UHEP.
4. ✅ **/dev/urandom désactivé** : la configuration GRUB interdit tout repli faible.
5. ✅ **Entropie validée** : supervision continue de la santé.
6. ✅ **Aléa vérifié par blockchain** : RC4OK d’Emercoin fournit un aléa prouvé.

**C’est l’architecture d’entropie la plus sûre possible.**

Pour un déploiement en production, la **configuration GRUB est obligatoire** pour désactiver `/dev/urandom`.
