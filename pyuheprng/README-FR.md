# pyuheprng – Service d’entropie cryptographique

[English](README.md)

## Universal Hardware Entropy Protocol Random Number Generator

Composant d’infrastructure qui alimente directement `/dev/random` avec une entropie cryptographiquement sûre issue de plusieurs sources, pour que tout le reste de la pile soit soit sûr, soit bloqué.

## ⚠️ Comportement en cas d’entropie faible (profil expérimental)

Ce service peut **bloquer** certaines opérations cryptographiques s’il estime que l’entropie disponible est insuffisante. Il privilégie ainsi la sécurité perçue par rapport à la disponibilité, ce qui **peut ne pas convenir à tous les environnements**.

Si l’entropie semble insuffisante, les opérations cryptographiques se mettent en pause jusqu’à ce que le niveau revienne au‑dessus d’un seuil. Ce comportement est **un choix de conception**, inspiré de la documentation du RNG Linux (`random(4)`), et doit être évalué par chaque opérateur selon son propre modèle de menace.

Pour les équipes secops/devops, vous pouvez considérer `pyuheprng` comme un disjoncteur : s’il bloque, c’est pour éviter que l’infrastructure ne signe des opérations dans des conditions d’entropie jugées défavorables.

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

Sur des hôtes correctement configurés, ce design vise à **réduire nettement le risque de privation d’entropie** :

- Alimentation continue de `/dev/random`.
- Sources multiples (RC4OK + matériel + UHEP).
- Aucun repli volontaire vers un RNG considéré faible.
- Blocage du système si l’entropie semble insuffisante.

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

La documentation du RNG Linux (`random(4)`) indique que `/dev/urandom` est prévu pour être adapté à la plupart des usages cryptographiques une fois le pool initialisé. Dans ce projet, nous choisissons un profil **plus conservateur** :

- Éviter `/dev/urandom` comme source d’aléa pour la cryptographie dans ce conteneur.
- Forcer les opérations sensibles à passer par `/dev/random`, alimenté par `pyuheprng`.
- Accepter un risque de blocage plus fréquent pour réduire la probabilité d’utiliser un aléa manifestement faible.

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

## Propriétés de sécurité (objectifs de conception)

### 1. Réduction de l’aléa faible

- ✅ Le système est conçu pour éviter autant que possible un aléa clairement prévisible.
- ✅ Il préfère bloquer plutôt que de continuer en mode dégradé.
- ✅ `/dev/urandom` est évité pour la crypto dans ce profil.

### 2. Limitation de l’épuisement d’entropie

- ✅ `/dev/random` est alimenté en continu.
- ✅ Multiples sources d’entropie indépendantes sont combinées.
- ✅ Un basculement simple entre sources et des healthchecks de base sont présents.

### 3. Hypothèses de force cryptographique

- ✅ RC4OK : aléa dérivé de la blockchain Emercoin, supposé fort selon sa documentation.
- ✅ Matériel : sources physiques (RNG matériels, CPU, TPM, bruit environnemental).
- ✅ UHEP : agrégation de ces sources matérielles.
- ✅ Mélange SHA‑512 : combinaison cryptographique standard.

### 4. Réduction de la confiance implicite dans le matériel

- ✅ GRUB désactive la confiance CPU et bootloader.
- ✅ Les sources sont combinées et monitorées, mais sans certification formelle.

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

`pyuheprng` vise à **améliorer la gestion de l’entropie** pour les opérations sensibles, en durcissant la base plutôt qu’en espérant que « tout se passera bien » :

1. ✅ En alimentant `/dev/random` avec plusieurs sources d’entropie.
2. ✅ En cherchant à réduire la privation d’entropie sur les hôtes correctement configurés.
3. ✅ En préférant bloquer plutôt que d’autoriser des opérations jugées non sûres.
4. ✅ En proposant un profil GRUB qui désactive `/dev/urandom` pour la crypto dans ce contexte.
5. ✅ En offrant un monitoring de base de la santé et du débit.

Il s’agit d’une configuration **expérimentale**, qui repose sur des hypothèses de sécurité à vérifier dans votre propre contexte. Pour une description plus détaillée de l’architecture d’entropie et des références externes (Linux RNG, UHEPRNG, Emercoin), voir **CRYPTOGRAPHIC-SECURITY-FR.md** et `SOURCES.md` à la racine du dépôt.
