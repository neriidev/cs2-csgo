# Guia: criar e configurar um Node no painel (Wings no Windows)

Este guia explica cada campo da tela **Admin → Nodes → Create Node** quando o Wings está rodando no Docker no Windows (modo bridge, `docker-compose-wings-windows.yml`).

---

## Antes de abrir o formulário

1. **Wings no ar:**  
   `docker compose -f docker-compose-wings-windows.yml up -d`
2. **config.yml do Wings** já criado em `wings-config/config.yml` (você vai preencher **api.key** depois de criar o node).

---

## Basic Details (coluna esquerda)

| Campo | O que colocar | Observação |
|-------|----------------|------------|
| **Name** | Ex.: `cs2`, `Windows`, `Local` | Só letras, números, `_`, `-`, `.` e espaço. Identifica o node no painel. |
| **Description** | Opcional | Ex.: "Node local Docker Windows". |
| **Location** | Escolha uma (ex.: `sa`) | Se não tiver, crie em **Admin → Locations** antes. |
| **Node Visibility** | **Public** ou **Private** | **Public**: qualquer um pode criar servidor neste node (se tiver permissão). **Private**: só você escolhe quem usa. Para teste local, **Public** é mais simples. |
| **FQDN** | **host.docker.internal** | É o “host” do Docker no Windows. O painel e os clientes usam esse nome (ou o IP do seu PC) para falar com o Wings. |
| **Communicate Over SSL** | **Use HTTP Connection** | No ambiente local com `host.docker.internal` não usamos SSL no Wings. Marque **Use HTTP Connection**. Se deixar SSL, o painel tenta HTTPS e pode falhar. |
| **Behind Proxy** | **Not Behind Proxy** | Deixe assim no ambiente local. Só mude se o Wings estiver atrás de Cloudflare etc. |

---

## Configuration (coluna direita)

| Campo | O que colocar | Observação |
|-------|----------------|------------|
| **Daemon Server File Directory** | **/var/lib/pterodactyl/volumes** | Deixe exatamente assim. No container do Wings esse caminho é mapeado para `wings-data/volumes` no seu projeto. |
| **Total Memory** | Ex.: **5000** (MiB) | Quanto de RAM o node “tem” no total para servidores. Ajuste conforme a RAM do seu PC (ex.: 4096, 8192). |
| **Memory Over-Allocation** | **0** ou **-1** | **0**: não deixa criar servidores se passar do total. **-1**: desliga a checagem (útil em teste). **%**: permite “overcommit” (ex.: 150). |
| **Total Disk Space** | Ex.: **10000** ou mais (MiB) | Espaço em disco que o node oferece para servidores. 10000 = ~10 GB. Ajuste conforme o disco. |
| **Disk Over-Allocation** | **0** ou **-1** | Mesma ideia da memória. **0** = não passar do total; **-1** = não verificar. |
| **Daemon Port** | **8080** | Porta do daemon do Wings. Tem que ser a mesma publicada no `docker-compose-wings-windows.yml` (8080:8080). |
| **Daemon SFTP Port** | **2022** | Porta do SFTP do Wings (acesso a arquivos do servidor). Também está publicada no compose (2022:2022). Não use a porta 22 do SSH do Windows. |

---

## Resumo recomendado para o seu caso (Wings no Windows)

- **Name:** `cs2` (ou outro nome que preferir)  
- **FQDN:** `host.docker.internal`  
- **Communicate Over SSL:** **Use HTTP Connection**  
- **Behind Proxy:** **Not Behind Proxy**  
- **Daemon Server File Directory:** `/var/lib/pterodactyl/volumes`  
- **Daemon Port:** `8080`  
- **Daemon SFTP Port:** `2022`  
- **Total Memory:** ex. `5000` (MiB)  
- **Total Disk Space:** ex. `10000` (MiB) ou mais  
- **Memory / Disk Over-Allocation:** `0` ou `-1` (conforme preferir)

Depois clique em **Create Node**.

---

## Depois de criar o node

1. Na tela do node criado, copie a **Node API Key** (começa com `ptla_`).
2. Abra **wings-config\config.yml** e cole essa chave em **api.key**.
3. Reinicie o Wings:
   ```powershell
   docker compose -f docker-compose-wings-windows.yml restart wings
   ```
4. No painel, em **Admin → Nodes → [seu node] → Allocations**, adicione as portas que os jogos vão usar (ex.: 27015–27030 para CS2). Assim você pode criar servidores nesse node.

---

## Erros comuns

- **Painel não conecta no Wings**  
  Confira: FQDN = `host.docker.internal`, Daemon Port = `8080`, **Use HTTP Connection** (não SSL). Veja os logs do Wings:  
  `docker compose -f docker-compose-wings-windows.yml logs -f wings`

- **SFTP não conecta**  
  Confirme que no compose está `2022:2022` e que no formulário **Daemon SFTP Port** = `2022`. No cliente SFTP use `host.docker.internal` (ou IP do PC) e porta `2022`.

- **Não consigo criar servidor / “no allocations”**  
  Vá em **Admin → Nodes → [seu node] → Allocations** e adicione portas (ex.: 27015, 27016, …). Depois, ao criar o servidor, escolha esse node e uma alocação livre.  
  Próximos passos para subir um servidor CS2: **[subir-servidor-cs2.md](subir-servidor-cs2.md)**.

Se quiser, na próxima etapa podemos preencher juntos o **config.yml** do Wings (api.host, system.token e allowed_origins) com base no seu painel.
