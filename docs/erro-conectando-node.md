# Erro: "Error connecting to node!" / ícone de coração no status

Esse aviso (ou o **coração vermelho** no status do node) aparece quando o **painel** não consegue se comunicar com o **Wings**.

**→ Para resolver de uma vez:** siga o guia **[Node verde de uma vez](node-verde-definitivo.md)** (passo a passo completo: token, HTTP, FQDN e config do Wings).

---

## 1. Wings está rodando?

No PowerShell:

```powershell
docker ps
```

Deve existir o container **wings** com status **Up**. Se não estiver:

```powershell
docker compose -f docker-compose-wings-windows.yml up -d
docker compose -f docker-compose-wings-windows.yml logs wings --tail 30
```

Se o Wings estiver em crash (Exit 1), veja o log completo e corrija o que aparecer (ex.: panic, config inválido).

---

## 2a. Node continua vermelho mesmo com FQDN e porta corretos (token 403)

Se a conexão até o Wings funciona (por exemplo `curl` do painel para `wings:8080` retorna 401/403), mas o ícone do node continua vermelho, o painel e o Wings podem estar com **tokens diferentes** (o painel recebe 403 ao checar o daemon).

**Solução: usar exatamente o config gerado pelo painel e corrigir só o que quebra no Windows**

1. No painel: **Admin** → **Nodes** → clique no node → aba **Configuration**.
2. Clique em **Generate Token** (ou use o bloco de código já exibido) e **copie o config inteiro** que aparece.
3. Cole em **wings-config/config.yml** (substituindo todo o conteúdo).
4. No **config.yml**, altere **só** a linha de `api:` para o daemon escutar em todas as interfaces (senão o Wings pode não subir no Windows):
   - Troque `api.host` de `http://panel` (ou o que estiver) para **`0.0.0.0`**.
   - Mantenha `api.port: 8080`.
5. No final do **config.yml**, deixe **`ignore_panel_config_updates: true`** (assim o Wings não sobrescreve token/uuid com o que o painel envia).
6. Salve, reinicie o Wings:
   ```powershell
   docker compose -f docker-compose-wings-windows.yml -f docker-compose-wings-windows-internal.yml restart wings
   ```
7. No painel, no **mesmo node**: **FQDN** = **172.30.0.5** (ou `wings`), **Daemon Port** = **8080**, **Use HTTP Connection** → Salve.
8. Atualize a página **Admin** → **Nodes** (F5).

---

## 2. Configuração do node no painel

No painel: **Admin** → **Nodes** → clique no node **cs2** e confira:

| Campo | Deve estar |
|-------|------------|
| **FQDN** | `host.docker.internal` **ou** `wings` (veja abaixo) |
| **Daemon Port** | `8080` |
| **Communicate Over SSL** | **Use HTTP Connection** (não use SSL no ambiente local) |

Se estiver em "Use SSL Connection", mude para **Use HTTP Connection** e salve.

**Se ainda aparecer coração/erro:** use **FQDN = `wings`** (em vez de `host.docker.internal`). Isso funciona quando o Wings está na **mesma rede** do painel: suba o Wings com **force-recreate** para anexá-lo à rede do painel:

```powershell
docker compose -f docker-compose-wings-windows.yml -f docker-compose-wings-windows-internal.yml up -d --force-recreate wings
```

Depois, no painel: edite o node → **FQDN** = **wings**, **Daemon Port** = **8080**, **Use HTTP Connection** → salve.

**Se mesmo assim não ficar verde:** use o **IP do container Wings** como FQDN. Descubra o IP na rede do painel:

```powershell
docker network inspect pterodactyl_net --format "{{range .Containers}}{{if eq .Name \"wings\"}}{{.IPv4Address}}{{end}}{{end}}"
```

(O resultado é algo como `172.30.0.5/16` — use só a parte antes da barra, ex.: **172.30.0.5**.) No painel, edite o node → **FQDN** = **172.30.0.5**, **Daemon Port** = **8080**, **Use HTTP Connection** → salve. Atualize a página de nodes (F5).

**Importante:** O painel verifica o node pelo **navegador** (JavaScript). Por isso o FQDN tem de ser um endereço que o **seu PC** alcance. Se você colocou o **IP do container** (ex.: 172.30.0.5), o navegador **não** consegue acessar (é IP interno do Docker). Nesse caso use **FQDN = localhost** (ou **127.0.0.1**) e **porta 8080** — o Wings está exposto em `localhost:8080` no Windows. No painel: edite o node → **FQDN** = **localhost**, **Daemon Port** = **8080**, **Use HTTP Connection** → Salve. Atualize a página de nodes (F5).

**Erro "The fqdn could not be resolved to a valid IP address"**  
O painel valida o FQDN resolvendo o nome para IP. Use FQDN `wings` só depois de subir o Wings com o override interno (e `--force-recreate`), ou use o **IP do container** (ex.: 172.30.0.5) ou o **IP do seu PC** (ipconfig) como FQDN, porta **8080**, **Use HTTP Connection**.

---

## 2b. Console do servidor abre com porta errada (ex.: ws://127.0.0.1:8888 em vez de 8080)

Se o **node está verde** e o banco está certo, mas ao abrir o **Console** do servidor o navegador tenta **ws://127.0.0.1:8888** (ou outra porta) em vez de **8080**, quase sempre é **cache do frontend**.

**Passos:**

1. **Confirmar no banco** que o node está com porta 8080:
   ```powershell
   docker exec cs2-csgo-database-1 sh -c "mysql -upterodactyl -ppanel123 panel -e 'SELECT id, fqdn, daemonListen FROM nodes'"
   ```
   Deve aparecer `daemonListen = 8080`. Se aparecer 8888 (ou outro), corrija:
   ```powershell
   docker exec cs2-csgo-database-1 sh -c "mysql -upterodactyl -ppanel123 panel -e \"UPDATE nodes SET daemonListen=8080 WHERE id=6\""
   ```

2. **Limpar cache do site**  
   No navegador: F12 → **Application** (ou **Aplicativo**) → **Storage** → **Clear site data** (ou limpar **Local storage** + **Session storage**). Ou use uma **janela anónima/privada** e aceda de novo ao painel.

3. **Confirmar a URL que o frontend usa**  
   F12 → aba **Network** → filtrar por **WS** (WebSocket). Abra o **Console** do servidor no painel. Veja qual URL aparece no pedido WebSocket. Se for **8080**, o problema era cache; se ainda for **8888**, anote e verifique se acede ao painel por **http://localhost:8888** (por exemplo, NPM ou outro proxy). Nesse caso, o frontend pode estar a usar a porta da página; o correto é vir da API (node), então confirme de novo o node no painel: **Admin** → **Nodes** → **Daemon Port** = **8080** e salve.

4. **Reinício do painel** (opcional)  
   Às vezes o painel cacheia respostas. Reinicie o container do painel e teste de novo em janela anónima.

---

## 2c. WebSocket para host.docker.internal falha ("We're having some trouble connecting")

Se o node está com **FQDN = host.docker.internal** (para o painel conseguir fazer Reinstall) e o **Console** no browser mostra "having trouble connecting" e no F12 aparece **WebSocket connection to "ws://host.docker.internal:8080/..." failed**, o browser no Windows não está a conseguir resolver ou ligar a `host.docker.internal`.

**Solução A – Fazer o Windows resolver host.docker.internal (recomendado)**

1. Abre o **Bloco de notas** **como Administrador** (botão direito → "Executar como administrador").
2. Ficheiro → Abrir → navega para `C:\Windows\System32\drivers\etc` → em "Ficheiros" escolhe **Todos os ficheiros** → abre o ficheiro **hosts**.
3. No final do ficheiro, adiciona uma linha:
   ```
   127.0.0.1 host.docker.internal
   ```
4. Grava o ficheiro e fecha.
5. No browser, atualiza a página do Console (F5) ou abre de novo o servidor **csgo** → **Console**.

Assim o browser passa a resolver `host.docker.internal` para 127.0.0.1 e o WebSocket liga ao Wings na porta 8080. O Reinstall continua a funcionar porque o painel (dentro do Docker) também usa host.docker.internal.

**Solução B – Usar 127.0.0.1 no node (Console OK, Reinstall pelo painel falha)**

Se não quiseres alterar o ficheiro hosts, podes pôr o FQDN do node em **127.0.0.1**. O Console no browser passa a funcionar. O **Reinstall** pelo painel deixa de funcionar (o painel não consegue alcançar 127.0.0.1:8080 a partir do container). Nesse caso, para reinstalar, usa o script de diagnóstico (ver documentação) ou coloca temporariamente o Wings na rede do painel e FQDN **wings** só para fazer o Reinstall.

---

## 3. Testar a porta 8080 no Windows

No PowerShell:

```powershell
curl http://localhost:8080
```

Ou abra no navegador: **http://localhost:8080**. Não precisa retornar uma página bonita; pode dar erro de “not found” ou resposta em JSON. O importante é **não** dar “connection refused” ou timeout. Se der **connection refused**, **timeout** ou **ERR_EMPTY_RESPONSE** ("Nenhum dado foi enviado"), o Wings não está acessível na 8080. Siga o [diagnóstico abaixo](#quando-localhost8080-nao-responde).

---

### Quando localhost:8080 não responde (ERR_EMPTY_RESPONSE)

Se o navegador mostra "Esta página não está funcionando" / "Nenhum dado foi enviado" / **ERR_EMPTY_RESPONSE**, faça na ordem:

**A) Container está de pé?**

```powershell
docker ps -a
```

Procure o container **wings**. Se estiver **Exited** ou não aparecer, suba e veja o log:

```powershell
cd C:\Users\rodri\OneDrive\Desktop\cs2-csgo
docker compose -f docker-compose-wings-windows.yml up -d
docker compose -f docker-compose-wings-windows.yml logs wings --tail 50
```

Se no log aparecer **panic**, erro de **config** ou **permission denied** no Docker socket, corrija o indicado (ex.: `token` no config).

**B) Outro programa está usando a 8080?**

```powershell
netstat -ano | findstr :8080
```

Se aparecer **LISTENING** e o PID não for do Docker, outro processo está na porta. Feche-o ou mude a porta no compose (ex.: `"8081:8080"`) e no painel use 8081.

**B2) localhost vs 127.0.0.1 (Windows + WSL)**  
Se aparecer **dois** PIDs na 8080 (ex.: `com.docker.backend.exe` e `wslrelay.exe`), ao acessar **localhost:8080** o Windows pode usar IPv6 (`::1`) e a conexão ir para o **wslrelay**, que não responde HTTP → ERR_EMPTY_RESPONSE. **Teste no navegador com http://127.0.0.1:8080** (IPv4); a resposta deve vir do Wings. O painel (dentro do Docker) usa `host.docker.internal`, que normalmente resolve para IPv4, então o node pode continuar funcionando.

**C) Reiniciar Wings e Docker Desktop**

Reinicie o container e acompanhe o log:

```powershell
docker compose -f docker-compose-wings-windows.yml restart wings
docker compose -f docker-compose-wings-windows.yml logs wings -f
```

Se ainda não responder, feche os containers, **reinicie o Docker Desktop** (ícone na bandeja) e suba de novo:

```powershell
docker compose -f docker-compose-wings-windows.yml down
docker compose -f docker-compose-wings-windows.yml up -d
```

Teste de novo **http://localhost:8080**.

---

## 4. Console do navegador

Abra as **Ferramentas do desenvolvedor** (F12) → aba **Console**. Recarregue a página do painel e clique de novo no node. Veja se aparece algum erro em vermelho (CORS, net::ERR_, 401, etc.) e anote a mensagem exata. Isso ajuda a saber se o problema é rede, CORS ou autenticação.

---

## 5. Se o node estiver em outra máquina

Se o painel roda em um PC e o Wings em outro, o **FQDN** do node deve ser o **IP ou hostname** do PC onde o Wings está (ex.: `192.168.1.10`), e a porta **8080** deve estar liberada no firewall desse PC.

---

## Resumo rápido

1. **Wings no ar:** `docker ps` → container wings **Up**.
2. **Node no painel:** FQDN `host.docker.internal`, porta `8080`, **HTTP** (não SSL).
3. **Porta 8080 aberta:** `curl http://localhost:8080` ou navegador em `http://localhost:8080`.
4. **Console (F12):** ver a mensagem exata do erro.

Na maioria dos casos o problema é **SSL marcado** no node (trocar para HTTP) ou **Wings parado** (subir/reiniciar o container).
