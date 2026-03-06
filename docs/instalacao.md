# Instalação – Fase 1 (ambiente estável)

## Pré-requisitos

- Docker e Docker Compose instalados
- (Wings) Linux com Docker no host onde rodarão os jogos

## 1. Painel

### 1.1 Variáveis de ambiente

Na raiz do projeto:

```bash
cp .env.example .env
```

Edite `.env` e defina:

- `MYSQL_ROOT_PASSWORD` – senha root do MariaDB
- `MYSQL_PASSWORD` – senha do usuário `pterodactyl` (mesma para o painel)
- `APP_URL` – URL do painel (ex: `https://painel.seudominio.com` ou `http://IP:80` para teste)
- `APP_SERVICE_AUTHOR` – e-mail do administrador

### 1.2 Subir o painel

```bash
docker compose -f docker-compose-painel.yml up -d
```

### 1.3 Primeiro acesso

1. Acesse `APP_URL` no navegador.
2. Crie a conta de administrador.
3. Em **Admin → Nodes**: crie um node; depois clique no node → aba **Configuration** e copie a configuração (ou anote **api.key** e **system.token**). Veja [docs/onde-system-token.md](docs/onde-system-token.md).
4. Em **Admin → Nodes**: crie um node (nome, FQDN ou IP da máquina do Wings, porta **8080** para o Wings). Salve e anote a **Node API Key** do node.

## 2. Wings (na máquina que hospedará os jogos)

### 2.1 Configuração no host

O Wings usa `config.yml` no **host**, não dentro do container.

**Linux:** crie ou edite `/etc/pterodactyl/config.yml`:

```bash
sudo mkdir -p /etc/pterodactyl
sudo cp pterodactyl/config.yml.example /etc/pterodactyl/config.yml
sudo nano /etc/pterodactyl/config.yml
```

Ajuste:

- `api.host` – mesma URL do painel (`APP_URL`)
- `api.key` – **Node API Key** do node (Admin → Nodes → seu node)
- `system.token` – **System Token** (em **Admin → Nodes → [seu node] → Configuration**; veja [onde-system-token.md](onde-system-token.md))
- `allowed_origins` – inclua a URL do painel

Ou use o **config.yml** gerado pelo painel em Admin → Nodes → [seu node] → Configuration.

### 2.2 Diretórios no host

```bash
sudo mkdir -p /var/lib/pterodactyl/volumes
sudo mkdir -p /tmp/pterodactyl
# UID/GID 988 (padrão Wings)
sudo chown -R 988:988 /var/lib/pterodactyl /tmp/pterodactyl
```

### 2.3 Subir o Wings

Na pasta do projeto (ou onde está o `docker-compose-wings.yml`):

```bash
docker compose -f docker-compose-wings.yml up -d
```

Verifique os logs:

```bash
docker compose -f docker-compose-wings.yml logs -f wings
```

## 3. Primeiro servidor de jogo

1. No painel: **Admin → Nests** – instale o Nest/Egg do jogo (ex.: CS2).
2. **Admin → Locations** – crie uma localização se quiser.
3. **Servers → Create Server** – escolha o node, o Egg, alocações de porta (ex.: 27015) e crie o servidor.
4. Inicie o servidor pelo painel e teste a conexão.

## 4. Troubleshooting

- **Wings não conecta ao painel:** confira `api.host` (HTTPS se o painel usar SSL), `api.key` (Node API Key) e `system.token`. Reinicie o Wings após alterar `config.yml`.
- **Painel 500:** veja `./logs/` e `docker compose -f docker-compose-painel.yml logs panel`.
- **Senha do banco:** deve ser a mesma em `.env` (MYSQL_PASSWORD) e no painel (variável DB_* já vem do compose).
