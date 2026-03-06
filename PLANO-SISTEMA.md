# Planejamento: Sistema de Gerenciamento de Servidores de Jogos

## 1. Visão geral

Sistema para subir e gerenciar **múltiplos servidores de jogos** usando:
- **Pterodactyl Panel** – painel web para administração
- **Pterodactyl Wings** – daemon que executa os containers dos jogos
- **Nginx Proxy Manager** (futuro) – proxy reverso e SSL em produção

---

## 2. O que já foi feito (estado atual)

### 2.1 `docker-compose-painel.yml`

| Componente | Status | Descrição |
|------------|--------|-----------|
| **MariaDB 10.5** | ✅ Configurado | Banco do painel, volume `./db`, credenciais via env |
| **Redis (Alpine)** | ✅ Configurado | Cache/sessão/fila do Laravel |
| **Panel (Pterodactyl)** | ✅ Configurado | Portas 80/443, rede `pterodactyl_net`, volumes para var, nginx, certs, logs |
| **Rede** | ✅ | `pterodactyl_net` (bridge) |
| **Variáveis** | ✅ | Uso de `.env` (veja `.env.example`). Obrigatório: `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`. Opcional: `APP_URL`, `APP_SERVICE_AUTHOR`. |

**Volumes:** `./var/` → `/app/var/`, `./nginx/` → `/etc/nginx/http.d/`, `./certs/` → `/etc/letsencrypt/`, `./logs/` → `/app/storage/logs/`

**Pendências (ação do usuário):**
- Copiar `.env.example` para `.env` e preencher senhas e `APP_URL`.
- Completar instalação no primeiro acesso (criar admin, configurar node).

### 2.2 `docker-compose-wings.yml`

| Item | Status | Descrição |
|------|--------|-----------|
| **Wings** | ✅ Configurado | Imagem oficial, `network_mode: host`, `privileged: true` |
| **Volumes** | ✅ | Docker socket, containers, `/etc/pterodactyl`, `/var/lib/pterodactyl`, `/tmp/pterodactyl`, `/dev/log` |
| **Timezone** | ✅ | America/Sao_Paulo |
| **WINGS_UID/GID** | ✅ | 988 (padrão Pterodactyl) |

**Observação:** Wings usa `network_mode: host` para que as portas dos jogos (ex.: 27015 para CS2) fiquem diretamente no IP da máquina. Por isso o Wings **não** deve rodar no mesmo `docker-compose` do painel (que usa rede bridge).

**Pendências no Wings (ação do usuário):**
- No **host**: copiar `pterodactyl/config.yml.example` para `/etc/pterodactyl/config.yml` e preencher `api.host`, `api.key`, `system.token` (valores gerados no painel).

### 2.3 Nginx do painel

- `nginx/panel.conf`: config básica do Laravel (PHP-FPM, `client_max_body_size 100m`).  
- Em produção com Nginx Proxy Manager, esse Nginx interno do painel continuará servindo a app; o NPM ficará na frente fazendo proxy e SSL.

---

## 3. Arquitetura alvo

```
                    [Internet]
                         |
                         v
              +----------------------+
              |  Nginx Proxy Manager |  (futuro: SSL, domínios, proxy)
              |  (porta 80/443)      |
              +----------+-----------+
                         |
         +---------------+---------------+
         |                               |
         v                               v
+----------------+              +----------------+
| Painel         |              | Outros serviços|
| (Pterodactyl)  |              | (opcional)     |
+--------+-------+              +----------------+
         |
         | API (HTTPS)
         v
+----------------+
| Wings (host)   |  <- network_mode: host
| + containers   |     Cada jogo = 1 container
|   dos jogos    |
+----------------+
```

- **Um painel** pode gerenciar **vários nodes (Wings)**. Cada node é uma máquina (ou VM) com Wings rodando.
- Em cada node, o Wings sobe vários **containers** (um por servidor de jogo).
- Nginx Proxy Manager fica na frente do painel (e de outros serviços) para HTTPS e múltiplos domínios.

---

## 4. Roadmap do projeto

### Fase 1 – Ambiente atual estável

- [x] Ajustar `docker-compose-painel.yml`: uso de `.env` (`.env.example`), variáveis obrigatórias.
- [ ] **Você:** Copiar `.env.example` → `.env`, preencher senhas e `APP_URL`.
- [ ] Subir painel: `docker compose -f docker-compose-painel.yml up -d`.
- [ ] Completar instalação do painel (primeiro acesso, criar admin, configurar node no painel).
- [x] Template do Wings: `pterodactyl/config.yml.example`. **Você:** no host, copiar para `/etc/pterodactyl/config.yml` e preencher `api.host`, `api.key`, `system.token`.
- [ ] Subir Wings: `docker compose -f docker-compose-wings.yml up -d` (no host dos jogos).
- [ ] Registrar servidor de jogo no painel (Egg CS2/CS:GO, etc.) e testar.

Guia passo a passo: **[docs/instalacao.md](docs/instalacao.md)**.

### Fase 2 – Múltiplos servidores de jogo

- [ ] Definir faixa de portas para jogos (ex: 27015–27030 para CS2).
- [ ] No painel: criar vários “Servers”, cada um com porta única.
- [ ] (Opcional) Segundo host com outro Wings = segundo node no painel para escalar.

Guia: **[docs/faixa-portas.md](docs/faixa-portas.md)**.

### Fase 3 – Produção com Nginx Proxy Manager

- [x] `docker-compose-proxy.yml` com NPM (rede `proxy_net` externa).
- [x] Override do painel: `docker-compose-painel.npm.yml` (painel em 8080/8443, rede `proxy_net`).
- [ ] **Você:** `docker network create proxy_net`; subir NPM e painel com override; no NPM, Proxy Host → `panel:8080`; SSL; ajustar `APP_URL`.

Guia: **[docs/npm-producao.md](docs/npm-producao.md)**.

### Fase 4 – Melhorias opcionais

- [x] Scripts de backup: `scripts/backup-painel.sh` e `scripts/backup-painel.bat`; documentação em **docs/backup.md**.
- [ ] Agendar backup (cron / Agendador de Tarefas) e testar restauração.
- [ ] Monitoramento (ex.: Uptime Kuma, Prometheus).
- [ ] Firewall: abrir só 80/443 no NPM e portas dos jogos no host do Wings.

---

## 5. Estrutura de arquivos (implementada)

```
cs2-csgo/
├── .env.example                 # Template de variáveis (copiar para .env)
├── docker-compose-painel.yml    # Panel + MariaDB + Redis
├── docker-compose-painel.npm.yml # Override: painel atrás do NPM (porta 8080, rede proxy_net)
├── docker-compose-wings.yml     # Wings
├── docker-compose-proxy.yml     # Nginx Proxy Manager (rede proxy_net externa)
├── PLANO-SISTEMA.md             # Este arquivo
├── db/                          # Dados MariaDB
├── var/                         # .env e dados do painel (var/.env.example = exemplo Laravel)
├── nginx/                       # panel.conf
├── certs/                       # LetsEncrypt
├── logs/                        # Logs Laravel
├── pterodactyl/
│   └── config.yml.example       # Template do Wings (copiar para /etc/pterodactyl/config.yml no host)
├── scripts/
│   ├── backup-painel.sh         # Backup banco + var (Linux)
│   └── backup-painel.bat        # Backup banco + var (Windows)
└── docs/
    ├── instalacao.md            # Fase 1: passo a passo
    ├── faixa-portas.md          # Fase 2: múltiplos servidores
    ├── npm-producao.md          # Fase 3: NPM em produção
    └── backup.md                # Fase 4: backup e restauração
```

---

## 6. Uso do Nginx Proxy Manager (Fase 3)

Já implementado:

1. **docker-compose-proxy.yml** – NPM nas portas 80, 443 e 81; rede `proxy_net` **externa** (criar com `docker network create proxy_net`).
2. **docker-compose-painel.npm.yml** – Override do painel: portas 8080/8443, container `panel` na rede `proxy_net`.
3. No NPM: Proxy Host com Forward Hostname `panel`, Forward Port `8080`; SSL (Let’s Encrypt).
4. Manter `APP_URL` no `.env` com o domínio público (ex: `https://painel.seudominio.com`).

Passo a passo: **[docs/npm-producao.md](docs/npm-producao.md)**.

---

## 7. Resumo

| Parte | Situação | Próximo passo |
|-------|----------|----------------|
| Painel | Compose + .env | Copiar `.env.example` → `.env`, preencher e subir; ver [docs/instalacao.md](docs/instalacao.md) |
| Wings | Compose + template config | Copiar `pterodactyl/config.yml.example` para `/etc/pterodactyl/config.yml` no host e subir |
| Múltiplos servidores | Guia | [docs/faixa-portas.md](docs/faixa-portas.md) |
| Nginx Proxy Manager | Compose + override painel | [docs/npm-producao.md](docs/npm-producao.md) |
| Backup | Scripts + doc | [docs/backup.md](docs/backup.md), `scripts/backup-painel.sh` ou `.bat` |

Implementação concluída conforme este plano. Próximos passos são de configuração e uso (criar .env, config do Wings, subir serviços e configurar NPM quando for para produção).
