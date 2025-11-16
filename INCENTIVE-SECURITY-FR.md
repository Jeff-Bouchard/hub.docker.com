# Sécurité des incitations – Récompenser des nœuds hostiles

[English](INCENTIVE-SECURITY.md)

## Le paradoxe : payer ses ennemis

**Comment pouvez‑vous récompenser, de façon sûre, des nœuds hostiles qui font tourner votre infrastructure ?**

C’est le problème fondamental des réseaux décentralisés :

- Vous avez besoin de nœuds pour faire tourner votre réseau
- Vous ne pouvez pas faire confiance aux opérateurs de nœuds
- Ils peuvent être activement hostiles
- Mais vous devez malgré tout les payer

**Solution : Équivalence binaire + vérification cryptographique = incitations sans confiance**

## Le problème sans équivalence binaire

### Scénario : opérateur de nœud hostile

```text
Vous : "Fais tourner mon logiciel de nœud, je te paie en crypto"
Opérateur hostile : "Bien sûr !" 
  → Fait tourner un logiciel modifié
  → Vole les données utilisateur
  → Intercepte les transactions
  → Backdoor le réseau
  → Est malgré tout payé

Résultat : vous payez quelqu’un pour attaquer votre réseau
```

**Sans vérification, vous ne pouvez pas savoir s’il exécute un code légitime.**

## La solution : équivalence binaire vérifiable

### Principe de fonctionnement

```text
1. Vous publiez le code source + un manifeste de hash du binaire
   → Signé sur la blockchain (Emercoin)
   → Hash : abc123...

2. L’opérateur hostile veut être payé
   → Doit exécuter exactement le binaire publié
   → Le hash doit correspondre : abc123...

3. Le réseau vérifie avant paiement
   → Vérifie le hash du binaire
   → Si hash ≠ abc123... → PAS DE PAIEMENT
   → Si hash = abc123... → PAIEMENT AUTORISÉ

4. Choix de l’opérateur hostile :
   Option A : exécuter un code modifié → pas de paiement
   Option B : exécuter le code légitime → être payé
   
   → L’incitation économique force un comportement légitime
```

## Preuve cryptographique d’exécution

### Protocole challenge/réponse

```python
class NodeVerification:
    def verify_node_for_payment(self, node_address):
        """
        Vérifie qu’un nœud exécute le binaire légitime avant paiement.
        Fonctionne même si l’opérateur est hostile.
        """
        
        # 1. Récupérer le hash attendu du binaire sur la blockchain
        expected_hash = emercoin.name_show("ness:manifest:skywire:0.6.0")['hash']
        
        # 2. Défier le nœud pour prouver qu’il exécute le binaire légitime
        challenge = os.urandom(32)  # Challenge aléatoire
        
        # 3. Le nœud doit exécuter du code présent uniquement dans le binaire légitime
        # Cela requiert l’accès à des fonctions/données spécifiques du binaire
        response = node.execute_challenge(challenge)
        
        # 4. Vérifier la réponse
        # Seul le binaire légitime peut produire la réponse correcte
        expected_response = self.calculate_expected_response(challenge, expected_hash)
        
        if response != expected_response:
            print(f"Node {node_address} failed verification - PAYMENT DENIED")
            return False
        
        # 5. Vérification supplémentaire : hash du binaire
        node_binary_hash = node.get_binary_hash()
        if node_binary_hash != expected_hash:
            print(f"Node {node_address} binary hash mismatch - PAYMENT DENIED")
            return False
        
        # 6. Nœud vérifié – autoriser le paiement
        print(f"Node {node_address} verified - PAYMENT AUTHORIZED")
        return True
```

### Preuve d’exécution

```python
def proof_of_execution(node):
    """
    Prouve qu’un nœud a exécuté un code spécifique du binaire légitime.
    Ne peut pas être simulé sans exécuter réellement le binaire.
    """
    
    # Challenge : exécuter une fonction spécifique avec une entrée aléatoire
    random_input = os.urandom(32)
    
    # Cette fonction existe uniquement dans le binaire légitime
    # Les binaires modifiés ne l’ont pas ou ont une implémentation différente
    result = node.execute_internal_function("crypto_verify_internal", random_input)
    
    # Vérifier que le résultat correspond à celui du binaire légitime
    expected = legitimate_binary.crypto_verify_internal(random_input)
    
    return result == expected
```

## Smarter contract de paiement

### Vérification basée sur Emercoin

```python
class IncentiveContract:
    """
    Smarter contract de paiement des nœuds.
    Ne paie que si la vérification du binaire réussit.
    """
    
    def __init__(self, emercoin_rpc):
        self.emc = emercoin_rpc
        self.payment_pool = {}
    
    def register_node(self, node_address, node_pubkey):
        """Enregistrement d’un nœud pour recevoir des paiements."""
        # Vérifier que le nœud exécute le binaire légitime
        if not self.verify_node_binary(node_address):
            raise Exception("Binary verification failed - registration denied")
        
        self.payment_pool[node_address] = {
            'pubkey': node_pubkey,
            'verified': True,
            'last_verification': time.time(),
            'total_earned': 0
        }
    
    def verify_node_binary(self, node_address):
        """Vérifie le binaire du nœud avant tout paiement."""
        # Récupérer le hash du binaire du nœud
        node_hash = self.get_node_binary_hash(node_address)
        
        # Récupérer le hash attendu sur la blockchain
        expected_hash = self.emc.name_show("ness:manifest:current")['hash']
        
        # Vérifier la signature
        signature = self.emc.name_show("ness:manifest:current")['signature']
        if not self.emc.verifymessage(expected_hash, signature):
            return False
        
        # Comparer les hashes
        return node_hash == expected_hash
    
    def process_payment(self, node_address, amount):
        """
        Paiement du nœud pour son travail.
        UNIQUEMENT si la vérification binaire réussit.
        """
        # Re‑vérifier avant chaque paiement
        if not self.verify_node_binary(node_address):
            print(f"Payment DENIED: Node {node_address} failed verification")
            return False
        
        # Vérifier que le nœud a réellement effectué le travail (preuve d’exécution)
        if not self.verify_work_done(node_address):
            print(f"Payment DENIED: Node {node_address} didn't do work")
            return False
        
        # Les deux vérifications ont réussi – autoriser le paiement
        self.emc.sendtoaddress(node_address, amount)
        self.payment_pool[node_address]['total_earned'] += amount
        
        print(f"Payment AUTHORIZED: {amount} EMC to {node_address}")
        return True
    
    def verify_work_done(self, node_address):
        """
        Vérifie que le nœud a réellement effectué le travail.
        Utilise des challenges de preuve d’exécution.
        """
        # Envoyer un challenge aléatoire
        challenge = os.urandom(32)
        response = self.send_challenge(node_address, challenge)
        
        # Vérifier que la réponse prouve l’exécution du code légitime
        return self.verify_challenge_response(challenge, response)
```

## Théorie des jeux et modèle économique

### Dilemme de l’opérateur hostile

```text
Scénario : l’opérateur veut attaquer le réseau ET être payé

Option 1 : exécuter du code modifié (malveillant)
  - Peut attaquer le réseau ✓
  - Hash du binaire ne correspond pas ✗
  - Échoue à la vérification ✗
  - PAS DE PAIEMENT ✗
  - Résultat : l’attaque réussit peut‑être, mais aucun revenu

Option 2 : exécuter le code légitime
  - Ne peut pas attaquer le réseau ✗
  - Hash du binaire correspond ✓
  - Vérification réussie ✓
  - REÇOIT LE PAIEMENT ✓
  - Résultat : pas d’attaque mais revenu assuré

Incitation économique : l’option 2 est plus profitable.
```

### Équilibre de Nash

```text
Tous les opérateurs (même hostiles) convergent vers l’exécution du code légitime
parce que c’est la seule manière d’être payés.

Stratégie optimale pour un opérateur hostile :
1. Exécuter le binaire légitime (pour être payé)
2. Tenter de trouver des failles dans le code légitime
3. Rapporter les failles contre une prime de bug bounty (paiement supplémentaire)

Résultat : même les acteurs hostiles contribuent à la sécurité du réseau.
```

## Exemple Skywire

### Incitations dans le mesh

```python
class SkywireIncentive:
    """
    Payer les nœuds Skywire pour le routage de trafic.
    Fonctionne même si les opérateurs de nœuds sont hostiles.
    """
    
    def pay_for_routing(self, node_id, bytes_routed):
        """Paie un nœud pour le trafic routé dans le mesh."""
        
        # 1. Vérifier que le nœud exécute le binaire Skywire légitime
        node_hash = self.get_node_binary_hash(node_id)
        expected_hash = self.get_manifest_hash("skywire")
        
        if node_hash != expected_hash:
            print(f"Node {node_id} running modified binary - NO PAYMENT")
            return False
        
        # 2. Vérifier que le nœud a effectivement routé le trafic (preuve de travail)
        if not self.verify_routing_proof(node_id, bytes_routed):
            print(f"Node {node_id} didn't route traffic - NO PAYMENT")
            return False
        
        # 3. Calculer le paiement en fonction du travail effectué
        payment = bytes_routed * PAYMENT_PER_BYTE
        
        # 4. Envoyer le paiement
        self.send_payment(node_id, payment)
        
        print(f"Paid {payment} to node {node_id} for routing {bytes_routed} bytes")
        return True
    
    def verify_routing_proof(self, node_id, bytes_routed):
        """
        Vérifie que le nœud a réellement routé du trafic.
        Utilise des preuves cryptographiques infaussables.
        """
        # Récupérer la preuve de routage du nœud
        proof = self.get_routing_proof(node_id)
        
        # Vérifier la preuve cryptographiquement
        # La preuve inclut des signatures des nœuds source et destination
        if not self.verify_signatures(proof):
            return False
        
        # Vérifier que le nombre d’octets correspond
        if proof['bytes'] != bytes_routed:
            return False
        
        return True
```

## Exemple d’entropie RC4OK Emercoin

### Paiement pour la génération d’entropie

```python
class EntropyIncentive:
    """
    Payer les nœuds qui contribuent de l’entropie au réseau.
    Même des nœuds hostiles doivent fournir une entropie légitime pour être payés.
    """
    
    def pay_for_entropy(self, node_id, entropy_bytes):
        """Paie un nœud pour l’entropie fournie."""
        
        # 1. Vérifier que le nœud exécute le binaire pyuheprng légitime
        if not self.verify_binary(node_id, "pyuheprng"):
            return False
        
        # 2. Vérifier la qualité de l’entropie
        # Doit provenir de RC4OK (blockchain Emercoin) + matériel + UHEP
        if not self.verify_entropy_sources(node_id, entropy_bytes):
            print(f"Node {node_id} entropy failed quality check - NO PAYMENT")
            return False
        
        # 3. Vérifier que l’entropie a réellement été utilisée par le réseau
        if not self.verify_entropy_consumption(entropy_bytes):
            print(f"Node {node_id} entropy not consumed - NO PAYMENT")
            return False
        
        # 4. Payer pour l’entropie de haute qualité
        payment = len(entropy_bytes) * PAYMENT_PER_ENTROPY_BYTE
        self.send_payment(node_id, payment)
        
        return True
    
    def verify_entropy_sources(self, node_id, entropy_bytes):
        """
        Vérifie que l’entropie provient de sources légitimes.
        La signature RC4OK prouve qu’elle provient de la blockchain Emercoin.
        """
        # Extraire la composante RC4OK
        rc4ok_component = entropy_bytes[:32]
        
        # Vérifier la signature RC4OK
        # Prouve que l’entropie inclut de l’aléa blockchain
        if not self.verify_rc4ok_signature(rc4ok_component):
            return False
        
        # Vérifier la présence d’un composant matériel
        # Prouve que l’entropie inclut un RNG matériel
        if not self.verify_hardware_component(entropy_bytes):
            return False
        
        return True
```

## Résistance aux attaques

### Attaque : exécuter un binaire modifié

```text
Attaquant : modifie le binaire pour voler des données
Réseau : le hash du binaire ne correspond pas
Résultat : nœud rejeté, pas de paiement, attaque échoue
```

### Attaque : falsifier le hash du binaire

```text
Attaquant : annonce un faux hash correspondant au hash attendu
Réseau : envoie un challenge de type challenge/réponse
Attaquant : ne peut pas répondre correctement (ne possède pas le code légitime)
Résultat : challenge échoue, pas de paiement, attaque échoue
```

### Attaque : exécuter le binaire légitime + un outil d’attaque séparé

```text
Attaquant : exécute le binaire légitime pour être payé
         + exécute un outil séparé pour attaquer le réseau
Réseau : surveille l’ensemble des processus, détecte le code non autorisé
Résultat : nœud banni, paiements stoppés, attaque détectée
```

### Attaque : relecture (replay)

```text
Attaquant : enregistre les réponses d’un nœud légitime
         + rejoue ces réponses pour simuler une vérification valide
Réseau : utilise des challenges aléatoires (nouveau challenge à chaque fois)
Attaquant : les réponses rejouées ne correspondent pas au nouveau challenge
Résultat : vérification échoue, pas de paiement
```

## Checklist d’implémentation

Pour chaque service incentivé :

- [ ] **Manifeste de hash binaire** publié sur la blockchain
- [ ] **Vérification de signature** avant tout paiement
- [ ] **Protocole challenge/réponse** pour prouver l’exécution
- [ ] **Vérification de preuve de travail** pour valider le travail effectué
- [ ] **Re‑vérification continue** (pas seulement une fois)
- [ ] **Smarter contract de paiement** avec logique de vérification
- [ ] **Analyse d’incitation économique** (paiement > valeur de l’attaque)
- [ ] **Tests d’attaque** (essayer de casser le système)

## Modèle de sécurité économique

### Calcul de paiement

```python
def calculate_secure_payment(work_done, attack_value):
    """
    Calculer un paiement qui incite au comportement légitime.
    
    Le paiement doit être > au profit potentiel d’une attaque,
    sinon les nœuds hostiles auront intérêt à attaquer.
    """
    
    # Paiement minimal pour inciter au comportement honnête
    min_payment = attack_value * 1.5  # prime de 50 % par rapport à la valeur de l’attaque
    
    # Paiement basé sur le travail effectué
    work_payment = work_done * PAYMENT_RATE
    
    # Utiliser le plus élevé des deux
    return max(min_payment, work_payment)
```

### Exemple : routage Skywire

```text
Valeur de l’attaque : 10 $ (vol de données sur 1 Go routé)
Paiement légitime : 15 $ (pour le routage de 1 Go)

Choix de l’opérateur hostile :
- Attaquer : gagner 10 $, être banni, perdre les revenus futurs
- Se comporter honnêtement : gagner 15 $, rester dans le réseau, revenu continu

Choix rationnel : comportement légitime (plus rentable)
```

## Pourquoi cela fonctionne

### 1. **Vérification cryptographique**

- Le hash du binaire prouve l’identité du code
- Le challenge/réponse prouve l’exécution
- Impossible à simuler sans exécuter le binaire légitime

### 2. **Incitations économiques**

- Paiement > valeur de l’attaque
- Revenu continu > gain unique d’une attaque
- La réputation impacte les paiements futurs

### 3. **Système sans confiance**

- Aucune confiance requise dans les opérateurs de nœuds
- Les mathématiques et la crypto imposent le comportement
- Même des nœuds hostiles contribuent de manière légitime

### 4. **Auto‑exécution**

- Le réseau vérifie automatiquement
- Aucun besoin d’intervention manuelle
- Passe à l’échelle jusqu’à des millions de nœuds

## Application réelle

### Structure d’incitations du réseau Privateness

```text
Service : routage mesh Skywire
Paiement : 0.001 EMC par Go routé
Vérification : hash binaire + preuve de routage
Valeur d’attaque : ~0.0005 EMC (vol de données)
Résultat : le routage légitime est plus rentable

Service : entropie pyuheprng
Paiement : 0.01 EMC par Mo d’entropie
Vérification : hash binaire + signature RC4OK
Valeur d’attaque : ~0.005 EMC (entropie faible)
Résultat : fournir une entropie légitime est plus rentable

Service : routage garlic I2P
Paiement : 0.002 EMC par tunnel‑heure
Vérification : hash binaire + preuve de tunnel
Valeur d’attaque : ~0.001 EMC (analyse de trafic)
Résultat : le routage légitime est plus rentable
```

## Conclusion

**Équivalence binaire + vérification cryptographique = capacité de récompenser de façon sûre des nœuds hostiles**

Cela résout le problème fondamental des réseaux décentralisés :

- ✅ Pas besoin de faire confiance aux opérateurs de nœuds
- ✅ Possibilité de vérifier qu’ils exécutent le bon binaire
- ✅ Possibilité de les payer pour le travail sans prendre de risques
- ✅ Les incitations économiques sont alignées avec la sécurité du réseau
- ✅ Même les acteurs hostiles contribuent de manière légitime

**C’est ainsi que l’on construit un réseau véritablement décentralisé qui fonctionne même lorsque tout le monde essaie de l’attaquer.**

Le réseau se moque de savoir si vous êtes hostile – il ne regarde que si vous exécutez le bon binaire et si vous faites le travail. Si oui, vous êtes payé. Sinon, vous ne l’êtes pas.

**Incitations sans confiance, à grande échelle.** 🔒💰
