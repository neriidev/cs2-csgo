# Tutorial 02 – Configurar na AWS EC2

Este tutorial ensina a **clonar** o projeto **cs2-csgo** e rodá-lo em **uma ou duas instâncias Amazon EC2** (Linux) com Docker, para ter o painel Pterodactyl e o Wings na AWS.

---

## O que você vai ter no final

- Painel acessível pela URL pública (IP da EC2 ou domínio)
- Wings a correr na mesma instância ou em outra EC2
- Servidores de jogo (ex.: CS2) criados pelo painel e acessíveis pela rede

---

## Pré-requisitos

- Conta **AWS**
- Conhecimento básico de **VPC**, **Security Groups** e **chave SSH**
- (Opcional) Domínio e certificado SSL para HTTPS

Para uma lista completa do que preparar (portas, Security Group, Docker, etc.), veja **[00 – Pré-requisitos AWS](00-pre-requisitos-aws.md)**.

---

## Arquitetura sugerida

- **Opção A – Uma instância:** 1 EC2 com Docker; painel + MariaDB + Redis + Wings no mesmo host. Mais simples; boa para teste ou poucos servidores de jogo.
- **Opção B – Duas instâncias:** EC2-1 = painel + MariaDB + Redis; EC2-2 = Wings (mais CPU/RAM para os jogos). O painel comunica com o Wings pelo IP privado ou DNS interno.

Este tutorial cobre a **Opção A**. Para a B, repita os passos do Wings noutra EC2 e use o IP privado da EC2-2 como FQDN do node no painel.

---

## Passo 1 – Criar a instância EC2

1. No **AWS Console** → **EC2** → **Launch Instance**.
2. **Name:** ex. `pterodactyl-cs2`.
3. **AMI:** **Amazon Linux 2** ou **Ubuntu Server 22.04**.
4. **Instance type:** ex. `t3.medium` (2 vCPU, 4 GB RAM) para painel + Wings; para muitos servidores de jogo, use instâncias maiores ou a Opção B.
5. **Key pair:** crie ou escolha uma chave SSH para aceder à instância.
6. **Network / Security group:** 
   - Crie ou use um Security Group que permita:
     - **SSH (22)** – do seu IP (ou 0.0.0.0/0 só para teste).
     - **HTTP (80)** e **HTTPS (443)** – para o painel (0.0.0.0/0 ou seu IP).
     - **8080** – API do Wings (recomendado restringir ao Security Group do painel ou à VPC).
     - **2022** – SFTP do Pterodactyl (opcional).
     - **27015** (e outras portas de jogo) – para clientes conectarem aos servidores CS2 (0.0.0.0/0 ou IPs dos jogadores).
7. **Storage:** mínimo 30–40 GB (CS2 precisa de ~33 GB por instância de jogo).
8. Launch a instância e anote o **IP público** (e o IP privado se usar duas instâncias).

Conecte por SSH (substitua pelo seu utilizador e IP):

```bash
# Amazon Linux 2
ssh -i sua-chave.pem ec2-user@<IP-PUBLICO>

# Ubuntu
ssh -i sua-chave.pem ubuntu@<IP-PUBLICO>
```

---

## Passo 2 – Instalar Docker e Docker Compose na EC2

**Amazon Linux 2:**

```bash
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
```

**Docker Compose v2:**

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

**Ubuntu:**

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
```

Faça **logout e login** (ou `newgrp docker`) para o grupo `docker` ser aplicado. Verifique:

```bash
docker --version
docker compose version
```

---

## Passo 3 – Clonar o projeto na EC2

```bash
# Substitua pela URL do seu repositório
git clone https://github.com/seu-usuario/cs2-csgo.git cs2-csgo
cd cs2-csgo
```

Se o repositório for privado, configure SSH key ou token no Git na EC2, ou use HTTPS com credenciais.

---

## Passo 4 – Criar e editar o `.env`

```bash
cp .env.example .env
nano .env
```

Defina pelo menos:

| Variável | Exemplo (EC2) | Descrição |
|----------|----------------|-----------|
| `MYSQL_ROOT_PASSWORD` | `root123` | Senha root do MariaDB |
| `MYSQL_PASSWORD` | `panel123` | Senha do utilizador do painel |
| `APP_URL` | `http://<IP-PUBLICO>` ou `https://painel.seudominio.com` | URL pública do painel |
| `APP_SERVICE_AUTHOR` | `admin@seudominio.com` | E-mail do admin |

Se o Wings estiver na **mesma** máquina, no painel o node terá FQDN = `localhost` ou o IP privado da EC2 e porta 8080. As variáveis do Wings você preenche depois de criar o node (Passo 7).

---

## Passo 5 – Criar diretórios no host (Linux)

O Wings precisa de diretórios com permissões corretas:

```bash
sudo mkdir -p /var/lib/pterodactyl/volumes /run/wings/machine-id /tmp/pterodactyl
sudo chown -R 988:988 /var/lib/pterodactyl /run/wings/machine-id /tmp/pterodactyl
```

O UID/GID `988` é o utilizado pelo Wings dentro do container; ajuste se o seu setup for diferente.

---

## Passo 6 – Subir o painel

Na EC2, na pasta do projeto:

```bash
docker compose -f docker-compose-painel.yml up -d
```

Aguarde a construção da imagem e o arranque dos containers. Verifique:

```bash
docker compose -f docker-compose-painel.yml ps
```

Aceda ao painel em **http://&lt;IP-PUBLICO-DA-EC2&gt;** e crie a primeira conta (admin).

---

## Passo 7 – Criar o node e configurar o Wings

1. No painel: **Admin** → **Nodes** → **Create Node**.
   - **Name:** ex. `ec2-node`
   - **FQDN:** IP **público** da EC2 (ex.: `54.123.45.67`) ou domínio (ex.: `wings.seudominio.com`). O painel e os clientes (browser, jogos) usam este endereço para falar com o Wings.
   - **Daemon Port:** **8080**
   - **Use HTTP Connection** (ou HTTPS se tiver SSL).
2. Guarde e copie **Token ID** e **Token** da aba **Configuration**.

Na EC2, edite o `.env` e adicione:

```env
WINGS_API_HOST=http://panel
WINGS_TOKEN_ID=...
WINGS_SYSTEM_TOKEN=...
```

Ajuste também o `wings-config/config.yml` (uuid do node, token_id, token) para coincidir com o painel. No Linux pode existir um `docker-compose-wings.yml` (sem o override Windows); use-o para subir o Wings:

```bash
# Exemplo se existir docker-compose-wings.yml
docker compose -f docker-compose-wings.yml up -d
```

Se o projeto só tiver os composes para Windows, adapte o `docker-compose-wings-windows.yml` para Linux (remover volumes específicos do WSL2 e usar os caminhos do Passo 5).

---

## Passo 8 – Allocations e servidor CS2

1. **Admin** → **Nodes** → [seu node] → **Allocations** → crie porta **27015** (e mais se quiser vários servidores).
2. **Servers** → **Create Server** → node, egg CS2, alocação 27015, recursos.
3. Após a instalação, **Start** no servidor.
4. No **Security Group** da EC2, garanta que a porta **27015** (e 27016, etc., se usar) está aberta para os IPs dos jogadores (ex.: 0.0.0.0/0 para teste).

Os jogadores conectam com: **`connect &lt;IP-PUBLICO-EC2&gt;:27015`**.

---

## Passo 9 – SSL (opcional, produção)

Para **HTTPS** no painel:

- **Opção 1:** Coloque um **Application Load Balancer (ALB)** à frente da EC2, com certificado no **AWS Certificate Manager (ACM)** e listener HTTPS (443) encaminhando para a EC2 na porta 80 (ou 443).
- **Opção 2:** Na própria EC2, use **Nginx** como reverso proxy com **Let's Encrypt** (certbot) e aponte `APP_URL` para `https://painel.seudominio.com`.

Ajuste o `APP_URL` no `.env` para a URL HTTPS e reinicie o painel.

---

## Resumo dos comandos (EC2)

| Ação | Comando |
|------|--------|
| Conectar à EC2 | `ssh -i sua-chave.pem ec2-user@<IP>` |
| Clonar projeto | `git clone <URL> cs2-csgo` → `cd cs2-csgo` |
| Criar .env | `cp .env.example .env` ou `cp .env.aws.example .env` → `nano .env` |
| Criar dirs Wings | `sudo mkdir -p ...` e `sudo chown -R 988:988 ...` |
| Subir painel | `docker compose -f docker-compose-painel.yml up -d` |
| Subir painel (AWS, volumes nomeados) | `docker compose -f docker-compose-painel.yml -f docker-compose-painel.aws.yml up -d` |
| Subir Wings | `docker compose -f docker-compose-wings.yml up -d` (conforme o projeto) |

Para overrides específicos da AWS (volumes nomeados, uso com ALB), veja **[docs/aws-docker-compose.md](../docs/aws-docker-compose.md)**.

---

## Problemas comuns

- **Painel não abre no browser** → Verifique Security Group (80/443) e que o serviço está a escutar: `curl -I http://localhost` na EC2.
- **Node offline** → Confirme que o Wings está a correr e que o FQDN do node resolve para a EC2 (IP ou DNS) e que a porta 8080 está acessível (Security Group e firewall).
- **Jogadores não conectam ao servidor** → Abra a porta do jogo (27015, etc.) no Security Group para os IPs dos jogadores.

Mais detalhes em **[docs/setup/README.md](../docs/setup/README.md)** (secção AWS EC2).
