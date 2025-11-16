# Blockchain Ness

[English](README.md)

Blockchain native du réseau Privateness – registre d’autorité pour les états et contrats critiques de l’écosystème décentralisé.

## Fonctionnalités

- **Blockchain native** : conçue spécifiquement pour privateness.network.
- **Smarter contracts** : plateforme pour applications décentralisées (dApps).
- **Finalité rapide** : confirmations de transactions rapides.
- **Frais faibles** : coûts de transaction minimaux.
- **Interopérabilité** : fonctionne en tandem avec Emercoin pour une sécurité duale.

- **Backbone d’état** : sert de registre durable pour les décisions, politiques et artefacts que vous ne pouvez pas vous permettre de perdre ou de falsifier.

## Déploiement

### Docker Run

```bash
docker run -d \
  --name ness-blockchain \
  -v ness-data:/data/ness \
  -p 6006:6006 \
  -p 6660:6660 \
  -e NESS_RPC_USER=nessuser \
  -e NESS_RPC_PASS=securepassword \
  nessnetwork/ness-blockchain
```

### Docker Compose

```yaml
services:
  ness-blockchain:
    image: nessnetwork/ness-blockchain:latest
    container_name: ness-blockchain
    volumes:
      - ness-data:/data/ness
    ports:
      - "6006:6006"  # P2P
      - "6660:6660"  # RPC
    environment:
      - NESS_RPC_USER=nessuser
      - NESS_RPC_PASS=securepassword
      - NESS_MAX_CONNECTIONS=125
      - NESS_DB_CACHE=450
    restart: unless-stopped

volumes:
  ness-data:
```

## Ports

- **6006** : port réseau P2P.
- **6660** : port API RPC.

## Variables d’environnement

- `NESS_RPC_USER` : utilisateur RPC (défaut : `nessuser`).
- `NESS_RPC_PASS` : mot de passe RPC (défaut : `nesspassword`).
- `NESS_MAX_CONNECTIONS` : nombre max de pairs (défaut : 125).
- `NESS_DB_CACHE` : taille du cache DB en Mo (défaut : 450).
- `NESS_MAX_MEMPOOL` : taille max du mempool en Mo (défaut : 300).
- `NESS_DEBUG` : niveau de log debug (défaut : 0).

## Utilisation CLI

Toutes les commandes s’exécutent via `ness-cli` dans le conteneur.

### État du nœud

```bash
docker exec ness-blockchain ness-cli getinfo
```

### Infos blockchain

```bash
docker exec ness-blockchain ness-cli getblockchaininfo
```

### Infos peers

```bash
docker exec ness-blockchain ness-cli getpeerinfo
```

### Infos réseau

```bash
docker exec ness-blockchain ness-cli getnetworkinfo
```

### Portefeuille

```bash
# Créer un wallet
docker exec ness-blockchain ness-cli createwallet "mywallet"

# Nouvelle adresse
docker exec ness-blockchain ness-cli getnewaddress

# Solde
docker exec ness-blockchain ness-cli getbalance

# Envoyer une transaction
docker exec ness-blockchain ness-cli sendtoaddress <address> <amount>
```

## API RPC

### Exemple Python

```python
import requests

rpc_user = "nessuser"
rpc_pass = "securepassword"
rpc_url = "http://localhost:6660"

def rpc_call(method, params=[]):
    payload = {
        "jsonrpc": "1.0",
        "id": "python",
        "method": method,
        "params": params,
    }
    response = requests.post(rpc_url, json=payload, auth=(rpc_user, rpc_pass))
    return response.json()["result"]

info = rpc_call("getblockchaininfo")
print(f"Blocks: {info['blocks']}")
print(f"Chain: {info['chain']}")
```

### Exemple JavaScript

```javascript
const axios = require('axios');

const rpcClient = axios.create({
  baseURL: 'http://localhost:6660',
  auth: {
    username: 'nessuser',
    password: 'securepassword',
  },
});

async function rpcCall(method, params = []) {
  const response = await rpcClient.post('/', {
    jsonrpc: '1.0',
    id: 'javascript',
    method,
    params,
  });
  return response.data.result;
}

(async () => {
  const info = await rpcCall('getblockchaininfo');
  console.log(`Blocks: ${info.blocks}`);
  console.log(`Chain: ${info.chain}`);
})();
```

## Intégration avec le réseau Privateness

### Architecture duale

La blockchain Ness fonctionne aux côtés d’Emercoin pour renforcer la sécurité :

```text
Blockchain Ness (native)
    ↓
Emercoin (sécurité éprouvée)
    ↓
Consensus combiné
```

Pour un attaquant, cela signifie qu’il ne suffit pas de compromettre une seule chaîne ou un ensemble local de nœuds : le modèle suppose qu’il doit casser deux fondations indépendantes, ce qui relève plus de la théorie que de la pratique dans un environnement correctement opéré.

### Cas d’usage

1. **Smarter contracts** – déploiement de dApps sur Ness.
2. **Tokens** – émission de tokens personnalisés.
3. **NFTs** – création et échange de NFTs.
4. **DeFi** – applications de finance décentralisée.
5. **DAO** – gouvernance décentralisée.

## Supervision

### Synchronisation

```bash
# Hauteur de bloc
docker exec ness-blockchain ness-cli getblockcount

# État de sync
docker exec ness-blockchain ness-cli getblockchaininfo | grep -E "blocks|headers"
```

### Connexions

```bash
# Nombre de connexions
docker exec ness-blockchain ness-cli getconnectioncount

# Détails des pairs
docker exec ness-blockchain ness-cli getpeerinfo
```

### Mempool

```bash
# Infos mempool
docker exec ness-blockchain ness-cli getmempoolinfo

# Transactions en mempool
docker exec ness-blockchain ness-cli getrawmempool
```

## Sauvegarde & restauration

### Sauvegarder le wallet

```bash
# Dans le conteneur
docker exec ness-blockchain ness-cli backupwallet /data/ness/wallet-backup.dat

# Copier sur l’hôte
docker cp ness-blockchain:/data/ness/wallet-backup.dat ./wallet-backup.dat
```

### Restaurer le wallet

```bash
# Copier dans le conteneur
docker cp ./wallet-backup.dat ness-blockchain:/data/ness/wallet-restore.dat

# Restaurer
docker exec ness-blockchain ness-cli restorewallet "restored" /data/ness/wallet-restore.dat
```

### Sauvegarde des données blockchain

```bash
# Arrêter le conteneur
docker stop ness-blockchain

# Sauvegarder les données
docker run --rm -v ness-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/ness-blockchain-backup.tar.gz /data

# Redémarrer
docker start ness-blockchain
```

## Optimisation des performances

### Cache DB

```bash
# Augmenter le cache DB (en Mo)
docker run -e NESS_DB_CACHE=2048 nessnetwork/ness-blockchain
```

### Nombre de connexions

```bash
# Augmenter le nombre de pairs
docker run -e NESS_MAX_CONNECTIONS=250 nessnetwork/ness-blockchain
```

### Pruning (économie de disque)

Dans `ness.conf` :

```text
prune=550  # Ne conserver qu’environ 550 Mo de blocs
```

## Sécurité

### Sécuriser l’accès RPC

1. Utiliser un mot de passe RPC fort.
2. Lier le RPC à `localhost` uniquement en production.
3. Restreindre le port RPC via firewall.
4. (Recommandé) Activer TLS/SSL pour l’API RPC.

### Chiffrement du wallet

```bash
# Chiffrer le wallet
docker exec ness-blockchain ness-cli encryptwallet "votre-passphrase"

# Déverrouiller temporairement
docker exec ness-blockchain ness-cli walletpassphrase "votre-passphrase" 600
```

## Environnements de test

### Testnet

```bash
docker run -e NESS_TESTNET=1 nessnetwork/ness-blockchain
```

### Regtest (tests locaux)

```bash
docker run -e NESS_REGTEST=1 nessnetwork/ness-blockchain
```

## Ressources

- GitHub : [https://github.com/ness-network/ness](https://github.com/ness-network/ness)
- Documentation : [https://docs.privateness.network](https://docs.privateness.network)
- Explorateur : [https://explorer.privateness.network](https://explorer.privateness.network)
- API : [https://api.privateness.network](https://api.privateness.network)

## Support

Pour les issues et questions :

- GitHub Issues : [https://github.com/ness-network/ness/issues](https://github.com/ness-network/ness/issues)
- Communauté : [https://community.privateness.network](https://community.privateness.network)
