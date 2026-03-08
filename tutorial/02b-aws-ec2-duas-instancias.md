# Tutorial 02B – AWS EC2: Duas Instâncias (Painel + Wings separados)

Este tutorial cobre a **Opção B** da arquitetura EC2: duas instâncias separadas, onde a **EC2-1** roda o painel Pterodactyl (+ MariaDB + Redis) e a **EC2-2** roda apenas o Wings — deixando mais CPU e RAM disponíveis para os servidores de jogo (CS2).

> Para a Opção A (tudo em uma instância), veja **[02 – AWS EC2](02-aws-ec2.md)**.

---

## O que você vai ter no final

- **EC2-1:** Painel Pterodactyl acessível pela URL pública (IP ou domínio)
- **EC2-2:** Wings a escutar na porta 8080, comunicando com o painel pelo IP privado (rede interna da VPC)
- Servidores de jogo (ex.: CS2) criados pelo painel e acessíveis pelos jogadores diretamente no IP público da EC2-2

---

## Pré-requisitos

- Conta **AWS** com permissão para criar EC2, Security Groups e VPC
- As duas instâncias devem estar **na mesma VPC e subnet** (ou subnets com roteamento interno)
- (Opcional) Domínio e certificado SSL para HTTPS no painel
- Leia **[00 – Pré-requisitos AWS](00-pre-requisitos-aws.md)** antes de começar

---

## Arquitetura

```
Internet
   │
   ├──── HTTP/HTTPS (80/443) ──► EC2-1 (Painel + MariaDB + Redis)
   │                                        │
   │                              porta 8080 (IP privado da VPC)
   │                                        │
   └──── portas de jogo (27015+) ──► EC2-2 (Wings)
                                         │
                                   volumes dos servidores CS2
```

O painel na EC2-1 chama o Wings na EC2-2 usando o **IP privado** (ou DNS privado) da VPC. Os jogadores conectam diretamente no **IP público da EC2-2** nas portas de jogo.

---

## Passo 1 – Criar as duas instâncias EC2

### EC2-1 (Painel)

1. **AWS Console** → **EC2** → **Launch Instance**
2. **Name:** `pterodactyl-panel`
3. **AMI:** Ubuntu Server 22.04 (ou Amazon Linux 2)
4. **Instance type:** `t3.small` ou `t3.medium` (o painel é leve; 2 GB RAM são suficientes)
5. **Key pair:** crie ou reutilize uma chave SSH
6. **Security Group** – crie `sg-panel` com as regras:

| Tipo | Protocolo | Porta | Origem |
|------|-----------|-------|--------|
| SSH | TCP | 22 | Seu IP |
| HTTP | TCP | 80 | 0.0.0.0/0 |
| HTTPS | TCP | 443 | 0.0.0.0/0 |

7. **Storage:** 20 GB (o painel não precisa de muito espaço)
8. Lance e anote o **IP público** e o **IP privado** da EC2-1

### EC2-2 (Wings)

1. **Launch Instance** novamente
2. **Name:** `pterodactyl-wings`
3. **AMI:** mesma do EC2-1 (Ubuntu 22.04 recomendado)
4. **Instance type:** `t3.large` ou maior — o Wings precisa de recursos para rodar os containers dos jogos (CS2 usa ~4–6 GB RAM por instância)
5. **Key pair:** a mesma chave SSH
6. **Security Group** – crie `sg-wings` com as regras:

| Tipo | Protocolo | Porta | Origem |
|------|-----------|-------|--------|
| SSH | TCP | 22 | Seu IP |
| API Wings | TCP | 8080 | sg-panel (ou IP privado da EC2-1) |
| SFTP | TCP | 2022 | 0.0.0.0/0 (opcional) |
| CS2 / jogos | UDP/TCP | 27015–27020 | 0.0.0.0/0 |

> Restringir a porta 8080 ao `sg-panel` (ou ao CIDR privado da VPC) é uma boa prática de segurança — a porta da API do Wings não precisa ser exposta à internet.

7. **Storage:** mínimo 60–80 GB (cada servidor CS2 ocupa ~33 GB)
8. Lance e anote o **IP público** e o **IP privado** da EC2-2

---

## Passo 2 – Instalar Docker nas duas instâncias

Repita os comandos abaixo **em cada EC2** (conecte via SSH em cada uma).

**Conectar à EC2-1:**

```bash
ssh -i sua-chave.pem ubuntu@<IP-PUBLICO-EC2-1>
```

**Conectar à EC2-2:**

```bash
ssh -i sua-chave.pem ubuntu@<IP-PUBLICO-EC2-2>
```

**Instalar Docker (Ubuntu 22.04) — rode em cada EC2:**

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

Faça **logout e login** (ou `newgrp docker`) em cada EC2 para o grupo `docker` ser aplicado. Verifique:

```bash
docker --version
docker compose version
```

---

## Passo 3 – Configurar a EC2-1 (Painel)

### 3.1 – Clonar o projeto

```bash
git clone https://github.com/seu-usuario/cs2-csgo.git cs2-csgo
cd cs2-csgo
```

### 3.2 – Criar e editar o `.env`

```bash
cp .env.aws.example .env
nano .env
```

Preencha as variáveis principais:

| Variável | Exemplo | Descrição |
|----------|---------|-----------|
| `MYSQL_ROOT_PASSWORD` | `root123` | Senha root do MariaDB |
| `MYSQL_PASSWORD` | `panel123` | Senha do utilizador do painel |
| `APP_URL` | `http://<IP-PUBLICO-EC2-1>` | URL pública do painel |
| `APP_SERVICE_AUTHOR` | `admin@seudominio.com` | E-mail do admin |

> Deixe as variáveis `WINGS_TOKEN_ID` e `WINGS_SYSTEM_TOKEN` em branco por ora — você as preencherá depois de criar o node no painel (Passo 5).

### 3.3 – Subir o painel

```bash
docker compose -f docker-compose-painel.yml up -d
```

Aguarde o arranque e verifique:

```bash
docker compose -f docker-compose-painel.yml ps
```

Acesse **http://\<IP-PUBLICO-EC2-1\>** e crie a primeira conta (admin).

---

## Passo 4 – Configurar a EC2-2 (Wings)

### 4.1 – Clonar o projeto

```bash
git clone https://github.com/seu-usuario/cs2-csgo.git cs2-csgo
cd cs2-csgo
```

### 4.2 – Criar diretórios necessários pelo Wings

```bash
sudo mkdir -p /var/lib/pterodactyl/volumes /run/wings/machine-id /tmp/pterodactyl
sudo chown -R 988:988 /var/lib/pterodactyl /run/wings/machine-id /tmp/pterodactyl
```

O UID/GID `988` é o utilizado pelo Wings dentro do container. Ajuste se necessário.

### 4.3 – Criar o `.env` (para o Wings)

```bash
cp .env.aws.example .env
nano .env
```

Deixe `APP_URL` apontando para o painel na EC2-1 (você vai precisar depois). As variáveis `WINGS_TOKEN_ID` e `WINGS_SYSTEM_TOKEN` serão preenchidas no Passo 5.

---

## Passo 5 – Criar o Node no painel e gerar o token do Wings

1. Acesse o painel em **http://\<IP-PUBLICO-EC2-1\>** como admin.
2. **Admin** → **Nodes** → **Create Node**:
   - **Name:** `ec2-wings`
   - **FQDN:** **IP público da EC2-2** (ex.: `54.200.10.20`) ou domínio (ex.: `wings.seudominio.com`)
     > O painel usará o IP privado para comunicar internamente, mas o FQDN é o que os clientes (browser, jogadores) precisam resolver. Se quiser usar IP privado (apenas em ambientes onde o browser do admin também está na VPC), use o IP privado; caso contrário, use o IP público.
   - **Daemon Port:** `8080`
   - **Use HTTP Connection** (marque HTTPS só se tiver certificado no Wings)
   - **Memory / Disk:** defina os limites com base na EC2-2 escolhida
3. Clique em **Create Node** e acesse a aba **Configuration**.
4. Copie o **Token ID** e o **Token**.

### 5.1 – Atualizar o `.env` da EC2-2

De volta à EC2-2:

```bash
nano .env
```

Adicione/atualize:

```env
WINGS_API_HOST=http://<IP-PRIVADO-EC2-1>
WINGS_TOKEN_ID=<token-id-copiado>
WINGS_SYSTEM_TOKEN=<token-copiado>
```

> Use o **IP privado** da EC2-1 em `WINGS_API_HOST` para que a comunicação Wings → Painel fique dentro da VPC (mais rápida e sem custo de transferência de dados).

### 5.2 – Atualizar o `wings-config/config.yml`

Edite (ou gere) o arquivo `wings-config/config.yml` com os valores do node. Você pode copiar o YAML gerado pelo painel na aba Configuration e salvar em `wings-config/config.yml`:

```bash
nano wings-config/config.yml
```

Certifique-se de que `api.host` aponta para o IP privado do painel e que `uuid`, `token_id` e `token` correspondem ao node criado.

### 5.3 – Subir o Wings

```bash
docker compose -f docker-compose-wings.yml up -d
```

Verifique se o Wings está a correr e se o node aparece como **online** no painel:

```bash
docker compose -f docker-compose-wings.yml logs -f
```

---

## Passo 6 – Criar allocations e servidor CS2

1. **Admin** → **Nodes** → `ec2-wings` → **Allocations**
   - **IP:** IP **público** da EC2-2 (ex.: `54.200.10.20`)
   - **Ports:** `27015` (adicione mais se quiser vários servidores: `27016`, `27017`, etc.)
2. **Servers** → **Create Server**:
   - **Node:** `ec2-wings`
   - **Egg:** CS2
   - **Allocation:** 27015
   - **Memory/CPU/Disk:** conforme os recursos da EC2-2
3. Após a instalação, clique em **Start** no servidor.
4. Confirme que a porta **27015 UDP/TCP** está aberta no Security Group `sg-wings` para `0.0.0.0/0` (ou os IPs dos jogadores).

Os jogadores conectam com: **`connect <IP-PUBLICO-EC2-2>:27015`**

---

## Passo 7 – SSL (opcional, produção)

### Painel (EC2-1)

- **Opção ALB:** Coloque um Application Load Balancer à frente da EC2-1 com certificado no ACM. O listener HTTPS (443) encaminha para a EC2-1 na porta 80. Atualize `APP_URL=https://painel.seudominio.com`.
- **Opção Nginx + Let's Encrypt:** Instale o Nginx na EC2-1 como reverso proxy e use certbot para obter o certificado.

### Wings (EC2-2)

- Configure o Wings para usar HTTPS (com certificado válido para o FQDN do node).
- Atualize o node no painel para usar HTTPS e porta 443 (ou 8443).
- Reinicie o Wings após a configuração.

---

## Resumo dos comandos

### EC2-1 (Painel)

| Ação | Comando |
|------|---------|
| Conectar | `ssh -i chave.pem ubuntu@<IP-EC2-1>` |
| Clonar projeto | `git clone <URL> cs2-csgo && cd cs2-csgo` |
| Criar `.env` | `cp .env.aws.example .env && nano .env` |
| Subir painel | `docker compose -f docker-compose-painel.yml up -d` |
| Ver logs | `docker compose -f docker-compose-painel.yml logs -f` |
| Reiniciar | `docker compose -f docker-compose-painel.yml restart` |

### EC2-2 (Wings)

| Ação | Comando |
|------|---------|
| Conectar | `ssh -i chave.pem ubuntu@<IP-EC2-2>` |
| Clonar projeto | `git clone <URL> cs2-csgo && cd cs2-csgo` |
| Criar dirs | `sudo mkdir -p /var/lib/pterodactyl/volumes /run/wings/machine-id /tmp/pterodactyl && sudo chown -R 988:988 ...` |
| Criar `.env` | `cp .env.aws.example .env && nano .env` |
| Subir Wings | `docker compose -f docker-compose-wings.yml up -d` |
| Ver logs | `docker compose -f docker-compose-wings.yml logs -f` |

---

## Problemas comuns

- **Node offline no painel** → Verifique se o Wings está a correr na EC2-2 (`docker ps`), se a porta 8080 está acessível no Security Group `sg-wings` para a EC2-1, e se o FQDN do node resolve corretamente.
- **Wings não consegue contactar o painel** → Confirme que `WINGS_API_HOST` usa o **IP privado** (ou público) correto da EC2-1 e que não há firewall bloqueando a comunicação entre as duas instâncias na VPC.
- **Jogadores não conectam ao servidor CS2** → Verifique se a porta 27015 UDP/TCP está aberta no `sg-wings` e se o servidor está no estado **Running** no painel.
- **Painel não abre no browser** → Verifique o Security Group `sg-panel` (portas 80/443) e se o container do painel está a correr: `docker compose -f docker-compose-painel.yml ps`.

---

Mais detalhes em **[docs/setup/README.md](../docs/setup/README.md)** e **[docs/aws-docker-compose.md](../docs/aws-docker-compose.md)**.
