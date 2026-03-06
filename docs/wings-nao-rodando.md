# Wings não está rodando – checklist (Windows)

Siga na ordem. Depois de cada passo, tente de novo: `docker compose -f docker-compose-wings-windows.yml up -d`.

**Documentação oficial do Wings:** [Installing Wings](https://pterodactyl.io/wings/1.0/installing.html). O Pterodactyl **não suporta Windows** como sistema do Wings; aqui rodamos o Wings **dentro de um container Linux** no Docker Desktop, o que costuma funcionar para desenvolvimento local.

## 1. Rede (não é mais necessário)

O compose do Wings no Windows **não** usa mais a rede externa **pterodactyl_net**. Ele usa uma rede própria (**wings_net**), então você **não** precisa subir o painel antes só por causa da rede. Suba o Wings quando quiser:

```powershell
docker compose -f docker-compose-wings-windows.yml up -d
```

(O painel ainda precisa estar no ar para o Wings **conectar** nele; mas não para o compose do Wings subir.)

---

## 2. Arquivo de config do Wings

**Opção automática:** rode o script (cria pastas, copia e preenche o que der):

```powershell
.\scripts\setup-wings-windows.ps1
```

Ele pede (opcional) a **Node API Key** e o **System Token**; se colar, já deixa o config pronto. Se pular, edite depois o `wings-config\config.yml`.

**Opção manual:** crie as pastas, copie o exemplo e edite:

```powershell
# Criar pastas
mkdir wings-config, wings-data\volumes, wings-data\tmp -Force

# Copiar exemplo e editar
copy pterodactyl\config.yml.example wings-config\config.yml
notepad wings-config\config.yml
```

No **wings-config/config.yml** ajuste pelo menos:

- **api.host** – URL do painel. Para painel em localhost no Windows use:  
  `http://host.docker.internal`  
  ou `http://host.docker.internal:80`
- **api.key** – Node API Key do painel (Admin → Nodes → [seu node] → copie a chave).
- **system.token** – Token do painel. Onde achar: **[Onde achar System Token](onde-system-token.md)** (Admin → Nodes → [seu node] → Configuration).
- **api.ssl.verify** – use `false` se o painel for HTTP (localhost).
- **allowed_origins** – inclua `http://localhost` e `http://host.docker.internal`.

Salve o arquivo e feche o Notepad.

---

## 3. Subir o Wings

Na pasta do projeto (onde está o docker-compose-wings-windows.yml):

```powershell
cd C:\Users\rodri\OneDrive\Desktop\cs2-csgo

docker compose -f docker-compose-wings-windows.yml up -d
```

---

## 4. Se der erro, veja a mensagem

**“network pterodactyl_net not found”**  
→ Esse erro não deve mais ocorrer (o compose usa rede própria). Se aparecer, atualize o docker-compose-wings-windows.yml.

**“panic: jwt: HMAC key is empty”**  
→ O **system.token** no config está vazio. Pegue o token em **Admin → Nodes → [seu node] → Configuration** (veja [onde-system-token.md](onde-system-token.md)), coloque no .env como `WINGS_SYSTEM_TOKEN=seu_token`, depois: `docker compose -f docker-compose-wings-windows.yml up -d --force-recreate wings-init` e `docker compose ... restart wings`. Ou edite **wings-config\config.yml** e preencha `system.token`.

**“config not found” / “no such file”**  
→ Confirme que existe o arquivo `wings-config\config.yml` (e não só `config.yml.example`).

**"The Authorization header provided was not in a valid format"** (HTTP 400)  
O painel espera **Bearer token_id.token** (dois campos). No **wings-config/config.yml** coloque na **raiz** do YAML: **token_id** e **token**, com os valores da aba **Configuration** do node (Admin → Nodes → [seu node] → Configuration). Veja [onde-system-token.md](onde-system-token.md).

**"Error response from daemon: invalid pool request: Pool overlaps with other one on this address space"**  
O Wings tenta criar a rede `pterodactyl_nw` e o Docker recusa por sobreposição de subnet. **Não use** a opção `interface` no config (no Windows o Wings pode não subir). Faça na ordem:

  1. **Pare o Wings e remova as redes antigas** do Pterodactyl:
  ```powershell
  docker compose -f docker-compose-wings-windows.yml stop wings
  docker network rm pterodactyl_nw 2>$null; docker network rm pterodactyl0 2>$null; docker network rm pterodactyl_net 2>$null
  ```

  2. **Crie a rede manualmente** com uma subnet que não conflite (ex.: 10.100.0.0/24). Assim o Wings usa a rede já existente e não tenta criar:
  ```powershell
  docker network create --subnet=10.100.0.0/24 pterodactyl_nw
  ```

  3. **Suba o Wings de novo** (com o mesmo compose que você usa, ex. com internal se for o caso):
  ```powershell
  docker compose -f docker-compose-wings-windows.yml -f docker-compose-wings-windows-internal.yml up -d
  ```
  Ou, se for só o Wings: `docker compose -f docker-compose-wings-windows.yml up -d`.

  4. Se ainda der "Pool overlaps", **ajuste o pool do Docker** no `daemon.json` (Docker Desktop: Settings → Docker Engine). Exemplo:
  ```json
  {
    "default-address-pools": [
      { "base": "10.10.0.0/16", "size": 24 },
      { "base": "192.168.0.0/16", "size": 24 }
    ]
  }
  ```
  Depois: **Apply & Restart**. Remova a rede que você criou (`docker network rm pterodactyl_nw`), então suba o Wings de novo para ele criar a rede sozinho.

**"unsupported protocol scheme """** (FATAL: failed to load server configurations)  
→ O Wings usa a chave **remote** no config como URL do painel (não só api.host). Em **wings-config/config.yml** adicione na raiz: **remote: "http://panel"** (ou "http://host.docker.internal"). Tem que começar com http:// ou https://. Reinicie o Wings.

**Container sobe e logo para (Exit 1)**  
→ Veja o log:

```powershell
docker compose -f docker-compose-wings-windows.yml logs wings
```

Erros comuns no log:
- **api.key invalid** → Coloque a Node API Key correta (Admin → Nodes → [seu node]).
- **connection refused** / **could not reach panel** → Confira **api.host** (`http://host.docker.internal`) e se o painel está no ar (`http://localhost` abre no navegador).
- **system.token** → Pegue em **Admin → Nodes → [seu node] → Configuration** (veja [onde-system-token.md](onde-system-token.md)) e coloque no config.

**Stack trace em `Manager.init` / manager.go:238 ("fetching list of servers from API")**  
O Wings falha ao buscar a lista de servidores na API do painel (início do [Manager.init](https://github.com/pterodactyl/wings/blob/develop/server/manager.go)). Em geral é **painel inacessível** ou **resposta inesperada** da API.

- **Painel no ar:** confira se o painel responde em `http://localhost` (ou na URL que você usa).
- **URL do painel no config:**  
  - Se você sobe **só** o compose do Wings (`docker-compose-wings-windows.yml`) e o painel está no **host** (localhost), use **`http://host.docker.internal`** em **`remote`** e **`api.host`**. O hostname **`panel`** só existe quando o Wings está na **mesma rede Docker** que o container do painel (ex.: mesmo compose ou rede externa compartilhada).  
  - Para usar **`http://panel`**: suba primeiro o painel (`docker compose -f docker-compose-painel.yml up -d`), depois o Wings **na rede do painel** com o override:  
    `docker compose -f docker-compose-wings-windows.yml -f docker-compose-wings-windows-internal.yml up -d`  
    (e no config: `remote` e `api.host` = `http://panel`). Veja o comentário em `docker-compose-wings-windows-internal.yml`.
- **Chaves:** confira **api.key**, **token_id** e **token** (system) iguais aos da aba **Configuration** do node no painel (veja [onde-system-token.md](onde-system-token.md)).
- **Timeout:** em **wings-config/config.yml** use a seção `remote_query:` com `timeout: 60` ou **120** e `boot_servers_per_page: 50`.
- Para ver o erro exato antes do panic: ponha **debug: true** no config, reinicie o Wings e veja o log:  
  `docker compose -f docker-compose-wings-windows.yml logs wings`

**Várias linhas "making request" a /api/remote/servers sem linha de sucesso**  
O painel está acessível (responde em segundos) mas o Wings não recebe 200. Na prática isso costuma ser **API key errada**: o painel devolve **401** e o Wings fica repetindo a requisição. **Solução:** No painel, **Admin** → **Nodes** → clique no node → em **Configuration** copie de novo a **Node API Key** (ou use “Regenerate” e copie a nova). Atualize em **wings-config/config.yml** o campo **api.key** com esse valor exato (e no **.env** em **WINGS_API_KEY**). Reinicie o Wings: `docker compose -f docker-compose-wings-windows.yml -f docker-compose-wings-windows-internal.yml restart wings`. Se a chave estiver correta, o Wings deve logar algo como “processing servers returned by the API” e subir.

---

## 5. Conferir se está rodando

```powershell
docker ps
```

Deve aparecer um container com nome **wings** e status **Up**.

```powershell
docker compose -f docker-compose-wings-windows.yml logs -f wings
```

Saia com Ctrl+C. Se aparecer algo como “listening” ou “registered”, o Wings está no ar. No painel, em **Admin → Nodes**, o node deve aparecer como **online** (verde).

---

## Resumo rápido

| Verificação | Comando / ação |
|-------------|-----------------|
| Rede existe | `docker network ls \| findstr pterodactyl` |
| config existe | Arquivo `wings-config\config.yml` (não só o .example) |
| api.host | `http://host.docker.internal` (painel em localhost) |
| api.key | Node API Key do painel |
| system.token | Admin → Nodes → [seu node] → Configuration. Veja [onde-system-token.md](onde-system-token.md) |
| Subir Wings | `docker compose -f docker-compose-wings-windows.yml up -d` |
| Logs | `docker compose -f docker-compose-wings-windows.yml logs wings` |

Se depois disso o Wings ainda não rodar, copie a **mensagem de erro** (do terminal ou do `logs wings`) e use para procurar a solução ou perguntar de novo com o erro exato.
