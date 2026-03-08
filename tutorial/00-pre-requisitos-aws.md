# Tutorial 00 – Pré-requisitos para rodar na AWS

Este documento lista **tudo o que você precisa** para conseguir rodar o projeto **cs2-csgo** (Painel Pterodactyl + Wings) na AWS, seja em **EC2**, **ECS** ou **EKS**. Use-o antes de seguir os tutoriais [02 – EC2](02-aws-ec2.md), [03 – ECS](03-aws-ecs.md) e [04 – EKS](04-aws-eks.md).

---

## Índice

- [Pré-requisitos comuns a todas as opções](#pré-requisitos-comuns-a-todas-as-opções)
- [Pré-requisitos para EC2](#pré-requisitos-para-ec2)
- [Pré-requisitos para ECS](#pré-requisitos-para-ecs)
- [Pré-requisitos para EKS](#pré-requisitos-para-eks)
- [Resumo rápido por cenário](#resumo-rápido-por-cenário)

---

## Pré-requisitos comuns a todas as opções

### Conta e acesso AWS

| Item | Descrição |
|------|-----------|
| **Conta AWS** | Conta ativa na AWS (Amazon Web Services). Crie em [aws.amazon.com](https://aws.amazon.com). |
| **Credenciais** | Usuário IAM com permissões para criar e gerenciar recursos (EC2, ECS, EKS, VPC, etc.). Para aprender, pode usar um usuário com permissões amplas; em produção restrinja por serviço. |
| **Região** | Escolha uma região (ex.: `sa-east-1` São Paulo). Todos os recursos do tutorial devem estar na mesma região. |

### Conceitos de rede e segurança

- **VPC (Virtual Private Cloud)** – Rede isolada na AWS. Você pode usar a VPC padrão ou criar uma nova.
- **Subnets** – Sub-redes dentro da VPC (públicas com IP público, privadas sem). Para EC2 com IP público use subnets públicas; para ECS/EKS é comum ter públicas e privadas.
- **Security Group** – Firewall por instância/serviço. Define quem pode acessar quais portas (ex.: 22 para SSH, 80/443 para o painel, 8080 para o Wings, 27015 para o jogo).
- **Chave SSH** – Par de chaves (`.pem`) para acessar instâncias EC2 por SSH. Crie ou importe em **EC2 → Key Pairs**.

### Domínio e SSL (opcional, mas recomendado em produção)

- **Domínio** – Para HTTPS profissional (ex.: `painel.seudominio.com`). Pode registrar na Route 53 ou usar um domínio já existente apontando para o recurso AWS (IP da EC2, ALB, etc.).
- **Certificado SSL** – Na AWS use **AWS Certificate Manager (ACM)** para certificados gratuitos. O certificado é usado no ALB (EC2 atrás de ALB, ECS, EKS) para terminar HTTPS.

### Ferramentas no seu PC (opcional)

- **AWS CLI** – Para criar recursos e fazer push de imagens (ECR) a partir do terminal. Instale e configure com `aws configure` ([instalação](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)).
- **Git** – Para clonar o repositório na EC2 ou no seu PC antes de fazer build das imagens.

---

## Pré-requisitos para EC2

Objetivo: rodar painel + Wings em **uma ou mais instâncias Linux** com Docker. É o caminho mais simples para ter tudo na AWS.

### O que você precisa

| Pré-requisito | Detalhes |
|---------------|----------|
| **Conta AWS** | Conforme [comuns](#pré-requisitos-comuns-a-todas-as-opções). |
| **Chave SSH** | EC2 → Key Pairs → Create key pair (ou importar). Você usará essa chave para `ssh -i sua-chave.pem ec2-user@<IP>`. |
| **Security Group** | Ao criar a instância, crie ou escolha um Security Group que permita: **22** (SSH), **80** (HTTP), **443** (HTTPS), **8080** (API do Wings), **2022** (SFTP, opcional), **27015** (e outras portas de jogo para os clientes). Restrinja SSH (22) ao seu IP em produção. |
| **AMI** | **Amazon Linux 2** ou **Ubuntu Server 22.04** (ou outra versão LTS). O tutorial traz comandos para instalar Docker em ambas. |
| **Tipo de instância** | Ex.: **t3.medium** (2 vCPU, 4 GB RAM) para painel + Wings na mesma máquina. Para muitos servidores de jogo, use instâncias maiores ou uma segunda EC2 só para o Wings. |
| **Armazenamento** | Mínimo **30–40 GB** (o CS2 usa ~33 GB por instância de jogo). Para produção, use um volume EBS adicional e monte em `/data` ou configure o Docker para usar esse volume. |
| **Docker e Docker Compose** | Instalados **na própria EC2** após o primeiro login (o tutorial [02 – EC2](02-aws-ec2.md) tem os comandos para Amazon Linux 2 e Ubuntu). |

### Portas que precisam estar abertas (Security Group)

| Porta | Uso |
|-------|-----|
| 22 | SSH (acesso à EC2) – restrinja ao seu IP |
| 80 | HTTP do painel |
| 443 | HTTPS do painel |
| 8080 | API do Wings (painel e clientes falam com o Wings) – pode restringir à VPC ou ao IP do painel |
| 2022 | SFTP do Pterodactyl (opcional) |
| 27015, 27016, … | Portas dos servidores de jogo (CS2, etc.) – para os jogadores conectarem |

### Ordem sugerida

1. Criar Key Pair (se ainda não tiver).
2. Criar Security Group com as regras acima.
3. Lançar a instância EC2 (AMI, tipo, storage, Security Group, Key Pair).
4. Conectar por SSH e instalar Docker + Docker Compose.
5. Clonar o projeto, criar `.env` e seguir o [tutorial 02](02-aws-ec2.md).

---

## Pré-requisitos para ECS

Objetivo: rodar o painel (e opcionalmente DB/Redis) em **Fargate** ou **EC2**, e o **Wings em EC2** (porque o Wings precisa do daemon Docker para criar containers de jogos). ECS não oferece Docker-in-Docker no Fargate.

### O que você precisa

| Pré-requisito | Detalhes |
|---------------|----------|
| **Conta AWS e VPC** | Conforme [comuns](#pré-requisitos-comuns-a-todas-as-opções). VPC com subnets públicas/privadas conforme a arquitetura. |
| **Cluster ECS** | Um cluster ECS (Fargate e/ou EC2). Se for usar Wings no mesmo cluster, o cluster precisa de **capacity provider EC2** (instâncias com Docker). |
| **Repositório ECR** | Para guardar a imagem do painel (build a partir de `./panel`). Crie em ECR → Repositories → Create repository (ex.: `pterodactyl-panel`). O Wings pode usar a imagem pública `ghcr.io/pterodactyl/wings:latest`. |
| **AWS CLI + Docker** | No seu PC ou numa máquina de build: para fazer login no ECR, build da imagem do painel e push. |
| **Application Load Balancer (ALB)** | Para expor o painel na internet com HTTPS (certificado no ACM). Crie o ALB, Target Group (porta 80 ou 8080) e associe ao Service do painel. |
| **RDS + ElastiCache (opcional)** | Em produção é recomendado usar **RDS (MariaDB/MySQL)** e **ElastiCache (Redis)** em vez de containers no ECS. Assim o painel só precisa das variáveis `DB_HOST` e `REDIS_HOST` apontando para esses endpoints. |

### Limitações importantes

- **Wings não roda em Fargate** – O Wings precisa acessar o Docker daemon para criar os containers dos servidores de jogo. No Fargate isso não é possível. Por isso o Wings deve rodar em **ECS com launch type EC2** (instâncias registradas no cluster com Docker instalado) ou numa **EC2 separada** com Docker.
- **Painel, MariaDB, Redis** – Podem ser Fargate ou EC2. Se usar containers no ECS para DB/Redis, precisará de volumes persistentes (EFS ou volumes no host EC2).

### Ordem sugerida

1. Criar repositório ECR para o painel.
2. Build e push da imagem do painel (a partir do projeto).
3. Criar cluster ECS (Fargate e, se for usar Wings no cluster, adicionar node group EC2 com Docker).
4. Criar Task Definitions (painel, Wings em EC2, e opcionalmente MariaDB/Redis ou usar RDS/ElastiCache).
5. Criar ALB + Target Group e Services ECS.
6. Configurar Security Groups (painel acessível pelo ALB; Wings com 8080, 2022 e portas de jogo).
7. Seguir o [tutorial 03](03-aws-ecs.md) para os passos detalhados.

---

## Pré-requisitos para EKS

Objetivo: rodar o stack em **Kubernetes** (EKS) com Deployments, Services, Ingress e, para o Wings, nós com Docker e montagem do socket do daemon.

### O que você precisa

| Pré-requisito | Detalhes |
|---------------|----------|
| **Conta AWS e VPC** | Conforme [comuns](#pré-requisitos-comuns-a-todas-as-opções). O EKS cria recursos na VPC (subnets, Security Groups). |
| **Cluster EKS** | Cluster EKS criado (Console EKS ou Terraform/eksctl). Leva alguns minutos até ficar **Active**. |
| **kubectl** | Instalado e configurado para o cluster: `aws eks update-kubeconfig --region <region> --name <cluster-name>`. |
| **Helm (opcional)** | Para instalar charts (ex.: MariaDB, Redis, Ingress Controller) e organizar o deploy do painel. |
| **ECR** | Para a imagem do painel (build e push como no ECS). |
| **Ingress Controller** | Para expor o painel com HTTPS. Ex.: **AWS Load Balancer Controller** (cria ALB a partir de Ingress) ou NGINX Ingress. O Ingress usa certificado do ACM. |
| **Node group com Docker** | O Wings precisa rodar em **nodes que tenham o Docker daemon** e que permitam montar `/var/run/docker.sock` no Pod. Isso exige um **node group** com AMI/User Data que instale o Docker, ou uso de **Docker-in-Docker (DinD)** com cuidado de segurança. |

### Limitações importantes

- **Wings em nós com Docker** – O Wings cria containers filhos (servidores de jogo). No EKS isso implica: (1) nodes com Docker instalado e socket exposto, (2) Pod do Wings com `privileged: true` (ou capabilities adequadas) e montagem de `hostPath` para `/var/run/docker.sock`, (3) PVC ou hostPath para `/var/lib/pterodactyl/volumes` e `/tmp/pterodactyl`. É comum usar um **node group dedicado** para o Wings com taints/tolerations.

### Ordem sugerida

1. Criar cluster EKS e node groups (um para aplicação, opcionalmente outro para o Wings com Docker).
2. Configurar `kubectl` e criar namespace (ex.: `pterodactyl`).
3. Criar Secrets (senhas do DB, token do Wings).
4. Deploy MariaDB e Redis (Helm ou manifestos YAML) ou usar RDS/ElastiCache fora do cluster.
5. Build e push da imagem do painel para o ECR; deploy do painel (Deployment + Service).
6. Instalar Ingress Controller e criar Ingress para o painel (HTTPS com ACM).
7. Deploy do Wings (Deployment com mount do docker.sock, Service LoadBalancer/NodePort para 8080 e portas de jogo).
8. Seguir o [tutorial 04](04-aws-eks.md) para os detalhes.

---

## Resumo rápido por cenário

| Se você quer… | Pré-requisitos mínimos | Tutorial |
|---------------|------------------------|----------|
| **Subir rápido na AWS com Docker** | Conta AWS, chave SSH, Security Group (22, 80, 443, 8080, 27015), EC2 Linux, Docker + Compose na EC2 | [02 – EC2](02-aws-ec2.md) |
| **Painel em Fargate, Wings em EC2** | Conta AWS, ECR, ECS cluster (Fargate + EC2), ALB, Task Definitions, Security Groups | [03 – ECS](03-aws-ecs.md) |
| **Tudo em Kubernetes (EKS)** | Conta AWS, cluster EKS, kubectl, ECR, Ingress Controller, node group com Docker para o Wings | [04 – EKS](04-aws-eks.md) |

### Checklist geral antes de começar

- [ ] Conta AWS ativa e região escolhida
- [ ] Conceito básico de VPC, Security Group e (para ECS/EKS) ALB/Ingress
- [ ] Para EC2: Key Pair e Security Group com as portas necessárias
- [ ] Para ECS/EKS: repositório ECR e Docker no PC (ou CI) para build/push da imagem do painel
- [ ] (Opcional) Domínio e certificado ACM para HTTPS
- [ ] (Opcional) AWS CLI configurado

Depois de cumprir os pré-requisitos do seu cenário, siga o tutorial correspondente (02, 03 ou 04) e, para uso dos arquivos Docker Compose na EC2, consulte também **[docs/aws-docker-compose.md](../docs/aws-docker-compose.md)**.
