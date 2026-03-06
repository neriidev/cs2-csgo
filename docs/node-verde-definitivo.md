# Node verde de uma vez – passo a passo definitivo (Windows + Docker)

Quando o node fica vermelho mesmo com Wings rodando e FQDN correto, o painel e o Wings costumam estar com **token ou esquema (HTTP/HTTPS) diferentes**. Siga **exatamente** esta ordem.

---

## Pré-requisitos

- Painel no ar: `docker compose -f docker-compose-painel.yml up -d`
- Wings na **mesma rede** do painel (compose interno)

---

## Passo 1 – Wings na rede do painel e IP

No PowerShell, na pasta do projeto:

```powershell
docker compose -f docker-compose-wings-windows.yml -f docker-compose-wings-windows-internal.yml up -d --force-recreate wings
```

Aguarde ~10 segundos e pegue o IP do Wings:

```powershell
docker network inspect pterodactyl_net --format "{{range .Containers}}{{if eq .Name \"wings\"}}{{.IPv4Address}}{{end}}{{end}}"
```

Anote o IP **sem** a máscara (ex.: `172.30.0.5`).

---

## Passo 2 – No painel: node com HTTP e FQDN correto

1. **Admin** → **Nodes** → clique no node (ou crie um novo).
2. Na **primeira aba** (Settings / General):
   - **FQDN:** use o IP do passo 1 **só se** a verificação do node for feita pelo **servidor** (backend).  
     Se o ícone do node ficar vermelho e no F12 (Network) a requisição for para `http://172.30.0.5:8080/api/system`, o pedido está saindo do **navegador**; o IP 172.30.0.5 não é acessível pelo PC. Nesse caso use **FQDN = localhost** (ou **127.0.0.1**), pois o Wings está em `localhost:8080` no Windows.
   - **Daemon Port:** `8080`.
   - **Communicate Over SSL:** marque **Use HTTP Connection** (não use SSL).
3. Clique em **Save** (ou **Update**).  
   Isso grava no banco **scheme = http** e o FQDN/porta.

---

## Passo 3 – Gerar token e copiar o config

1. No **mesmo node**, abra a aba **Configuration**.
2. Clique em **Generate Token**.  
   O painel gera um novo token e **grava no banco**.
3. **Sem sair da página**, copie **todo** o bloco de código YAML que aparecer (config do Wings).
4. **(Opcional mas recomendado)** Volte na primeira aba do node e clique em **Save** de novo.  
   Assim você garante que FQDN, porta e HTTP estão salvos junto com o token.

---

## Passo 4 – Colar no Wings e ajustar para Windows

1. Abra **wings-config/config.yml** no editor.
2. **Apague todo** o conteúdo e cole o config que você copiou do painel.
3. Faça **só** estes ajustes (o resto deixe como veio):

   - **api.host**  
     Troque o valor (por exemplo `http://panel` ou URL) para:
     ```yaml
     api:
       host: 0.0.0.0
       port: 8080
     ```
   - **api.ssl**  
     Se existir `cert` e `key` com caminhos, deixe vazio (Wings sem SSL):
     ```yaml
     ssl:
       enabled: false
       cert: ""
       key: ""
     ```
   - **remote** (obrigatório para Wings achar o painel na rede Docker)  
     Na raiz do YAML:
     ```yaml
     remote: "http://panel"
     ```
   - No **final** do arquivo, adicione (ou confira):
     ```yaml
     ignore_panel_config_updates: true
     ```

4. Salve o arquivo.

---

## Passo 5 – Reiniciar Wings e limpar cache do painel

No PowerShell:

```powershell
docker compose -f docker-compose-wings-windows.yml -f docker-compose-wings-windows-internal.yml restart wings
```

Aguarde ~10 segundos e limpe o cache do painel:

```powershell
docker exec cs2-csgo-panel-1 php /app/artisan config:clear
docker exec cs2-csgo-panel-1 php /app/artisan cache:clear
```

---

## Passo 6 – Ver o node verde

1. No painel, abra **Admin** → **Nodes**.
2. Atualize a página (F5).
3. O node deve aparecer **online** (ícone verde).

Se ainda estiver vermelho, espere 30–60 segundos e atualize de novo (o painel pode demorar para atualizar o status).

---

## Checklist rápido

| Onde | O quê |
|------|--------|
| Painel – aba do node | FQDN = IP do Wings (ex.: 172.30.0.5), Porta 8080, **Use HTTP Connection** → Save |
| Painel – Configuration | Generate Token → copiar todo o YAML |
| wings-config/config.yml | Colar o YAML, depois: `api.host: 0.0.0.0`, `remote: "http://panel"`, `ignore_panel_config_updates: true` |
| PowerShell | `docker compose ... restart wings` + `artisan config:clear` e `cache:clear` |
| Painel | Admin → Nodes → F5 |

---

## Se ainda ficar vermelho

- Confira no navegador (F12 → Console) se aparece erro ao abrir o node (CORS, rede, 403).
- Confira se **Communicate Over SSL** está em **Use HTTP Connection** (não SSL).
- Confira se o config do Wings tem **remote: "http://panel"** (não `http://localhost`).
- Veja também: [erro-conectando-node.md](erro-conectando-node.md).
