# Wings no Docker Desktop (Windows) – modo bridge

Dá para rodar o **Wings direto no Docker do Windows** (sem WSL2), em modo **bridge**, e ter as portas dos jogos acessíveis no Windows. O Wings **não** usa `network_mode: host`; as portas são expostas pelo Docker normalmente.

---

## Como funciona

- O **Wings** roda em um container em rede bridge.
- A porta **8080** (daemon do Wings) e a **2022** (SFTP) são publicadas no Windows.
- Quando você cria um servidor de jogo no painel, o Wings cria um **outro** container para esse jogo; o Docker publica a porta desse container no Windows (ex.: 27015).
- O **painel** (também em container) conversa com o Wings em **host.docker.internal:8080** (o Windows “vira” o host para o Docker).

---

## Passo a passo

### 1. Painel no ar (para o Wings conectar)

O Wings **não** depende mais da rede do painel: você pode subir o Wings antes. Mas para o Wings conectar no painel, o painel precisa estar no ar. Se ainda não subiu o painel:

```powershell
cd C:\Users\rodri\OneDrive\Desktop\cs2-csgo
docker compose -f docker-compose-painel.yml up -d
```

### 2. (Opcional) Chaves no .env para o Wings

Se você já criou o node no painel, pode colocar no **.env** (na raiz do projeto):

```env
WINGS_API_KEY=ptla_xxxx
WINGS_SYSTEM_TOKEN=xxxx
```

O compose vai usar isso para gerar o `wings-config/config.yml` automaticamente. Se não colocar, o config é gerado com placeholders; depois você edita `wings-config\config.yml` e reinicia o Wings.

### 3. Subir o Wings (Windows)

O **docker-compose-wings-windows.yml** tem um serviço **wings-init** que roda antes do Wings e gera as pastas e o **wings-config/config.yml** a partir do template e do .env. Basta subir:

```powershell
docker compose -f docker-compose-wings-windows.yml up -d
```

Na primeira vez o **wings-init** cria o config; em seguida o **wings** sobe. Se você não preencheu **WINGS_API_KEY** e **WINGS_SYSTEM_TOKEN** no .env, o Wings pode falhar ao conectar no painel. Nesse caso: crie o node no painel, copie a Node API Key e o System Token, coloque no .env (ou edite `wings-config\config.yml`), regenere o config e reinicie:

```powershell
docker compose -f docker-compose-wings-windows.yml up -d --force-recreate wings-init
docker compose -f docker-compose-wings-windows.yml restart wings
```

### 4. Registrar o node no painel

Ver logs do Wings (opcional): `docker compose -f docker-compose-wings-windows.yml logs -f wings`

1. No painel: **Admin** → **Nodes** → **Create Node**.
2. Preencha conforme o guia **[docs/criar-node-painel.md](criar-node-painel.md)**. Em resumo:
   - **FQDN:** **host.docker.internal**
   - **Communicate Over SSL:** marque **Use HTTP Connection** (não use SSL no ambiente local).
   - **Daemon Port:** **8080**
   - **Daemon SFTP Port:** **2022**
   - **Daemon Server File Directory:** `/var/lib/pterodactyl/volumes`
   - Preencha **Total Memory** e **Total Disk Space** (ex.: 5000 MiB e 10000 MiB).
3. Clique em **Create Node**.
4. Na tela do node, copie a **Node API Key** e o **System Token** (ambos na aba **Configuration** do mesmo node; veja [onde-system-token.md](onde-system-token.md)). Coloque no **.env** como `WINGS_API_KEY=ptla_xxx` e `WINGS_SYSTEM_TOKEN=xxx`, depois regenere o config e reinicie o Wings:

   ```powershell
   docker compose -f docker-compose-wings-windows.yml up -d --force-recreate wings-init
   docker compose -f docker-compose-wings-windows.yml restart wings
   ```

   Ou edite `wings-config\config.yml` à mão e reinicie só o Wings: `docker compose -f docker-compose-wings-windows.yml restart wings`

### 5. Conectar nos jogos

- No **mesmo PC:** use **localhost:PORTA** (ex.: `localhost:27015` para CS2).
- Em **outro PC na rede:** use **IP_DO_PC:PORTA** (ex.: `192.168.1.10:27015`).

O painel mostra o endereço do servidor; se aparecer `host.docker.internal`, no mesmo Windows pode trocar por `localhost`.

---

## Resumo dos arquivos

| Arquivo | Uso |
|--------|-----|
| **docker-compose-wings-windows.yml** | Wings no Windows (bridge, portas expostas no Windows). |
| **docker-compose-wings.yml** | Wings no Linux (ou WSL2) com `network_mode: host`. |
| **wings-config/config.yml** | Config do Wings (api.host, api.key, system.token). |
| **wings-data/** | Dados e arquivos dos servidores de jogo. |

---

## Se der problema

- **“network pterodactyl_net not found”**  
  Esse erro não deve mais aparecer: o compose do Wings no Windows passou a usar rede própria (wings_net). Atualize o arquivo e rode o compose de novo.

- **Wings não conecta no painel**  
  Confira **api.host** = `http://host.docker.internal` (ou com `:80` se precisar) e **api.key** igual à Node API Key do painel. Reinicie o Wings após mudar o config.

- **"jwt: HMAC key is empty" / panic no Wings**  
  O **system.token** do config está vazio. O Wings exige um token não vazio. Pegue o **System Token** em **Admin → Nodes → [seu node] → Configuration** (detalhes em [onde-system-token.md](onde-system-token.md)), coloque no **.env** como `WINGS_SYSTEM_TOKEN=seu_token` e regenere o config (e reinicie o Wings):

  ```powershell
  docker compose -f docker-compose-wings-windows.yml up -d --force-recreate wings-init
  docker compose -f docker-compose-wings-windows.yml restart wings
  ```

  Ou edite **wings-config\config.yml** e defina `system.token` com o valor do painel; depois `docker compose ... restart wings`.

- **Não consigo conectar no jogo**  
  Confirme que a porta do servidor (ex.: 27015) está em **Allocations** do node e que você está usando **localhost:27015** (ou o IP do PC) no cliente do jogo.

- **Erro de permissão ou /var/lib/docker/containers**  
  No Windows não montamos `/var/lib/docker/containers`; em alguns casos o Wings pode reclamar de logs. Se for crítico, use a solução com WSL2: [wings-windows.md](wings-windows.md).
