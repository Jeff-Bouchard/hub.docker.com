# Builds reproductibles – Équivalence binaire

## ⚠️ EXIGENCE CRITIQUE

**Tous les nœuds DOIVENT être binaires équivalents, sinon la « décentralisation » est du bullshit.**

Dans un réseau réellement décentralisé, chaque nœud doit pouvoir vérifier que :

1. Tous les autres nœuds exécutent des **binaires strictement identiques**.
2. Aucun nœud n’a été compromis ou modifié.
3. Le consensus du réseau repose sur du **code vérifié et identique**.

Sans builds reproductibles, un attaquant peut fournir un binaire différent à chaque nœud, tout en prétendant utiliser la même version.

## Problème des builds non reproductibles

### Sans équivalence binaire

```text
Nœud A : build depuis la source → Binaire A (hash : abc123...)
Nœud B : build depuis la source → Binaire B (hash : def456...)
Nœud C : build depuis la source → Binaire C (hash : 789xyz...)

Résultat : BINAIRES DIFFÉRENTS
- Impossible de vérifier l’intégrité du réseau
- Impossible de détecter les nœuds compromis
- Impossible de faire confiance au consensus
- La « décentralisation » est FAUSSE
```

### Avec équivalence binaire (builds reproductibles)

```text
Nœud A : build → Binaire (hash : abc123...)
Nœud B : build → Binaire (hash : abc123...)
Nœud C : build → Binaire (hash : abc123...)

Résultat : BINAIRES IDENTIQUES
✓ Intégrité du réseau vérifiable
✓ Nœuds compromis détectables
✓ Consensus digne de confiance
✓ VRAIE décentralisation
```

## Exigences pour un build reproductible

### 1. Compilation déterministe

Les builds doivent produire des binaires **bit‑à‑bit identiques**.

Principes généraux :

- Pinner les images de base par **digest** (`@sha256:...`) et non par tag mutable.
- Fixer les versions des compilateurs et outils (gcc, go, python, etc.).
- Éviter tout usage de l’heure système ou de chemins locaux dans les métadonnées binaires.

Exemple (idée) :

```dockerfile
# Mauvais – non déterministe
FROM ubuntu:latest
RUN apt-get update && apt-get install -y build-essential
RUN git clone https://github.com/repo/project.git
RUN cd project && make

# Bon – plus déterministe
FROM ubuntu:22.04@sha256:...
ENV SOURCE_DATE_EPOCH=1609459200
RUN apt-get update && apt-get install -y \
    build-essential=12.9ubuntu3 \
    git=1:2.34.1-1ubuntu1
RUN git clone --depth 1 --branch v1.0.0 https://github.com/repo/project.git
RUN cd project && make CFLAGS="-ffile-prefix-map=$(pwd)=."
```

### 2. Dépendances figées

Toutes les dépendances doivent être **pinnées** à des versions exactes :

- Python : `requests==2.28.1`, `flask==2.2.2`, etc.
- Go : modules avec `@vX.Y.Z` ou `go.mod` figé.
- Debian/Ubuntu : paquets avec `=version‑exacte`.

### 3. Normalisation des timestamps

Les timestamps ne doivent pas influencer le binaire.

Idées :

- Utiliser `SOURCE_DATE_EPOCH`.
- Normaliser les dates des fichiers (`touch -d @${SOURCE_DATE_EPOCH}` sur tous les fichiers).
- Stripper les sections contenant des dates / chemins de build.

### 4. Normalisation des chemins

Le chemin de build local ne doit pas apparaître dans le binaire.

Exemple :

```makefile
# Mauvais – embarque le chemin PWD
CFLAGS = -g -O2

# Bon – remappe le préfixe de fichier
CFLAGS = -g -O2 -ffile-prefix-map=$(PWD)=.
```

### 5. Environnement figé

- Locale fixe (ex. `LANG=C.UTF-8`, `LC_ALL=C.UTF-8`).
- Fuseau horaire fixe (`TZ=UTC`).
- Désactivation des aléas internes (`PYTHONHASHSEED=0`, etc.).

## Implémentation dans Privateness Network

Chaque image critique (Emercoin Core, Skywire, pyuheprng, Privateness, etc.) doit :

- Pinner son image de base par digest (`FROM ...@sha256:...`).
- Télécharger des releases signées/avec hash attendu.
- Calculer et stocker un hash SHA‑256 des binaires résultants dans l’image (ex : `/emercoin.hash`, `/skywire.hash`, ...).

Exemple conceptuel pour Emercoin Core :

```dockerfile
FROM debian:bullseye-20231009-slim@sha256:...

ENV SOURCE_DATE_EPOCH=1609459200
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

ARG EMERCOIN_VERSION=0.8.5
RUN wget https://github.com/emercoin/emercoin/releases/download/v${EMERCOIN_VERSION}/emercoin-${EMERCOIN_VERSION}-x86_64-linux-gnu.tar.gz
RUN echo "expected_sha256_hash  emercoin-${EMERCOIN_VERSION}-x86_64-linux-gnu.tar.gz" | sha256sum -c

# Vérification du binaire
RUN sha256sum emercoind > /emercoin.hash
```

## Processus de vérification

### 1. Générer un manifeste de hash

Pour chaque image, on génère un fichier listant les hashes des binaires importants :

```bash
# Exemple d’idée
docker run ness-network/emercoin-core sha256sum /usr/local/bin/emercoind > emercoin.manifest
docker run ness-network/skywire sha256sum /usr/local/bin/skywire-visor > skywire.manifest
docker run ness-network/pyuheprng find /app -type f -exec sha256sum {} \; > pyuheprng.manifest
```

### 2. Signer le manifeste sur la blockchain

Le manifeste est signé et publié via Emercoin (NVS) :

```bash
emercoin-cli signmessage <address> "$(cat emercoin.manifest)"

emercoin-cli name_new "ness:manifest:emercoin:0.8.5" \
  '{"hash":"abc123...","signature":"xyz789...","timestamp":1609459200}'
```

### 3. Vérifier un nœud à l’exécution

Chaque nœud vérifie au démarrage que son binaire correspond au hash publié :

```bash
#!/bin/bash
# verify-node.sh

EXPECTED_HASH=$(emercoin-cli name_show "ness:manifest:emercoin:0.8.5" | jq -r '.hash')
ACTUAL_HASH=$(sha256sum /usr/local/bin/emercoind | cut -d' ' -f1)

if [ "$EXPECTED_HASH" != "$ACTUAL_HASH" ]; then
    echo "ERROR: Binary hash mismatch!"
    exit 1
fi

echo "✓ Binary verified - node is legitimate"
```

### 4. Vérifier les pairs

Les nœuds refusent les pairs qui ne présentent pas le bon hash (ou une signature non valide) – ce qui empêche l’entrée de binaires modifiés dans le réseau.

## Multi‑architecture

Chaque architecture a son propre manifeste :

```text
ness:manifest:emercoin:0.8.5:amd64   → hash: abc123...
ness:manifest:emercoin:0.8.5:arm64   → hash: def456...
ness:manifest:emercoin:0.8.5:armv7   → hash: 789xyz...
```

Les nœuds comparent leur binaire au manifeste correspondant à leur architecture.

## Vérification des images Docker

### Digests d’image (contenu adressé)

Au lieu de déployer via `image: repo:tag` (tag mutable), on fixe les stacks avec des digests :

```yaml
services:
  emercoin-core:
    # Mauvais : tag mutable
    image: ness-network/emercoin-core:0.8.5

    # Bon : digest immuable
    image: ness-network/emercoin-core@sha256:abc123def456...
```

Les digests eux‑mêmes peuvent aussi être publiés dans Emercoin NVS pour vérification.

## Vérification automatique en CI

Des workflows CI (GitHub Actions, etc.) peuvent :

- Construire une image deux fois.
- Extraire les binaires.
- Comparer récursivement les répertoires de binaires (`diff -r`).
- Échouer le build si les binaires diffèrent.

Cela garantit la reproductibilité dans le temps.

## Pourquoi c’est fondamental

### Sans équivalence binaire

- ❌ Impossible de vérifier l’intégrité des nœuds.
- ❌ Impossible de détecter des binaires backdoorés.
- ❌ Consensus basé uniquement sur la confiance dans le publisher.
- ❌ La « décentralisation » est une illusion.

### Avec équivalence binaire

- ✅ Chaque nœud peut vérifier tous les autres.
- ✅ Les nœuds compromis sont détectables immédiatement.
- ✅ Le consensus est mathématiquement vérifiable.
- ✅ Aucune confiance dans une autorité centrale.
- ✅ **VRAIE décentralisation**.

## Checklist d’implémentation pour chaque service

Pour chaque service de privateness.network :

- [ ] Pinner toutes les images de base par digest.
- [ ] Pinner toutes les dépendances à des versions exactes.
- [ ] Définir `SOURCE_DATE_EPOCH` pour normaliser les timestamps.
- [ ] Utiliser `-trimpath` / `-ffile-prefix-map` pour normaliser les chemins.
- [ ] Fixer la locale et l’environnement.
- [ ] Générer et publier un manifeste de hash binaire.
- [ ] Signer le manifeste via la blockchain Emercoin.
- [ ] Vérifier les binaires au démarrage du nœud.
- [ ] Vérifier les pairs avant d’accepter des connexions.
- [ ] Ajouter un job CI de vérification de reproductibilité.

## Lien avec la sécurité des incitations

L’équivalence binaire est ce qui permet de **payer des nœuds hostiles en toute sécurité** :

1. Vérification binaire → prouve qu’ils exécutent le bon code.
2. Challenge/réponse → prouve qu’ils l’exécutent réellement.
3. Preuve de travail → prouve qu’ils ont fait le travail.
4. Paiement conditionnel → n’est effectué que si tout passe.

Même un opérateur hostile n’a économiquement intérêt qu’à exécuter le binaire légitime.

Voir [INCENTIVE-SECURITY-FR.md](INCENTIVE-SECURITY-FR.md) pour les détails complets sur la rémunération des nœuds hostiles.
