# Ness Blockchain

[Français](README-FR.md)

Privateness Network's native blockchain - the foundation of the decentralized ecosystem.

## Features

- **Native blockchain**: Purpose-built for privateness.network
- **Smart contracts**: Decentralized application platform
- **Fast finality**: Quick transaction confirmation
- **Low fees**: Minimal transaction costs
- **Interoperability**: Works with Emercoin for dual-chain security

## Deployment

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

- **6006**: P2P network port
- **6660**: RPC API port

## Environment Variables

- `NESS_RPC_USER`: RPC username (default: nessuser)
- `NESS_RPC_PASS`: RPC password (default: nesspassword)
- `NESS_MAX_CONNECTIONS`: Max peer connections (default: 125)
- `NESS_DB_CACHE`: Database cache size in MB (default: 450)
- `NESS_MAX_MEMPOOL`: Max mempool size in MB (default: 300)
- `NESS_DEBUG`: Debug logging level (default: 0)

## CLI Usage

### Check Node Status

```bash
docker exec ness-blockchain ness-cli getinfo
```

### Get Blockchain Info

```bash
docker exec ness-blockchain ness-cli getblockchaininfo
```

### Get Peer Info

```bash
docker exec ness-blockchain ness-cli getpeerinfo
```

### Get Network Info

```bash
docker exec ness-blockchain ness-cli getnetworkinfo
```

### Create Wallet

```bash
docker exec ness-blockchain ness-cli createwallet "mywallet"
```

### Get New Address

```bash
docker exec ness-blockchain ness-cli getnewaddress
```

### Check Balance

```bash
docker exec ness-blockchain ness-cli getbalance
```

### Send Transaction

```bash
docker exec ness-blockchain ness-cli sendtoaddress <address> <amount>
```

## RPC API

### Python Example

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
        "params": params
    }
    response = requests.post(
        rpc_url,
        json=payload,
        auth=(rpc_user, rpc_pass)
    )
    return response.json()['result']

# Get blockchain info
info = rpc_call("getblockchaininfo")
print(f"Blocks: {info['blocks']}")
print(f"Chain: {info['chain']}")
```

### JavaScript Example

```javascript
const axios = require('axios');

const rpcClient = axios.create({
    baseURL: 'http://localhost:6660',
    auth: {
        username: 'nessuser',
        password: 'securepassword'
    }
});

async function rpcCall(method, params = []) {
    const response = await rpcClient.post('/', {
        jsonrpc: '1.0',
        id: 'javascript',
        method: method,
        params: params
    });
    return response.data.result;
}

// Get blockchain info
const info = await rpcCall('getblockchaininfo');
console.log(`Blocks: ${info.blocks}`);
console.log(`Chain: ${info.chain}`);
```

## Integration with Privateness Network

### Dual-Chain Architecture

Ness blockchain works alongside Emercoin for enhanced security:

```text
Ness Blockchain (Native)
    ↓
Emercoin (Established security)
    ↓
Combined consensus
```

### Use Cases

1. **Smart Contracts**: Deploy dApps on Ness blockchain
2. **Token Issuance**: Create custom tokens
3. **NFTs**: Mint and trade NFTs
4. **DeFi**: Decentralized finance applications
5. **DAO**: Decentralized governance

## Monitoring

### Check Sync Status

```bash
# Get current block height
docker exec ness-blockchain ness-cli getblockcount

# Get sync status
docker exec ness-blockchain ness-cli getblockchaininfo | grep -E "blocks|headers"
```

### Monitor Connections

```bash
# Get peer count
docker exec ness-blockchain ness-cli getconnectioncount

# Get peer details
docker exec ness-blockchain ness-cli getpeerinfo
```

### Check Mempool

```bash
# Get mempool info
docker exec ness-blockchain ness-cli getmempoolinfo

# Get mempool transactions
docker exec ness-blockchain ness-cli getrawmempool
```

## Backup & Recovery

### Backup Wallet

```bash
# Backup wallet
docker exec ness-blockchain ness-cli backupwallet /data/ness/wallet-backup.dat

# Copy from container
docker cp ness-blockchain:/data/ness/wallet-backup.dat ./wallet-backup.dat
```

### Restore Wallet

```bash
# Copy to container
docker cp ./wallet-backup.dat ness-blockchain:/data/ness/wallet-restore.dat

# Restore wallet
docker exec ness-blockchain ness-cli restorewallet "restored" /data/ness/wallet-restore.dat
```

### Backup Blockchain Data

```bash
# Stop container
docker stop ness-blockchain

# Backup data
docker run --rm -v ness-data:/data -v $(pwd):/backup \
    alpine tar czf /backup/ness-blockchain-backup.tar.gz /data

# Start container
docker start ness-blockchain
```

## Performance Tuning

### Increase Cache

```bash
# Set larger DB cache (in MB)
docker run -e NESS_DB_CACHE=2048 nessnetwork/ness-blockchain
```

### Increase Connections

```bash
# Allow more peer connections
docker run -e NESS_MAX_CONNECTIONS=250 nessnetwork/ness-blockchain
```

### Enable Pruning (Save Disk Space)

Add to `ness.conf`:

```text
prune=550  # Keep only last 550MB of blocks
```

## Troubleshooting

### Node Not Syncing

```bash
# Check peer connections
docker exec ness-blockchain ness-cli getpeerinfo

# Add nodes manually
docker exec ness-blockchain ness-cli addnode <node-ip>:9333 add
```

### RPC Connection Issues

```bash
# Check RPC is listening
docker exec ness-blockchain netstat -tlnp | grep 6660

# Test RPC connection
curl --user nessuser:password \
    --data-binary '{"jsonrpc":"1.0","id":"test","method":"getinfo","params":[]}' \
    -H 'content-type: text/plain;' \
    http://localhost:6660/
```

### High Memory Usage

```bash
# Reduce cache size
docker run -e NESS_DB_CACHE=256 nessnetwork/ness-blockchain

# Reduce mempool size
docker run -e NESS_MAX_MEMPOOL=100 nessnetwork/ness-blockchain
```

## Security

### Secure RPC Access

1. Use strong RPC password
2. Bind RPC to localhost only (production)
3. Use firewall to restrict RPC port
4. Enable SSL/TLS for RPC (recommended)

### Wallet Encryption

```bash
# Encrypt wallet
docker exec ness-blockchain ness-cli encryptwallet "your-passphrase"

# Unlock wallet
docker exec ness-blockchain ness-cli walletpassphrase "your-passphrase" 600
```

## Development

### Run Testnet

```bash
docker run -e NESS_TESTNET=1 nessnetwork/ness-blockchain
```

### Run Regtest (Local Testing)

```bash
docker run -e NESS_REGTEST=1 nessnetwork/ness-blockchain
```

## Resources

- GitHub: <https://github.com/ness-network/ness>
- Documentation: <https://docs.privateness.network>
- Explorer: <https://explorer.privateness.network>
- API Docs: <https://api.privateness.network>

## Support

For issues and questions:

- GitHub Issues: <https://github.com/ness-network/ness/issues>
- Community: <https://community.privateness.network>
