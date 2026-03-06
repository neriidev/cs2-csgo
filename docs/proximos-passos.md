# Próximos passos – depois do config do Wings

Com o **wings-config/config.yml** preenchido (api.key e system.token), siga nesta ordem:

---

## 1. Subir o Wings (se ainda não estiver rodando)

```powershell
cd C:\Users\rodri\OneDrive\Desktop\cs2-csgo
docker compose -f docker-compose-wings-windows.yml up -d
```

Ver se está no ar:

```powershell
docker ps
docker compose -f docker-compose-wings-windows.yml logs wings --tail 30
```

---

## 2. No painel: conferir o node

1. Abra o painel (**http://localhost**).
2. **Admin** → **Nodes** → clique no seu node (ex.: **cs2**).
3. O node deve aparecer como **online** (indicador verde). Se estiver offline ou aparecer **"Error connecting to node!"**, siga o guia [erro-conectando-node.md](erro-conectando-node.md).

---

## 3. Alocações (portas para os jogos)

Sem alocações o node pode ficar **online** normalmente; o que falha é **criar servidor** neste node (não há porta para alocar). Timeout ao conectar o node não é causado por falta de allocation.

1. Com o node aberto, vá na aba **Allocations**.
2. **Create Allocation**.
3. Adicione pelo menos a porta **27015** (CS2). Ex.: IP em branco ou `0.0.0.0`, porta `27015`, ou range `27015-27020`.
4. Salve.

Sem alocações você não consegue criar servidor nesse node.

---

## 4. Criar o servidor CS2

1. No painel: **Servers** (ou **Dashboard**) → **Create Server**.
2. **Name:** ex. `Meu CS2`.
3. **Node:** escolha o seu node (ex.: cs2).
4. **Nest:** ex. **Source Engine** (ou o nest que tiver o egg CS2).
5. **Egg:** **Counter-Strike 2** (ou o egg que você importou).
6. **Memory:** ex. 2048 MiB. **Disk:** ex. 35000 MiB.
7. Na etapa **Allocation:** marque **Assign Port** e escolha uma alocação livre (ex.: **27015**).
8. **Create** / **Create Server**.

Aguarde a **instalação** (download dos arquivos do jogo). Pode demorar vários minutos.

---

## 5. Iniciar e conectar no jogo

1. Abra o servidor na lista → **Console** ou **Overview**.
2. Quando a instalação terminar, clique em **Start**.
3. No CS2 no seu PC: **Jogar** → **Comunidade** ou **Conectar** → use **localhost:27015** (ou a porta que você alocou). Ou no console do jogo: `connect localhost:27015`.

---

## Resumo rápido

| # | O quê |
|---|--------|
| 1 | `docker compose -f docker-compose-wings-windows.yml up -d` (Wings no ar) |
| 2 | Painel → Admin → Nodes → node deve estar **online** |
| 3 | Node → **Allocations** → criar porta **27015** (ou range) |
| 4 | **Servers** → **Create Server** → node, nest, egg CS2, alocação 27015 |
| 5 | Abrir o servidor → **Start** → no CS2: `connect localhost:27015` |

Guia detalhado do CS2: [subir-servidor-cs2.md](subir-servidor-cs2.md).
