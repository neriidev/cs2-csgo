# Tutorial 01 – Clonar e configurar em outra máquina local

Este tutorial ensina a **clonar** o projeto **cs2-csgo** e configurá-lo em **outro PC com Windows**, com Docker Desktop, para rodar o painel Pterodactyl e o Wings (servidores de jogo).

---

## O que você vai ter no final

- Painel acessível em **http://localhost**
- Wings conectado ao painel (node online)
- Possibilidade de criar e gerir servidores CS2/CSGO pelo painel
- Console do servidor funcionando no browser

---

## Pré-requisitos na máquina

- **Windows 10 ou 11**
- **Docker Desktop** instalado e em execução, com motor **WSL2**
- **Git** instalado ([git-scm.com](https://git-scm.com))
- Portas **80, 443, 8080, 2022** livres (ou você altera no compose)

---

## Passo 1 – Clonar o projeto

Abra **PowerShell** (ou Terminal do Windows) e execute:

```powershell
# Troque pela URL real do seu repositório
git clone https://github.com/seu-usuario/cs2-csgo.git cs2-csgo
cd cs2-csgo
```

Se você ainda não tiver o projeto em um repositório remoto:

1. Na máquina onde o projeto já existe, crie um repositório no GitHub/GitLab (ex.: `cs2-csgo`).
2. Na pasta do projeto, execute:
   ```powershell
   git init
   git remote add origin https://github.com/seu-usuario/cs2-csgo.git
   git add .
   git commit -m "Initial commit"
   git push -u origin main
   ```
3. Na **outra máquina**, use o `git clone` do passo 1 acima.

---

## Passo 2 – Criar o ficheiro `.env`

O projeto usa variáveis de ambiente definidas no ficheiro `.env`. Como o `.env` normalmente não vai no Git (por segurança), você precisa criá-lo a partir do exemplo.

```powershell
# Se existir .env.example:
copy .env.example .env

# Se não existir, crie um ficheiro .env vazio:
# New-Item -Path .env -ItemType File
notepad .env
```

Preencha no mínimo as seguintes variáveis:

| Variável | Exemplo | Descrição |
|----------|---------|-----------|
| `MYSQL_ROOT_PASSWORD` | `root123` | Senha do utilizador root do MariaDB |
| `MYSQL_PASSWORD` | `panel123` | Senha do utilizador do painel (base de dados) |
| `APP_URL` | `http://localhost` | URL em que você acede ao painel (local = localhost) |
| `APP_SERVICE_AUTHOR` | `admin@localhost` | E-mail do administrador do painel |

Exemplo de conteúdo mínimo do `.env`:

```env
MYSQL_ROOT_PASSWORD=root123
MYSQL_PASSWORD=panel123
APP_URL=http://localhost
APP_SERVICE_AUTHOR=admin@localhost
```

As variáveis do **Wings** (`WINGS_API_HOST`, `WINGS_TOKEN_ID`, `WINGS_SYSTEM_TOKEN`) você preenche **depois** de criar o node no painel (Passo 6).

---

## Passo 3 – Criar diretório no WSL2 (obrigatório no Windows)

O Wings usa o diretório `/tmp/pterodactyl` no **host do Docker** (WSL2). Esse diretório precisa existir, senão o Reinstall dos servidores falha com "bind source path does not exist".

Execute **uma vez** no PowerShell:

```powershell
wsl -e sh -c "mkdir -p /tmp/pterodactyl"
```

---

## Passo 4 – Subir o painel

Na pasta do projeto (`cs2-csgo`):

```powershell
docker compose -f docker-compose-painel.yml up -d
```

Na primeira execução, a imagem do painel é construída (pode demorar alguns minutos). Aguarde os containers `database`, `redis` e `panel` ficarem em execução.

Verifique:

```powershell
docker compose -f docker-compose-painel.yml ps
```

Abra o browser em **http://localhost**. Deve aparecer a página de registo do Pterodactyl. **Crie a primeira conta** – ela será a conta de administrador.

---

## Passo 5 – Criar o node no painel

1. Faça login no painel (http://localhost).
2. Vá a **Admin** → **Nodes** → **Create Node**.
3. Preencha:
   - **Name:** por exemplo `local`
   - **FQDN:** **`wings`** (importante: será usado para o Console no browser)
   - **Daemon Port:** **8080**
   - Marque **Use HTTP Connection** (sem SSL para ambiente local).
4. Guarde e abra o node criado → aba **Configuration**.
5. Copie o **Token ID** e o **Token** (ou o bloco de configuração completo).

---

## Passo 6 – Configurar o Wings no `.env` e no `config.yml`

Abra de novo o `.env` e adicione (substitua pelos valores que você copiou do painel):

```env
WINGS_API_HOST=http://panel
WINGS_TOKEN_ID=o-token-id-copiado
WINGS_SYSTEM_TOKEN=o-token-copiado
```

Abra `wings-config/config.yml` e confirme/ajuste:

- `api.host`: deve estar `0.0.0.0` ou o valor que o painel indicar (mantenha consistente com o node).
- `api.port`: `8080`
- `system.token_id` e `system.token`: os mesmos do painel (ou deixe o painel sobrescrever; o projeto pode ter `ignore_panel_config_updates: true` e usar só o que está no ficheiro).

O **uuid** do node no `config.yml` deve coincidir com o UUID do node no painel (visible na página do node).

---

## Passo 7 – Subir o Wings na mesma rede do painel

Para o painel e o browser conseguirem falar com o Wings, o container do Wings precisa estar na rede interna do painel (`pterodactyl_net`). Use o compose do Wings **com** o override interno:

```powershell
docker compose -f docker-compose-wings-windows.yml -f docker-compose-wings-windows-internal.yml up -d --force-recreate wings
```

Verifique os logs:

```powershell
docker compose -f docker-compose-wings-windows.yml logs wings -f
```

Deve aparecer que o Wings está a escutar na porta 8080 e que carregou as configurações dos servidores. No painel, o node deve ficar **online** (ícone verde).

---

## Passo 8 – Ficheiro hosts (para o Console no browser)

O painel usa o FQDN do node (**wings**) para o WebSocket do Console. O browser corre no Windows e precisa resolver o nome **wings** para o seu PC.

1. Abra **Bloco de notas** **como Administrador**.
2. Ficheiro → Abrir → navegue até `C:\Windows\System32\drivers\etc`.
3. Em "Tipo", escolha **Todos os ficheiros** e abra o ficheiro **hosts**.
4. No final do ficheiro, adicione uma linha:
   ```text
   127.0.0.1 wings
   ```
5. Guarde e feche.

Assim, quando você abrir o Console de um servidor no browser, a ligação **ws://wings:8080/...** resolve para **127.0.0.1:8080**, onde o Wings está a escutar.

---

## Passo 9 – Criar um servidor CS2 (resumo)

1. **Admin** → **Nodes** → [seu node] → **Allocations** → crie uma alocação com porta **27015** (ou um range, ex.: 27015–27020).
2. **Admin** → **Nests** → certifique-se de que existe o egg **Counter-Strike 2** (ou importe de [eggs.pterodactyl.io](https://eggs.pterodactyl.io)).
3. **Servers** → **Create Server** → escolha o node, o egg CS2, alocação 27015, recursos (ex.: 2048 MiB RAM, 35 GB disco).
4. Após a criação, espere a **instalação** terminar (ou use Reinstall se necessário).
5. **Start** no servidor. Na consola do jogo (CS2 no seu PC), conecte com: **`connect 127.0.0.1:27015`** (não use `0.0.0.0` no cliente).

Para mais detalhes, consulte **[docs/subir-servidor-cs2.md](../docs/subir-servidor-cs2.md)**.

---

## Resumo dos comandos (outra máquina local)

| Ação | Comando |
|------|--------|
| Clonar | `git clone <URL> cs2-csgo` → `cd cs2-csgo` |
| Criar .env | `copy .env.example .env` e editar |
| Criar /tmp/pterodactyl no WSL2 | `wsl -e sh -c "mkdir -p /tmp/pterodactyl"` |
| Subir painel | `docker compose -f docker-compose-painel.yml up -d` |
| Subir Wings | `docker compose -f docker-compose-wings-windows.yml -f docker-compose-wings-windows-internal.yml up -d` |
| Parar painel | `docker compose -f docker-compose-painel.yml down` |
| Logs do Wings | `docker compose -f docker-compose-wings-windows.yml logs wings -f` |

---

## Problemas comuns

- **"Could not establish a connection to the machine"** no Console → confirme que adicionou `127.0.0.1 wings` ao ficheiro **hosts** e que o Wings está em execução.
- **Reinstall dá 500** → verifique se o painel alcança o Wings (FQDN do node = `wings`, Wings na rede `pterodactyl_net`).
- **Erro `io.weight`** ou container do servidor não arranca → o projeto já inclui o patch em `panel-patch/Server.php`; no painel, use **Disk I/O = 0** para esse servidor.
- **"bind source path does not exist"** no Reinstall → confirme que executou `wsl -e sh -c "mkdir -p /tmp/pterodactyl"` e que o `docker-compose-wings-windows.yml` monta `/tmp/pterodactyl` corretamente.

Mais soluções em **[docs/erro-conectando-node.md](../docs/erro-conectando-node.md)** e **[docs/setup/README.md](../docs/setup/README.md)**.
