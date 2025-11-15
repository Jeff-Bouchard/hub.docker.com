# Conteneur combiné pyuheprng + privatenesstools

Conteneur combiné exécutant :
- **pyuheprng** : service d’entropie cryptographique (port 5000)
- **privatenesstools** : utilitaires réseau (port 8888)

## Pourquoi combiné ?

Les deux services sont légers et fonctionnent ensemble :
- `pyuheprng` fournit de l’entropie cryptographique pour toutes les opérations
- `privatenesstools` utilise cette entropie pour des opérations réseau sécurisées
- Réduit la surcharge de conteneurs sur les appareils à ressources limitées (Pi4, etc.)

## Services

### pyuheprng (Port 5000)
- Alimente `/dev/random` avec RC4OK + matériel + UHEP
- Élimine la privation d’entropie
- Garantit la sécurité cryptographique

### privatenesstools (Port 8888)
- Utilitaires et outils réseau
- Utilise l’entropie sécurisée de pyuheprng
- Gestion du réseau Privateness

## Déploiement

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

Voir `docker-compose.ness.yml` pour la pile Ness minimale.

## Healthcheck

```bash
# Vérifier les deux services
curl http://localhost:5000/health  # pyuheprng
curl http://localhost:8888/health  # privatenesstools

# Vérifier le niveau d’entropie
cat /proc/sys/kernel/random/entropy_avail
```

## Journaux

```bash
# Voir les journaux des deux services
docker logs pyuheprng-privatenesstools

# Voir les journaux individuels (dans le conteneur)
docker exec pyuheprng-privatenesstools tail -f /var/log/supervisor/pyuheprng.out.log
docker exec pyuheprng-privatenesstools tail -f /var/log/supervisor/privatenesstools.out.log
```

## Consommation de ressources

Empreinte minimale :
- **RAM** : ~200 Mo combinés (vs 300 Mo séparés)
- **CPU** : faible (alimentation d’entropie + outils réseau)
- **Disque** : image ~500 Mo

Parfait pour Raspberry Pi 4 et autres appareils à ressources limitées.
