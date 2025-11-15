# Guide de déploiement Portainer

Déployer et gérer toute la pile Privateness Network via Portainer.

## Prérequis

1. **Portainer installé** (Community ou Business Edition)
2. **Docker Engine** avec support du mode privilégié
3. **Exigences hôte** :
   - Périphérique `/dev/net/tun` disponible
   - Modules noyau : `tun`, `amneziawg` (optionnel)
   - Ports disponibles : 53, 3000, 4444, 5000, 6661-6662, 6668, 7657, 8000-8001, 8053, 8080, 8775, 8888, 9001-9002, 51820-51821

## Méthodes de déploiement

### Méthode 1 : Interface Portainer (recommandée)

1. **Connexion à Portainer** → Aller dans **Stacks**
2. Cliquer sur **Add Stack**
3. **Nom** : `privateness-network`
4. **Build method** : Upload
5. Uploader `portainer-stack.yml`
6. Cliquer sur **Deploy the stack**

### Méthode 2 : API Portainer

```bash
curl -X POST "http://localhost:9000/api/stacks" \
  -H "X-API-Key: YOUR_API_KEY" \
  -F "Name=privateness-network" \
  -F "StackFileContent=@portainer-stack.yml" \
  -F "Env=[{\"name\":\"STACK_ENV\",\"value\":\"production\"}]"
```

### Méthode 3 : Dépôt Git

1. **Stacks** → **Add Stack**
2. **Build method** : Repository
3. **Repository URL** : `https://github.com/ness-network/docker-hub`
4. **Compose path** : `portainer-stack.yml`
5. **Deploy**

## Variantes de stack

### Stack complète (`portainer-stack.yml`)

Les 11 services – pile OSI décentralisée complète.

- **RAM** : ~4 Go minimum
- **CPU** : 4+ cœurs recommandés
- **Disque** : 50+ Go pour les données blockchain

### Stack minimale (`portainer-stack-minimal.yml`)

Services cœur uniquement (Emercoin + Yggdrasil + Privateness).

- **RAM** : ~1 Go minimum
- **CPU** : 2+ cœurs
- **Disque** : 20+ Go

## Fonctionnalités Portainer

### Gestion des services

- **Start/Stop/Restart** des services individuels
- **Visualisation des logs** en temps réel
- **Inspection** détaillée des conteneurs
- **Exécution de commandes** via terminal Web

### Supervision des ressources

- Utilisation CPU/mémoire par service
- Statistiques de trafic réseau
- Suivi de l’utilisation des volumes

### Labels de stack

Tous les services sont labellisés :

```yaml
labels:
  - "io.portainer.accesscontrol.teams=privateness"
  - "com.privateness.service=<service-name>"
  - "com.privateness.layer=<osi-layer>"
```

Filtrage par couche :

- `foundation` – Blockchain (Emercoin)
- `network` – Mesh/Anonymat (Yggdrasil, I2P)
- `transport` – VPN/Routage (AmneziaWG, Skywire)
- `application` – Services (Privateness, DNS, RNG, etc.)

## Variables d’environnement

Configuration via l’UI Portainer ou le fichier de stack :

```yaml
environment:
  - EMERCOIN_VERSION=0.8.5
  - I2P_VERSION=2.4.0
  - STACK_ENV=production
```

## Gestion des volumes

Tous les volumes sont labellisés pour une identification facile :

- `emercoin-data` – données blockchain
- `yggdrasil-data` – configuration mesh
- `i2p-data` – données routeur I2P
- `skywire-data` – données nœud Skywire
- `awg-config` – configuration AmneziaWG

### Sauvegarde des volumes

```bash
# Via l’UI Portainer : Volumes → Sélection → Download backup
# Ou via CLI :
docker run --rm -v emercoin-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/emercoin-backup.tar.gz /data
```

## Contrôle d’accès

### Accès basé sur les équipes

1. **Settings** → **Teams** → Créer l’équipe `privateness`
2. Assigner les utilisateurs à l’équipe
3. Les services sont automatiquement restreints aux membres de l’équipe (via labels)

### Permissions basées sur les rôles

- **Admin** : contrôle complet de la stack
- **Operator** : démarrage/arrêt des services, consultation des logs
- **Read-only** : consultation de l’état uniquement

## Supervision de la santé

### Healthchecks de services

- **Emercoin** : `emercoin-cli getinfo`
- **I2P** : console HTTP sur le port 7657
- **Privateness** : endpoint HTTP sur le port 8080

### Webhooks Portainer

Configurer des webhooks pour :

- Notifications de redémarrage de service
- Échecs de healthcheck
- Alertes de dépassement de ressources

## Dépannage

### Problèmes fréquents

**Les services ne démarrent pas**

- Vérifier que l’hôte possède les capacités requises : `NET_ADMIN`, `SYS_MODULE`
- Vérifier l’existence de `/dev/net/tun` : `ls -l /dev/net/tun`
- Vérifier les conflits de ports : `netstat -tulpn`

**I2P/Yggdrasil échoue**

- Vérifier les modules noyau : `lsmod | grep tun`
- Vérifier les sysctls : `sysctl net.ipv6.conf.all.forwarding`

**Synchronisation Emercoin lente**

- Augmenter la taille du volume
- Vérifier la connectivité réseau
- Voir les logs : Portainer → emercoin-core → Logs

### Logs Portainer

Afficher les logs de déploiement de la stack :

- **Stacks** → `privateness-network` → **Logs**
- Filtrer par service
- Télécharger les logs pour analyse

## Mise à jour de la stack

### Via l’interface Portainer

1. **Stacks** → `privateness-network` → **Editor**
2. Modifier le YAML
3. Cliquer sur **Update the stack**
4. Cocher **Pull latest images**

### Mises à jour progressives

Mettre à jour des services individuels sans interruption :

1. **Containers** → sélectionner le service
2. **Recreate** → Activer **Pull latest image**
3. Le service redémarre avec la nouvelle version

## Intégration avec Umbrel

Déploiement sur Umbrel via Portainer :

1. Installer Portainer sur Umbrel
2. Déployer `portainer-stack.yml`
3. Accéder via le dashboard Umbrel

## Recommandations production

1. **Activer les mises à jour automatiques** pour les correctifs de sécurité
2. **Définir des limites de ressources** par service
3. **Configurer des sauvegardes** pour les volumes
4. **Surveiller les healthchecks** via webhooks
5. **Utiliser des secrets** pour les configs sensibles
6. **Activer le RBAC** pour les accès multi‑utilisateurs

## Support

- **Docs Portainer** : <https://docs.portainer.io>
- **Privateness Network** : <https://privateness.network>
- **Issues** : dépôt GitHub
