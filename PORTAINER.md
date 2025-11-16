# Portainer Deployment Guide

[Français](PORTAINER-FR.md)

Deploy and manage the entire Privateness Network stack via Portainer.

## Prerequisites

1. **Portainer installed** (Community or Business Edition)
2. **Docker Engine** with privileged mode support
3. **Host requirements**:
   - `/dev/net/tun` device available
   - Kernel modules: `tun`, `amneziawg` (optional)
   - Ports available: 53, 3000, 4444, 5000, 6661-6662, 6668, 7657, 8000-8001, 8053, 8080, 8775, 8888, 9001-9002, 51820-51821

## Deployment Methods

### Method 1: Portainer UI (Recommended)

1. **Login to Portainer** → Navigate to **Stacks**
2. Click **Add Stack**
3. **Name**: `privateness-network`
4. **Build method**: Upload
5. Upload `portainer-stack.yml`
6. Click **Deploy the stack**

### Method 2: Portainer API

```bash
curl -X POST "http://localhost:9000/api/stacks" \
  -H "X-API-Key: YOUR_API_KEY" \
  -F "Name=privateness-network" \
  -F "StackFileContent=@portainer-stack.yml" \
  -F "Env=[{\"name\":\"STACK_ENV\",\"value\":\"production\"}]"
```

### Method 3: Git Repository

1. **Stacks** → **Add Stack**
2. **Build method**: Repository
3. **Repository URL**: `https://github.com/ness-network/docker-hub`
4. **Compose path**: `portainer-stack.yml`
5. **Deploy**

## Stack Variants

### Full Stack (`portainer-stack.yml`)

All 11 services - complete decentralized OSI stack

- **RAM**: ~4GB minimum
- **CPU**: 4+ cores recommended
- **Disk**: 50GB+ for blockchain data

### Minimal Stack (`portainer-stack-minimal.yml`)

Core services only (Emercoin + Yggdrasil + Privateness)

- **RAM**: ~1GB minimum
- **CPU**: 2+ cores
- **Disk**: 20GB+

## Portainer Features

### Service Management

- **Start/Stop/Restart** individual services
- **View logs** in real-time
- **Inspect** container details
- **Execute commands** via web terminal

### Resource Monitoring

- CPU/Memory usage per service
- Network traffic statistics
- Volume usage tracking

### Stack Labels

All services tagged with:

```yaml
labels:
  - "io.portainer.accesscontrol.teams=privateness"
  - "com.privateness.service=<service-name>"
  - "com.privateness.layer=<osi-layer>"
```

Filter by layer:

- `foundation` - Blockchain (Emercoin)
- `network` - Mesh/Anonymity (Yggdrasil, I2P)
- `transport` - VPN/Routing (AmneziaWG, Skywire)
- `application` - Services (Privateness, DNS, RNG, etc.)

## Environment Variables

Configure via Portainer UI or stack file:

```yaml
environment:
  - EMERCOIN_VERSION=0.8.5
  - I2P_VERSION=2.4.0
  - STACK_ENV=production
```

## Volume Management

All volumes labeled for easy identification:

- `emercoin-data` - Blockchain data
- `yggdrasil-data` - Mesh configuration
- `i2p-data` - I2P router data
- `skywire-data` - Skywire node data
- `awg-config` - AmneziaWG configuration

### Backup Volumes

```bash
# Via Portainer UI: Volumes → Select → Download backup
# Or via CLI:
docker run --rm -v emercoin-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/emercoin-backup.tar.gz /data
```

## Access Control

### Team-based Access

1. **Settings** → **Teams** → Create `privateness` team
2. Assign users to team
3. Services auto-restrict to team members (via labels)

### Role-based Permissions

- **Admin**: Full stack control
- **Operator**: Start/stop services, view logs
- **Read-only**: View status only

## Health Monitoring

### Service Health Checks

- **Emercoin**: `emercoin-cli getinfo`
- **I2P**: HTTP console on port 7657
- **Privateness**: HTTP endpoint on port 8080

### Portainer Webhooks

Set up webhooks for:

- Service restart notifications
- Health check failures
- Resource limit alerts

## Troubleshooting

### Common Issues

**Services won't start**

- Check host has required capabilities: `NET_ADMIN`, `SYS_MODULE`
- Verify `/dev/net/tun` exists: `ls -l /dev/net/tun`
- Check port conflicts: `netstat -tulpn`

**I2P/Yggdrasil fails**

- Ensure kernel modules loaded: `lsmod | grep tun`
- Check sysctls: `sysctl net.ipv6.conf.all.forwarding`

**Emercoin sync slow**

- Increase volume size
- Check network connectivity
- View logs: Portainer → emercoin-core → Logs

### Portainer Logs

View stack deployment logs:

- **Stacks** → `privateness-network` → **Logs**
- Filter by service
- Download logs for analysis

## Updating Stack

### Via Portainer UI

1. **Stacks** → `privateness-network` → **Editor**
2. Modify YAML
3. **Update the stack**
4. Select **Pull latest images**

### Rolling Updates

Update individual services without downtime:

1. **Containers** → Select service
2. **Recreate** → Enable **Pull latest image**
3. Service restarts with new version

## Integration with Umbrel

Deploy on Umbrel via Portainer:

1. Install Portainer on Umbrel
2. Deploy `portainer-stack.yml`
3. Access via Umbrel dashboard

## Production Recommendations

1. **Enable auto-updates** for security patches
2. **Set resource limits** per service
3. **Configure backups** for volumes
4. **Monitor health checks** via webhooks
5. **Use secrets** for sensitive configs
6. **Enable RBAC** for multi-user access

## Support

- **Portainer Docs**: <https://docs.portainer.io>
- **Privateness Network**: <https://privateness.network>
- **Issues**: GitHub repository
