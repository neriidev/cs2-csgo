# Docker Compose na AWS

Os arquivos `docker-compose-painel.yml` e `docker-compose-wings.yml` **funcionam na AWS** (EC2 com Linux), sem alteração. Este documento descreve os **overrides opcionais** para uso em produção na AWS.

## Resumo

| Cenário | Comando |
|--------|--------|
| EC2 padrão (igual ao local) | `docker compose -f docker-compose-painel.yml up -d` |
| EC2 com volumes nomeados (persistência EBS) | `docker compose -f docker-compose-painel.yml -f docker-compose-painel.aws.yml up -d` |
| EC2 atrás de ALB (SSL no ALB) | `docker compose -f docker-compose-painel.yml -f docker-compose-painel.aws-alb.yml up -d` |
| EC2 + volumes nomeados + ALB | `docker compose -f docker-compose-painel.yml -f docker-compose-painel.aws.yml -f docker-compose-painel.aws-alb.yml up -d` |
| Wings (Linux/EC2) | `docker compose -f docker-compose-wings.yml up -d` |

## Arquivos para AWS

- **docker-compose-painel.aws.yml** – Override que usa **volumes nomeados** (`pterodactyl_panel_db`, `pterodactyl_panel_var`) em vez de pastas locais (`./db`, `./var/`). Recomendado na EC2 para facilitar backup e para manter dados no EBS (configure o Docker data root num volume EBS ou faça backup de `/var/lib/docker/volumes/`).

- **docker-compose-painel.aws-alb.yml** – Override que expõe o painel nas portas **8080** e **8443** em vez de 80 e 443. Use quando houver um **Application Load Balancer (ALB)** na frente da EC2: o ALB termina SSL (certificado no ACM) e encaminha para a EC2 na porta 8080. O Security Group da EC2 pode permitir 80/443 apenas para o Security Group do ALB (ou não expor 80/443 na internet).

- **.env.aws.example** – Exemplo de `.env` com comentários para AWS (APP_URL em HTTPS, Security Group, etc.). Na EC2: `cp .env.aws.example .env` e edite.

## Wings na AWS

O **docker-compose-wings.yml** já é compatível com Linux/EC2:

- Usa `network_mode: host` (funciona em Amazon Linux 2 e Ubuntu).
- Monta `/var/run/docker.sock`, `/etc/pterodactyl`, `/var/lib/pterodactyl`, etc.

Antes de subir o Wings na EC2, crie os diretórios no host:

```bash
sudo mkdir -p /var/lib/pterodactyl/volumes /run/wings/machine-id /tmp/pterodactyl
sudo chown -R 988:988 /var/lib/pterodactyl /run/wings/machine-id /tmp/pterodactyl
```

Coloque o `config.yml` do node em `/etc/pterodactyl/` (ou use o `wings-config/` do projeto) e suba:

```bash
docker compose -f docker-compose-wings.yml up -d
```

## Proxy (Nginx Proxy Manager)

Os arquivos **docker-compose-proxy.yml** e **docker-compose-painel.npm.yml** funcionam na AWS como em qualquer Linux. Use se quiser terminar SSL com Let's Encrypt no próprio servidor em vez de ALB + ACM.

## Referências

- [tutorial/02-aws-ec2.md](../tutorial/02-aws-ec2.md) – Passo a passo na EC2.
- [docs/setup/README.md](setup/README.md) – Guia geral (local, EC2, ECS, EKS).
