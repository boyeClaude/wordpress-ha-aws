## Phase 1 - VPC
- Nom : TheCloudPastor-VPC
- CIDR : 10.0.0.0/16
- DNS Hostnames : activé
- DNS Resolution : activé

les options DNS Hostnames et DNS Resolution sont activées pour permettre aux services de se reconnaître par leur nom plutôt que par leur IP.

## Subnets
| Subnet | CIDR | AZ | Type |
|---|---|---|---|
| Public-Subnet-1 | 10.0.1.0/24 | ca-central-1a | Public |
| Public-Subnet-2 | 10.0.2.0/24 | ca-central-1b | Public |
| Private-Subnet-1 | 10.0.3.0/24 | ca-central-1a | Privé |
| Private-Subnet-2 | 10.0.4.0/24 | ca-central-1b | Privé |

Note : Auto-assign public IPv4 activé sur les subnets publics uniquement.

## Connectivité
- Internet Gateway : TheCloudPastor-IGW (attachée à TheCloudPastor-VPC)

## Route Tables

### Public-RT
- Associée à : Public-Subnet-1, Public-Subnet-2
- Routes :
  - 10.0.0.0/16 → local (communication interne VPC)
  - 0.0.0.0/0 → TheCloudPastor-IGW (accès Internet entrant/sortant)

### Private-RT
- Associée à : Private-Subnet-1, Private-Subnet-2
- Routes :
  - 10.0.0.0/16 → local (communication interne VPC)
  - 0.0.0.0/0 → TheCloudPastor-NAT (à ajouter après création NAT Gateway)

## NAT Gateway
- Nom : TheCloudPastor-NAT
- Subnet : Public-Subnet-1 (doit être dans le public pour accéder à l'IGW)
- Elastic IP : allouée automatiquement
- Rôle : permet aux instances privées de sortir vers Internet 
  (mises à jour, téléchargement WordPress) sans être accessibles depuis l'extérieur
- 0.0.0.0/0 → TheCloudPastor-NAT (sortie Internet pour instances privées)

- Mode : Regional (couvre automatiquement toutes les AZs)
- Note : le mode Zonal aurait nécessité de spécifier Public-Subnet-1 
  explicitement, mais Regional offre une meilleure résilience Multi-AZ




## Phase 2 - Security Groups

| Nom | Port | Source | Rôle |
|---|---|---|---|
| WP-ALB-SG | 80 (HTTP) | 0.0.0.0/0 | Reçoit le trafic public |
| WP-Web-SG | 80 (HTTP) | WP-ALB-SG | Reçoit uniquement du Load Balancer |
| WP-DB-SG | 3306 (MySQL) | WP-Web-SG | Reçoit uniquement des serveurs WordPress |

Note : chaînage des Security Groups = défense en profondeur.
Aucune ressource n'est exposée directement à Internet sauf l'ALB.


## Phase 3 - RDS & Secrets Manager

### Secrets Manager
- Nom : WP-DB-Secret
- Clés : username, password, dbname
- Rôle : coffre-fort centralisé des identifiants, 
  lu dynamiquement par le script User Data au démarrage EC2

### RDS
- Moteur : MySQL
- Template : Free Tier (Single-AZ)
- Note : architecture cible = Multi-AZ, contrainte Free Tier impose Single-AZ
- Subnet Group : wp-db-subnetgroup (subnets privés uniquement)
- Public Access : Non
- Security Group : WP-DB-SG


### IAM Role
- Nom : WP-EC2-Role
- Trusted entity : EC2
- Politique : SecretsManagerReadWrite
- Rôle : permet aux instances EC2 de lire WP-DB-Secret 
  sans access keys dans le code
- Session duration : 1 heure (credentials temporaires auto-renouvelés)

- Endpoint : wordpressdb.c2h0e8iuorj8.us-east-1.rds.amazonaws.com
- Port : 3306
- AZ : us-east-1b

wordpressdb.c2h0e8iuorj8.us-east-1.rds.amazonaws.com

DNS name : WP-ALB-734151959.us-east-1.elb.amazonaws.com


## Phase 4 - EC2, ALB & Auto Scaling

### Launch Template
- Nom : WP-Launch-Template
- AMI : Amazon Linux 2023
- Instance type : t3.micro
- Security Group : WP-Web-SG
- IAM Profile : WP-EC2-Role
- User Data : installe Apache/PHP/WordPress au démarrage,
  récupère les credentials via Secrets Manager

### Application Load Balancer
- Nom : WP-ALB
- Scheme : Internet-facing
- Subnets : Public-Subnet-1, Public-Subnet-2
- Security Group : WP-ALB-SG
- DNS : WP-ALB-734151959.us-east-1.elb.amazonaws.com

### Auto Scaling Group
- Nom : WP-ASG
- Subnets : Private-Subnet-1, Private-Subnet-2
- Target Group : WP-Target-Group
- Health Check : ELB (grace period 300s)
- Desired: 2 | Min: 2 | Max: 4

### Correction Launch Template v2
- Problème : Apache installé mais non démarré au lancement
- Cause : commandes systemctl manquantes dans User Data
- Fix : ajout de systemctl enable httpd && systemctl start httpd
- Leçon : toujours démarrer et activer les services après installation


## Phase 5 - Test de Résilience

### Chaos Test
- Action : terminaison manuelle de i-03b791f0c1ed5b72f (us-east-1a)
- Observation 1 : site WordPress resté accessible via l'instance us-east-1b
- Observation 2 : ASG a automatiquement lancé une nouvelle instance 
  pour maintenir Desired capacity = 2
- Résultat : zéro interruption de service

### Conclusion
L'architecture haute disponibilité fonctionne comme conçue.
Aucun Single Point of Failure détecté.