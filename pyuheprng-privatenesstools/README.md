# pyuheprng + privatenesstools Combined Container

[Français](README-FR.md)

Combined container running both:
- **pyuheprng**: Cryptographic entropy service (port 5000)
- **privatenesstools**: Network utilities (port 8888)

## Why Combined?

Both services are lightweight and work together:
- `pyuheprng` provides cryptographic entropy for all operations
- `privatenesstools` uses that entropy for secure network operations
- Reduces container overhead on resource-constrained devices (Pi4, etc.)

## Services

### pyuheprng (Port 5000)
- Feeds `/dev/random` with RC4OK + Hardware + UHEP
- Eliminates entropy deprivation
- Ensures cryptographic security

### privatenesstools (Port 8888)
- Network utilities and tools
- Uses secure entropy from pyuheprng
- Privateness network management

## Deployment

### Docker Run

```bash
docker run -d \
  --name pyuheprng-privatenesstools \
  --privileged \
  --device /dev/random \
  -v /dev:/dev \
  -p 5000:5000 \
  -p 8888:8888 \
  -e EMERCOIN_HOST=emercoin-core \
  -e EMERCOIN_PORT=6662 \
  -e EMERCOIN_USER=rpcuser \
  -e EMERCOIN_PASS=rpcpassword \
  ness-network/pyuheprng-privatenesstools
```

### Docker Compose

See `docker-compose.ness.yml` for the minimal Ness stack.

## Health Check

```bash
# Check both services
curl http://localhost:5000/health  # pyuheprng
curl http://localhost:8888/health  # privatenesstools

# Check entropy levels
cat /proc/sys/kernel/random/entropy_avail
```

## Logs

```bash
# View both service logs
docker logs pyuheprng-privatenesstools

# View individual service logs (inside container)
docker exec pyuheprng-privatenesstools tail -f /var/log/supervisor/pyuheprng.out.log
docker exec pyuheprng-privatenesstools tail -f /var/log/supervisor/privatenesstools.out.log
```

## Resource Usage

Minimal footprint:
- **RAM**: ~200MB combined (vs 300MB separate)
- **CPU**: Low (entropy feeding + network tools)
- **Disk**: ~500MB image

Perfect for Raspberry Pi 4 and other resource-constrained devices.
