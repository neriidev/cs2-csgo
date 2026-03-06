# Tutorial 03 – Configurar na AWS ECS

Este tutorial ensina os **conceitos e passos** para rodar o projeto **cs2-csgo** (Pterodactyl Panel + Wings) na **AWS ECS** (Elastic Container Service), com painel em Fargate ou EC2 e Wings em instâncias EC2 (porque o Wings precisa do Docker daemon).

---

## O que você precisa saber

- **ECS** usa **Clusters**, **Task Definitions**, **Services** e opcionalmente **ALB**.
- O **Wings** precisa de acesso ao **Docker daemon** para criar containers dos servidores de jogo. Em **Fargate** isso **não** é possível. Por isso:
  - **Painel, MariaDB, Redis** → podem ser **Fargate** ou **EC2**.
  - **Wings** → tem de correr em **ECS com launch type EC2** (instâncias no cluster com Docker instalado) ou numa **EC2 separada** com Docker.

---

## Pré-requisitos

- Conta AWS
- AWS CLI configurado (opcional)
- Repositório **ECR** para as imagens (ou use imagens públicas do Docker Hub/GHCR)
- VPC com subnets públicas/privadas conforme a arquitetura

---

## Passo 1 – Criar o cluster ECS

1. **AWS Console** → **ECS** → **Clusters** → **Create cluster**.
2. **Cluster name:** ex. `pterodactyl-cluster`.
3. **Infrastructure:** 
   - Para Fargate apenas (só painel/DB/Redis): escolha **AWS Fargate**.
   - Para incluir o Wings no mesmo cluster: adicione **EC2** (provisionar instâncias com Docker e registá-las no cluster).
4. Se usar EC2: crie ou use um **Launch Template** com Docker instalado e **User Data** que registe a instância no cluster ECS (AMI com ECS agent, ou script de bootstrap).

---

## Passo 2 – Repositório ECR e imagens

Crie um repositório ECR para o painel (e outro para o Wings se usar imagem customizada):

```bash
aws ecr create-repository --repository-name pterodactyl-panel --region sa-east-1
```

Na máquina onde você tem o projeto (com Docker):

```bash
# Login no ECR (substitua account-id e region)
aws ecr get-login-password --region sa-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.sa-east-1.amazonaws.com

# Build e push do painel
cd cs2-csgo
docker build -t pterodactyl-panel ./panel
docker tag pterodactyl-panel:latest <account-id>.dkr.ecr.sa-east-1.amazonaws.com/pterodactyl-panel:latest
docker push <account-id>.dkr.ecr.sa-east-1.amazonaws.com/pterodactyl-panel:latest
```

Para o Wings pode usar a imagem oficial: `ghcr.io/pterodactyl/wings:latest` (ou a do Docker Hub equivalente). Se precisar de customizações, crie outro repositório ECR e faça build/push.

---

## Passo 3 – Task Definition – Painel

1. **ECS** → **Task Definitions** → **Create new Task Definition**.
2. **Family:** ex. `pterodactyl-panel`.
3. **Launch type:** Fargate (ou EC2).
4. **Task size:** ex. 0.5 vCPU, 1 GB memory (ajuste conforme necessidade).
5. **Container – Add container:**
   - **Name:** `panel`
   - **Image:** URI do ECR (ex.: `<account-id>.dkr.ecr.sa-east-1.amazonaws.com/pterodactyl-panel:latest`)
   - **Port mappings:** 80 (e 443 se terminar SSL no container).
   - **Environment variables:**  
     `APP_URL`, `APP_SERVICE_AUTHOR`, `DB_HOST` (nome do serviço ECS do MariaDB ou endpoint RDS), `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`, `REDIS_HOST`, `CACHE_DRIVER`, `SESSION_DRIVER`, `QUEUE_CONNECTION`.
   - **Secrets:** pode usar **Secrets Manager** ou **SSM Parameter Store** para senhas (DB_PASSWORD, etc.).
   - **Log configuration:** CloudWatch Logs (log group criado previamente).
6. **Storage:** se o painel precisar de volume persistente (uploads, storage), adicione um volume e monte no container (Fargate suporta volumes efémeros ou EFS).

Crie a Task Definition.

---

## Passo 4 – Task Definitions – MariaDB e Redis

- **Opção recomendada em produção:** use **RDS (MariaDB/MySQL)** e **ElastiCache (Redis)** e configure apenas as variáveis de ambiente no painel (`DB_HOST` = endpoint RDS, `REDIS_HOST` = endpoint ElastiCache).
- **Opção em containers:** crie Task Definitions para MariaDB e Redis (imagens `mariadb:10.5`, `redis:alpine`) com **volumes** (EFS ou volumes do host em EC2) para persistência. Exponha-os como **Services** ECS internos (ClusterIP) na mesma VPC.

---

## Passo 5 – Task Definition – Wings

1. **Create new Task Definition** – family ex. `pterodactyl-wings`.
2. **Launch type:** **EC2** (obrigatório).
3. **Container – Add container:**
   - **Name:** `wings`
   - **Image:** `ghcr.io/pterodactyl/wings:latest` (ou a sua imagem ECR).
   - **Port mappings:** 8080 (API), 2022 (SFTP), e as portas dos jogos (ex.: 27015–27020) em **host** ou **bridge** conforme a rede.
   - **Environment / Secrets:** configurar o token do painel (ex.: variáveis ou ficheiro montado de Secrets Manager).
   - **Volumes:** montar o **socket do Docker** do host (`/var/run/docker.sock`) no container e, se necessário, diretórios como `/var/lib/pterodactyl/volumes` e `/tmp/pterodactyl` (com volumes do host ou EFS).
   - **Privileged:** pode ser necessário marcar o container como **privileged** para o Wings conseguir criar outros containers.
   - **User:** o Wings espera um UID específico (ex.: 988); ajuste se a imagem definir outro.

A configuração exata (network mode, port mappings para jogos) depende de como você expõe as portas dos servidores (host network vs bridge + ALB/NLB). Em muitos setups, o Wings corre com **network mode = host** nas instâncias EC2 para as portas de jogo ficarem diretamente no host.

---

## Passo 6 – Services ECS

1. **Painel:** crie um **Service** no cluster, usando a Task Definition do painel. **Desired count:** 1. Se quiser acesso pela internet, crie um **Application Load Balancer (ALB)** e um **Target Group** (porta 80) e associe ao Service. O ALB pode terminar SSL (certificado no ACM).
2. **Wings:** crie um **Service** com a Task Definition do Wings, **launch type EC2**, e garanta que as tarefas são colocadas nas instâncias EC2 que têm Docker (pode usar **placement constraints** ou um **capacity provider** dedicado). Exponha a porta 8080 (e portas de jogo) via Security Group nas instâncias EC2 ou via NLB/ALB conforme o desenho.

---

## Passo 7 – Rede e Security Groups

- **Painel:** Security Group que permite 80/443 do ALB (ou 0.0.0.0/0 para teste). O painel precisa conseguir falar com o **DB** (RDS ou serviço ECS) e **Redis** (ElastiCache ou serviço ECS) na VPC.
- **Wings:** Security Group que permite 8080 do painel (ou do ALB), 2022 (SFTP) e as portas dos jogos (ex.: 27015) dos IPs dos jogadores. As instâncias EC2 do Wings precisam de conseguir falar com o painel (por URL interna ou pública).

---

## Passo 8 – Configurar o painel para o node Wings

No painel Pterodactyl (após o primeiro acesso e criação da conta admin):

1. **Admin** → **Nodes** → **Create Node**.
2. **FQDN:** DNS ou IP pelo qual o painel e os clientes alcançam o Wings (ex.: nome do serviço interno, IP da tarefa, ou endpoint público/NLB). A porta 8080 deve estar acessível.
3. **Daemon Port:** 8080.
4. Copie o token e configure no Wings (variáveis de ambiente ou ficheiro de config injetado via Secrets/ConfigMap).

---

## Resumo ECS

| Componente | Onde roda | Notas |
|-----------|-----------|--------|
| Painel | Fargate ou EC2 | Atrás de ALB; env para DB e Redis |
| MariaDB / Redis | RDS + ElastiCache (recomendado) ou ECS | Em ECS use volumes persistentes (EFS/host) |
| Wings | **EC2** (no cluster ECS ou EC2 dedicada) | Acesso a Docker daemon; portas 8080, 2022, jogos |

Para um guia mais detalhado e exemplos de YAML (Terraform/CloudFormation), consulte **[docs/setup/README.md](../docs/setup/README.md)** (secção AWS ECS).
