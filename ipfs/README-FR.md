# Démon IPFS – Stockage décentralisé

[English](README.md)

InterPlanetary File System (IPFS) – démon pour le stockage décentralisé adressé par contenu, utilisé ici comme couche de stockage immuable pour des données critiques du réseau Privateness.

## Fonctionnalités

- **Stockage adressé par contenu** : fichiers identifiés par un hash cryptographique
- **Décentralisé** : pas de serveurs centraux
- **Pair à pair** : partage direct de fichiers entre nœuds
- **Web permanent** : le contenu ne disparaît pas tant qu’il est « pinned »
- **Intégration** : fonctionne avec la blockchain Emercoin pour le nommage

## Déploiement

### Docker Run

```bash
docker run -d \
  --name ipfs \
  -v ipfs-data:/data/ipfs \
  -p 4001:4001 \
  -p 5001:5001 \
  -p 8080:8080 \
  -p 8081:8081 \
  -e IPFS_STORAGE_MAX=50GB \
  nessnetwork/ipfs
```

### Docker Compose

```yaml
services:
  ipfs:
    image: nessnetwork/ipfs:latest
    container_name: ipfs
    volumes:
      - ipfs-data:/data/ipfs
    ports:
      - "4001:4001"     # P2P swarm
      - "5001:5001"     # API
      - "8080:8080"     # Gateway
      - "8081:8081"     # WebUI
    environment:
      - IPFS_STORAGE_MAX=50GB
    restart: unless-stopped

volumes:
  ipfs-data:
```

## Ports

- **4001** : swarm P2P (TCP/UDP) – connexions entre pairs
- **5001** : API HTTP – accès programmatique
- **8080** : gateway HTTP – accès aux contenus IPFS
- **8081** : WebUI – interface Web

## Utilisation

### Ajouter un fichier à IPFS

```bash
# Ajouter un fichier
docker exec ipfs ipfs add /path/to/file

# Retourne un hash du type : QmXxx...
```

### Récupérer un fichier depuis IPFS

```bash
# Récupérer par hash
docker exec ipfs ipfs get QmXxx...

# Ou via la gateway
curl http://localhost:8080/ipfs/QmXxx...
```

### Pinner du contenu (le conserver)

```bash
# Pinner un fichier
docker exec ipfs ipfs pin add QmXxx...

# Lister les contenus « pinned »
docker exec ipfs ipfs pin ls
```

### Informations sur le nœud

```bash
# ID du nœud et adresses
docker exec ipfs ipfs id

# Pairs connectés
docker exec ipfs ipfs swarm peers

# Statistiques du dépôt
docker exec ipfs ipfs repo stat
```

## Intégration avec le réseau Privateness

Dans le réseau Privateness, IPFS joue le rôle de coffre‑fort distribué : ce que vous y placez reste vérifiable, même si l’infrastructure qui l’entoure disparaît ou est compromise.

### Nommage Emercoin + IPFS

```bash
# Stocker un hash IPFS dans la blockchain Emercoin
emercoin-cli name_new "ipfs:myfile" "QmXxx..."

# Résoudre via Emercoin
emercoin-cli name_show "ipfs:myfile"
# Retourne : QmXxx...

# Accéder via IPFS
ipfs get QmXxx...
```

### Cas d’usage

1. **Hébergement de site décentralisé**
   - Uploader le site sur IPFS
   - Enregistrer le hash dans Emercoin
   - Accéder via la gateway IPFS

2. **Stockage permanent de fichiers**
   - Uploader sur IPFS
   - Pinner sur plusieurs nœuds
   - Le contenu persiste tant qu’il est pin

3. **Distribution de contenu**
   - Uploader une fois
   - Les pairs répliquent automatiquement
   - Pas de coût de bande passante centralisé

4. **Stockage de données blockchain volumineuses**
   - Stocker les gros fichiers dans IPFS
   - N’enregistrer que le hash dans la blockchain
   - Vérifier l’intégrité via le hash

## Configuration

### Limite de stockage

```bash
# Définir la capacité max (par défaut : 10 Go)
docker run -e IPFS_STORAGE_MAX=50GB nessnetwork/ipfs
```

### Garbage collection

Une collecte automatique des objets non « pinned » peut être exécutée régulièrement.

```bash
# Garbage collection manuelle
docker exec ipfs ipfs repo gc
```

### Nœuds bootstrap

Par défaut, IPFS se connecte à des nœuds bootstrap publics. Pour en ajouter :

```bash
# Ajouter un nœud bootstrap
docker exec ipfs ipfs bootstrap add /ip4/1.2.3.4/tcp/4001/p2p/QmXxx...

# Lister les nœuds bootstrap
docker exec ipfs ipfs bootstrap list
```

## WebUI

Accéder à la WebUI IPFS : **[http://localhost:8081/webui](http://localhost:8081/webui)**

Fonctionnalités :

- Navigateur de fichiers
- Connexions aux pairs
- Statistiques du dépôt
- Paramètres

## Exemples d’API

### Python

```python
import requests

# Ajouter un fichier
files = {'file': open('myfile.txt', 'rb')}
response = requests.post('http://localhost:5001/api/v0/add', files=files)
hash = response.json()['Hash']

# Récupérer le fichier
response = requests.post(f'http://localhost:5001/api/v0/cat?arg={hash}')
content = response.content
```

### JavaScript

```javascript
const ipfsClient = require('ipfs-http-client');
const ipfs = ipfsClient.create({ url: 'http://localhost:5001' });

// Ajouter un fichier
const { cid } = await ipfs.add('Hello IPFS!');
console.log('Hash:', cid.toString());

// Récupérer un fichier
const chunks = [];
for await (const chunk of ipfs.cat(cid)) {
    chunks.push(chunk);
}
console.log('Content:', Buffer.concat(chunks).toString());
```

### Bash

```bash
# Ajouter un fichier
curl -F file=@myfile.txt http://localhost:5001/api/v0/add

# Récupérer un fichier
curl "http://localhost:5001/api/v0/cat?arg=QmXxx..."
```

## Supervision

### Vérifier la santé

```bash
# Statut du démon
docker exec ipfs ipfs id

# Nombre de pairs
docker exec ipfs ipfs swarm peers | wc -l

# Utilisation du dépôt
docker exec ipfs ipfs repo stat
```

### Logs

```bash
# Voir les logs
docker logs ipfs

# Suivre les logs en temps réel
docker logs -f ipfs
```

## Sécurité

### Réseau IPFS privé (optionnel)

Pour créer un réseau IPFS privé :

```bash
# Générer une swarm key
docker exec ipfs ipfs-swarm-key-gen > swarm.key

# Copier sur tous les nœuds
docker cp swarm.key ipfs:/data/ipfs/swarm.key

# Redémarrer le démon
docker restart ipfs
```

### Contrôle d’accès à l’API

Par défaut, l’API n’est accessible que depuis localhost. Pour restreindre davantage :

```bash
# Forcer l’API à écouter seulement sur localhost
docker exec ipfs ipfs config Addresses.API /ip4/127.0.0.1/tcp/5001
```

## Sauvegarde

### Export du dépôt

```bash
# Sauvegarde des données IPFS
docker run --rm -v ipfs-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/ipfs-backup.tar.gz /data
```

### Restauration du dépôt

```bash
# Restauration des données IPFS
docker run --rm -v ipfs-data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/ipfs-backup.tar.gz -C /
```

## Optimisation des performances

### Augmenter le nombre de connexions

```bash
# Autoriser plus de pairs connectés
docker exec ipfs ipfs config --json Swarm.ConnMgr.HighWater 900
docker exec ipfs ipfs config --json Swarm.ConnMgr.LowWater 600
```

### Activer les fonctionnalités expérimentales

```bash
# Transport QUIC (plus rapide)
docker exec ipfs ipfs config --json Experimental.QUIC true

# DHT accélérée
docker exec ipfs ipfs config --json Experimental.AcceleratedDHTClient true
```

## Dépannage

### Impossible de se connecter aux pairs

```bash
# Vérifier que le firewall autorise le port 4001
# Vérifier la configuration NAT / redirection de port

# Tester la connectivité
docker exec ipfs ipfs swarm peers
```

### Utilisation disque trop élevée

```bash
# Lancer une garbage collection
docker exec ipfs ipfs repo gc

# Réduire la limite de stockage
docker exec ipfs ipfs config Datastore.StorageMax 10GB
```

### Performances lentes

```bash
# Vérifier le nombre de pairs (doit être > 10)
docker exec ipfs ipfs swarm peers | wc -l

# Ajouter des nœuds bootstrap supplémentaires
docker exec ipfs ipfs bootstrap add <peer-address>
```

## Ressources

- Documentation IPFS : [https://docs.ipfs.tech](https://docs.ipfs.tech)
- Gateway IPFS : [https://ipfs.io](https://ipfs.io)
- Liste de gateways publiques : [https://ipfs.github.io/public-gateway-checker/](https://ipfs.github.io/public-gateway-checker/)
