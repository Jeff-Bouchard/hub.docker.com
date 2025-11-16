# pyuheprng – Service d’entropie cryptographique

[English](README.md)

## Universal Hardware Entropy Protocol Random Number Generator

Composant d’infrastructure qui alimente directement `/dev/random` avec une entropie cryptographiquement sûre issue de plusieurs sources, pour que tout le reste de la pile soit soit sûr, soit bloqué.

## ⚠️ CRITIQUE : le système BLOQUE en cas d’entropie insuffisante

**Ce service garantit que le système BLOQUE plutôt que d’effectuer des opérations cryptographiques non sûres.**

Si l’entropie disponible est insuffisante, toutes les opérations cryptographiques se mettent en pause jusqu’à ce que le niveau d’entropie soit rétabli. Ce comportement est **volontaire et correct** pour la sécurité.

Pour les équipes secops/devops, considérez `pyuheprng` comme un disjoncteur : s’il bloque, c’est pour éviter que le reste de votre infrastructure ne signe des opérations faibles.

## Sources d’entropie

### 1. RC4OK depuis Emercoin Core

Aléa dérivé de la blockchain :

- Hashs de blocs (SHA‑256, preuve de travail vérifiée).
- Données de transaction (distribuées globalement).
- Temporisation réseau (imprévisible).
- Aléa robuste, vérifié par la blockchain.

### 2. Bits matériels originaux

Entropie matériel directe :

- Instructions CPU RDRAND/RDSEED.
- Périphériques RNG matériels (`/dev/hwrng`).
- TPM (Trusted Platform Module).
- Sources de bruit environnemental.

### 3. Protocole UHEP

Universal Hardware Entropy Protocol :

- Agrège plusieurs sources matérielles.
- Mélange cryptographique (SHA‑512).
- Supervision continue de la santé.
- Validation automatique des sources.

## Prévention de la privation d’entropie

**La privation d’entropie est ÉLIMINÉE** grâce à :

- Alimentation continue de `/dev/random`.
- Sources multiples (RC4OK + matériel + UHEP).
- Aucun repli vers un RNG faible.
- Blocage du système en cas d’entropie insuffisante.

## Déploiement

### Docker Run

```bash
docker run -d \
  --name pyuheprng \
  --privileged \
  --device /dev/random \
  -v /dev:/dev \
  -p 5000:5000 \
  -e EMERCOIN_HOST=emercoin-core \
  -e EMERCOIN_PORT=6662 \
  -e EMERCOIN_USER=rpcuser \
  -e EMERCOIN_PASS=rpcpassword \
  -e MIN_ENTROPY_RATE=1000 \
  -e BLOCK_ON_LOW_ENTROPY=true \
  ness-network/pyuheprng
```

**Note** : nécessite `--privileged` et l’accès à `/dev` pour alimenter `/dev/random`.

### Docker Compose

```yaml
services:
  pyuheprng:
    image: ness-network/pyuheprng
    privileged: true
    devices:
      - /dev/random
    volumes:
      - /dev:/dev
    environment:
      - EMERCOIN_HOST=emercoin-core
      - EMERCOIN_PORT=6662
      - MIN_ENTROPY_RATE=1000
      - BLOCK_ON_LOW_ENTROPY=true
    depends_on:
      - emercoin-core
```

## Configuration GRUB (obligatoire en production)

### Désactiver /dev/urandom

**CRITIQUE** : sur les machines non‑Windows, `/dev/urandom` DOIT être désactivé via GRUB.

Modifier `/etc/default/grub` :

```bash
GRUB_CMDLINE_LINUX="random.trust_cpu=off random.trust_bootloader=off"
```

Mettre à jour GRUB :

```bash
# Debian/Ubuntu
sudo update-grub

# RHEL/CentOS/Fedora
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# Arch Linux
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Redémarrer puis vérifier :

```bash
cat /proc/cmdline | grep random
# Doit afficher : random.trust_cpu=off random.trust_bootloader=off
```

### Pourquoi désactiver /dev/urandom ?

`/dev/urandom` continue de renvoyer des données même lorsque le pool d’entropie est épuisé, ce qui peut être **cryptographiquement dangereux**.

En le désactivant :

- Aucun repli vers un aléa faible.
- Toutes les opérations cryptographiques passent par `/dev/random`.
- Le système bloque plutôt que de continuer de manière non sûre.

## Supervision

### Niveau d’entropie

```bash
# Entropie disponible (rafraîchie chaque seconde)
watch -n 1 cat /proc/sys/kernel/random/entropy_avail

# Avec pyuheprng, doit rester élevée (> 3000)
```

### Santé du service

```bash
# Healthcheck
curl http://localhost:5000/health

# État des sources d’entropie
curl http://localhost:5000/sources

# Débit d’entropie (octets/s)
curl http://localhost:5000/rate
```

Exemple de sortie JSON :

```json
{
  "status": "healthy",
  "entropy_avail": 3842,
  "sources": {
    "rc4ok": "active",
    "hardware": "active",
    "uhep": "active"
  },
  "rate": 1247,
  "blocking": false
}
```

## Modes de défaillance

### Entropie insuffisante

**Comportement** : le système BLOQUE les opérations cryptographiques.

```text
ERROR: Insufficient entropy available
ERROR: pyuheprng source failure
ACTION: Cryptographic operations BLOCKED
STATUS: Waiting for entropy restoration
```

**C’est le comportement CORRECT** en sécurité forte.

### Perte de la connexion Emercoin

**Comportement** : repli sur Hardware + UHEP.

```text
WARNING: Emercoin RC4OK source unavailable
INFO: Using Hardware + UHEP sources only
STATUS: Reduced entropy rate (still secure)
```

### RNG matériel indisponible

**Comportement** : utilisation de RDRAND/RDSEED + RC4OK.

```text
WARNING: Hardware RNG unavailable
INFO: Using CPU RDRAND/RDSEED + RC4OK
STATUS: Entropy generation continues
```

## Garanties de sécurité

### 1. Pas d’aléa faible

- ✅ Le système n’utilise jamais un aléa prévisible.
- ✅ Il bloque plutôt que de continuer en mode dégradé.
- ✅ `/dev/urandom` est désactivé via GRUB.

### 2. Aucun épuisement d’entropie

- ✅ `/dev/random` est alimenté en continu.
- ✅ Multiples sources d’entropie indépendantes.
- ✅ Basculement automatique entre sources.

### 3. Force cryptographique

- ✅ RC4OK : aléa vérifié par blockchain.
- ✅ Matériel : sources physiques.
- ✅ UHEP : protocole matériel validé.
- ✅ Mélange SHA‑512 : combinaison cryptographique.

### 4. Aucune confiance implicite dans le matériel

- ✅ GRUB désactive la confiance CPU et bootloader.
- ✅ Toutes les sources sont validées.
- ✅ Healthchecks en continu.

## API HTTP

### GET /health

```bash
curl http://localhost:5000/health
```

### GET /sources

```bash
curl http://localhost:5000/sources
```

### GET /rate

```bash
curl http://localhost:5000/rate
```

### GET /entropy

Obtenir des octets aléatoires (pour tests uniquement) :

```bash
curl "http://localhost:5000/entropy?bytes=32"
```

## Intégration avec la pile Privateness

Tous les services critiques de privateness.network dépendent de `pyuheprng` :

```text
Emercoin Core (source RC4OK)
    ↓
pyuheprng (mélange d’entropie)
    ↓
/dev/random (pool d’entropie noyau)
    ↓
Toutes les opérations cryptographiques
    ├─ AmneziaWG (génération de clés)
    ├─ Skywire (chiffrement mesh)
    ├─ Yggdrasil (clé de tunnel)
    ├─ I2P (clés garlic)
    └─ Privateness (crypto applicative)
```

## Plateformes non‑Windows

Cette architecture d’entropie est conçue pour les systèmes **Linux**.

Sur Windows, l’entropie provient d’APIs natives :

- CryptGenRandom.
- BCryptGenRandom.
- RNG‑CSP.

Les conteneurs Windows doivent s’appuyer sur ces sources plutôt que sur `/dev/random`.

## Conclusion

`pyuheprng` fournit une **sécurité cryptographique maximale** en durcissant la base plutôt qu’en espérant que « tout se passera bien » :

1. ✅ Alimentant `/dev/random` avec plusieurs sources d’entropie.
2. ✅ Éliminant la privation d’entropie.
3. ✅ Bloquant plutôt que d’autoriser des opérations non sûres.
4. ✅ Imposant une configuration GRUB qui désactive `/dev/urandom`.
5. ✅ Offrant un monitoring complet de la santé et du débit.

Pour une description encore plus détaillée de l’architecture d’entropie, voir **CRYPTOGRAPHIC-SECURITY-FR.md**. C’est ici que vous transformez une hypothèse floue sur « l’aléa système » en une position mesurable et difficile à attaquer.
