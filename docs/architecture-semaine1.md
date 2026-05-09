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