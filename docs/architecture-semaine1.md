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