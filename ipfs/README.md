# IPFS Daemon - Decentralized Storage

InterPlanetary File System (IPFS) daemon for decentralized content-addressed storage.

## Features

- **Content-addressed storage**: Files identified by cryptographic hash
- **Decentralized**: No central servers
- **Peer-to-peer**: Direct file sharing between nodes
- **Permanent web**: Content can't be deleted if pinned
- **Integration**: Works with Emercoin blockchain for naming

## Deployment

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

- **4001**: P2P swarm (TCP/UDP) - peer connections
- **5001**: HTTP API - programmatic access
- **8080**: Gateway - HTTP access to IPFS content
- **8081**: WebUI - web interface

## Usage

### Add File to IPFS

```bash
# Add file
docker exec ipfs ipfs add /path/to/file

# Returns hash like: QmXxx...
```

### Get File from IPFS

```bash
# Get by hash
docker exec ipfs ipfs get QmXxx...

# Or via gateway
curl http://localhost:8080/ipfs/QmXxx...
```

### Pin Content (Keep Forever)

```bash
# Pin file
docker exec ipfs ipfs pin add QmXxx...

# List pinned files
docker exec ipfs ipfs pin ls
```

### Node Information

```bash
# Node ID and addresses
docker exec ipfs ipfs id

# Connected peers
docker exec ipfs ipfs swarm peers

# Repository stats
docker exec ipfs ipfs repo stat
```

## Integration with Privateness Network

### Emercoin + IPFS Naming

```bash
# Store IPFS hash in Emercoin blockchain
emercoin-cli name_new "ipfs:myfile" "QmXxx..."

# Resolve via Emercoin
emercoin-cli name_show "ipfs:myfile"
# Returns: QmXxx...

# Access via IPFS
ipfs get QmXxx...
```

### Use Cases

1. **Decentralized website hosting**
   - Upload site to IPFS
   - Register hash in Emercoin
   - Access via IPFS gateway

2. **Permanent file storage**
   - Upload to IPFS
   - Pin on multiple nodes
   - Content persists forever

3. **Content distribution**
   - Upload once
   - Peers distribute automatically
   - No bandwidth costs

4. **Blockchain data storage**
   - Store large data in IPFS
   - Store hash in blockchain
   - Verify integrity via hash

## Configuration

### Storage Limit

```bash
# Set max storage (default: 10GB)
docker run -e IPFS_STORAGE_MAX=50GB nessnetwork/ipfs
```

### Garbage Collection

Automatic garbage collection runs every hour to remove unpinned content.

```bash
# Manual garbage collection
docker exec ipfs ipfs repo gc
```

### Bootstrap Nodes

IPFS connects to default bootstrap nodes. To add custom nodes:

```bash
# Add bootstrap node
docker exec ipfs ipfs bootstrap add /ip4/1.2.3.4/tcp/4001/p2p/QmXxx...

# List bootstrap nodes
docker exec ipfs ipfs bootstrap list
```

## WebUI

Access IPFS WebUI at: **http://localhost:8081/webui**

Features:
- File browser
- Peer connections
- Repository stats
- Settings

## API Examples

### Python

```python
import requests

# Add file
files = {'file': open('myfile.txt', 'rb')}
response = requests.post('http://localhost:5001/api/v0/add', files=files)
hash = response.json()['Hash']

# Get file
response = requests.post(f'http://localhost:5001/api/v0/cat?arg={hash}')
content = response.content
```

### JavaScript

```javascript
const ipfsClient = require('ipfs-http-client');
const ipfs = ipfsClient.create({ url: 'http://localhost:5001' });

// Add file
const { cid } = await ipfs.add('Hello IPFS!');
console.log('Hash:', cid.toString());

// Get file
const chunks = [];
for await (const chunk of ipfs.cat(cid)) {
    chunks.push(chunk);
}
console.log('Content:', Buffer.concat(chunks).toString());
```

### Bash

```bash
# Add file
curl -F file=@myfile.txt http://localhost:5001/api/v0/add

# Get file
curl "http://localhost:5001/api/v0/cat?arg=QmXxx..."
```

## Monitoring

### Check Health

```bash
# Daemon status
docker exec ipfs ipfs id

# Peer count
docker exec ipfs ipfs swarm peers | wc -l

# Storage usage
docker exec ipfs ipfs repo stat
```

### Logs

```bash
# View logs
docker logs ipfs

# Follow logs
docker logs -f ipfs
```

## Security

### Private Network (Optional)

To create a private IPFS network:

```bash
# Generate swarm key
docker exec ipfs ipfs-swarm-key-gen > swarm.key

# Copy to all nodes
docker cp swarm.key ipfs:/data/ipfs/swarm.key

# Restart daemon
docker restart ipfs
```

### API Access Control

By default, API is only accessible from localhost. To restrict further:

```bash
# Set API to localhost only
docker exec ipfs ipfs config Addresses.API /ip4/127.0.0.1/tcp/5001
```

## Backup

### Export Repository

```bash
# Backup IPFS data
docker run --rm -v ipfs-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/ipfs-backup.tar.gz /data
```

### Restore Repository

```bash
# Restore IPFS data
docker run --rm -v ipfs-data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/ipfs-backup.tar.gz -C /
```

## Performance Tuning

### Increase Connections

```bash
# Allow more peer connections
docker exec ipfs ipfs config --json Swarm.ConnMgr.HighWater 900
docker exec ipfs ipfs config --json Swarm.ConnMgr.LowWater 600
```

### Enable Experimental Features

```bash
# QUIC transport (faster)
docker exec ipfs ipfs config --json Experimental.QUIC true

# Accelerated DHT
docker exec ipfs ipfs config --json Experimental.AcceleratedDHTClient true
```

## Troubleshooting

### Can't Connect to Peers

```bash
# Check firewall allows port 4001
# Check NAT/port forwarding

# Test connectivity
docker exec ipfs ipfs swarm peers
```

### High Storage Usage

```bash
# Run garbage collection
docker exec ipfs ipfs repo gc

# Reduce storage limit
docker exec ipfs ipfs config Datastore.StorageMax 10GB
```

### Slow Performance

```bash
# Check peer count (should be > 10)
docker exec ipfs ipfs swarm peers | wc -l

# Add more bootstrap nodes
docker exec ipfs ipfs bootstrap add <peer-address>
```

## Resources

- IPFS Documentation: https://docs.ipfs.tech
- IPFS Gateway: https://ipfs.io
- Public Gateways: https://ipfs.github.io/public-gateway-checker/
