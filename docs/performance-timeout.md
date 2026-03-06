# Performance e evitar timeout

Dicas para deixar o painel + Wings estáveis e sem erro de timeout.

---

## 1. Wings falando direto com o painel (recomendado)

Por padrão o Wings usa **host.docker.internal** para falar com o painel: a requisição sai do container → host Windows → de volta para o container do painel. Isso pode ser mais lento e sensível a timeout.

**Melhor:** Wings e painel na **mesma rede Docker**, com **api.host = http://panel**. A comunicação fica entre containers (mais rápida e estável).

### Como fazer

1. **Subir o painel primeiro** (para criar a rede `pterodactyl_net`):
   ```powershell
   docker compose -f docker-compose-painel.yml up -d
   ```

2. **No .env**, defina o host da API do Wings como o serviço do painel:
   ```env
   WINGS_API_HOST=http://panel
   ```

3. **Subir o Wings usando a rede do painel** (override):
   ```powershell
   docker compose -f docker-compose-wings-windows.yml -f docker-compose-wings-windows-internal.yml up -d
   ```

4. **Regenerar o config do Wings** (para pegar `api.host=http://panel`):
   ```powershell
   docker compose -f docker-compose-wings-windows.yml -f docker-compose-wings-windows-internal.yml up -d --force-recreate wings-init
   docker compose -f docker-compose-wings-windows.yml -f docker-compose-wings-windows-internal.yml restart wings
   ```

5. **No painel**, edite o node: **FQDN** = **wings** (não use host.docker.internal), **Daemon Port** = **8080**, **Use HTTP Connection**. Salve. O painel passa a acessar o daemon em `wings:8080` na rede interna.

Assim o Wings chama a API em **http://panel** (rede interna) e o painel chama o Wings em **host.docker.internal:8080**.

---

## 2. Config do Wings

Em **wings-config/config.yml** (e no template **pterodactyl/config.yml.template**):

| Opção | Valor | Motivo |
|-------|--------|--------|
| **remote_query.timeout** | **60** | Evita timeout quando o painel demora a responder. |
| **remote_query.boot_servers_per_page** | **50** | Padrão estável; não aumente muito. |
| **debug** | **false** em uso normal | Menos I/O e log; use **true** só para diagnosticar. |

Depois de alterar o config:
```powershell
docker compose -f docker-compose-wings-windows.yml restart wings
```

---

## 3. Painel (Laravel)

### Variáveis no .env

- **CACHE_DRIVER=redis** e **SESSION_DRIVER=redis** e **QUEUE_CONNECTION=redis** (já usados no compose).
- **APP_DEBUG=false** em uso normal (menos overhead).
- **APP_URL** igual à URL real do painel (evita redirects e problemas de CORS/cookie).

### Queue worker (filas)

O painel usa filas para tarefas pesadas. Se o **queue worker** não estiver rodando, algumas ações podem travar ou demorar.

Na imagem oficial do painel o worker não sobe sozinho. Opções:

- **Cron no host:** de 1 em 1 minuto rodar algo como:
  ```
  docker exec cs2-csgo-panel-1 php /app/artisan schedule:run
  ```
  (o schedule pode incluir `queue:work` com timeout, conforme a doc do Pterodactyl.)

- **Ou** subir um container extra que rode `php artisan queue:work` (ver documentação oficial do painel).

Ter Redis para filas já está correto; o que falta é um processo consumindo a fila.

### Banco (MariaDB)

- O compose já usa Redis para cache/session/queue; o MySQL fica para dados.
- Se o disco estiver lento, a pasta **db/** pode atrasar as queries; use um disco rápido.

---

## 4. Docker e recursos

- **Não** limite CPU/memória dos containers sem necessidade; falta de recurso gera lentidão e timeout.
- No **Docker Desktop**, em *Settings → Resources*, deixe memória e CPU suficientes para o painel + banco + Redis + Wings.
- Se o Wings e o painel estiverem na mesma rede (**http://panel**), a comunicação consome menos recurso e evita timeout.

---

## 5. Resumo rápido

| O quê | Ação |
|--------|------|
| Menos timeout Wings ↔ painel | Use **WINGS_API_HOST=http://panel** e suba o Wings com **docker-compose-wings-windows-internal.yml** (rede interna). |
| Timeout ao buscar servidores | **remote_query.timeout: 60** no config do Wings. |
| Log enxuto e estável | **debug: false** no Wings. |
| Painel responsivo | Redis para cache/session/queue; rodar queue worker (cron ou container). |
| Recursos | Não restringir CPU/memória dos containers; disco rápido para **db/** |

Guia de erro do node: [erro-conectando-node.md](erro-conectando-node.md). Wings não sobe: [wings-nao-rodando.md](wings-nao-rodando.md).
