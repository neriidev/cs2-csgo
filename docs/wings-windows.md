# Rodar Wings no Windows (WSL2)

O Wings usa **`network_mode: host`** para que as portas dos jogos fiquem direto no IP da máquina. No **Docker no Windows** isso não funciona como no Linux (o "host" seria a VM do Docker Desktop, não o seu PC).

A solução é rodar o **Wings dentro do WSL2**: aí você tem um Linux de verdade e o `network_mode: host` funciona. O painel pode continuar no Windows (Docker Desktop); o Wings fica no WSL2 e o painel se comunica com ele pela rede.

---

## Pré-requisitos

- Windows 10/11 com **WSL2** instalado.
- **Docker** instalado **dentro** do WSL2 (não use só o Docker Desktop para o Wings).

---

## 1. Instalar WSL2 e Ubuntu

No **PowerShell como Administrador**:

```powershell
wsl --install -d Ubuntu
```

Reinicie se pedir. Depois abra **Ubuntu** no menu Iniciar e conclua o primeiro uso (usuário e senha).

---

## 2. Instalar Docker dentro do WSL2 (Ubuntu)

Dentro do **Ubuntu (WSL2)**:

```bash
sudo apt update && sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker $USER
```

Feche e abra de novo o terminal do Ubuntu para o grupo `docker` valer. Teste:

```bash
docker run hello-world
```

---

## 3. Acessar o projeto no WSL2

Você pode usar a pasta do Windows de dentro do WSL2. No Ubuntu:

```bash
# Exemplo: seu projeto está em C:\Users\rodri\OneDrive\Desktop\cs2-csgo
# No WSL2 isso vira:
cd /mnt/c/Users/rodri/OneDrive/Desktop/cs2-csgo
```

Ou clone/copie o projeto para dentro do sistema de arquivos do Linux (mais estável para Docker):

```bash
mkdir -p ~/cs2-csgo
# Copie para cá o docker-compose-wings.yml e a pasta pterodactyl (com config.yml.example)
# Ou use o projeto já clonado em /mnt/c/... e só ajuste o caminho abaixo
```

---

## 4. Configurar o Wings no WSL2

O Wings precisa do arquivo **config.yml** no “host” (agora o Linux do WSL2).

**Criar diretórios e config:**

```bash
sudo mkdir -p /etc/pterodactyl /var/lib/pterodactyl/volumes /tmp/pterodactyl
sudo chown -R 988:988 /var/lib/pterodactyl /tmp/pterodactyl
```

**Criar o config** (troque pela URL do seu painel e pelas chaves geradas no painel):

```bash
sudo nano /etc/pterodactyl/config.yml
```

Conteúdo mínimo (ajuste `api.host`, `api.key`, `system.token` e `allowed_origins` conforme o painel):

```yaml
api:
  host: "http://SEU_IP_WINDOWS:80"   # ou https://painel.seudominio.com
  key: "ptla_xxxxxxxx"
  ssl:
    verify: false

system:
  token: "xxxxxxxx"
  data: "/var/lib/pterodactyl/volumes"

docker:
  network:
    name: "pterodactyl_nw"
  container_pid_limit: 512

allowed_origins:
  - "http://SEU_IP_WINDOWS:80"
  - "http://localhost"

debug: false
tmpfs_size: 100
app_name: "Pterodactyl"
```

Para **api.host** e **allowed_origins**:

- Se o painel está no **Windows** (Docker Desktop): use o IP do Windows na rede local (ex.: `192.168.1.10`) ou, se o painel estiver em localhost do Windows, use o IP do Windows para o WSL2 conseguir acessar (WSL2 não é “localhost” do Windows).
- Descobrir IP do Windows (no PowerShell): `ipconfig` e veja o IPv4 da sua rede.

**Onde pegar `api.key` e `system.token`:** no painel (Windows), **Admin** → **Nodes** → [seu node] → **Configuration** (ou **Admin** → **Configuration** → **Wings**).

---

## 5. Subir o Wings no WSL2

No **Ubuntu (WSL2)** na pasta onde está o `docker-compose-wings.yml`:

```bash
# Se estiver usando a pasta do Windows:
cd /mnt/c/Users/rodri/OneDrive/Desktop/cs2-csgo

docker compose -f docker-compose-wings.yml up -d
```

Ver logs:

```bash
docker compose -f docker-compose-wings.yml logs -f wings
```

---

## 6. Registrar o node no painel (Windows)

No **painel** (no navegador):

1. **Admin** → **Nodes** → **Create Node**.
2. **Name:** ex. `WSL2`.
3. **FQDN / IP:** use o **IP do WSL2** (no Ubuntu: `hostname -I | awk '{print $1}'` ou `ip addr show eth0`).
4. **Port:** `8080` (porta padrão do Wings).
5. Salve e anote a **Node API Key**; ela deve ser a mesma que você colocou em **api.key** no `config.yml` do WSL2 (ou atualize o `config.yml` com a chave que o painel mostrar).

Assim o painel (no Windows) passa a falar com o Wings (no WSL2) nesse IP e porta.

---

## 7. Conectar nos servidores de jogo

Os servidores criados no painel vão rodar no **WSL2**. Para jogar no mesmo PC:

- **Endereço do servidor:** use o **IP do WSL2** (o mesmo do node) e a **porta** que o painel mostrou para o servidor (ex.: 27015 para CS2).
- Em alguns setups, **localhost** no Windows pode redirecionar para o WSL2; pode testar `localhost:27015`. Se não funcionar, use o IP do WSL2.

Para outros PCs na rede, usem o **IP do Windows** na rede local e a mesma porta (desde que o firewall do Windows permita e que o tráfego seja encaminhado para o WSL2, se necessário).

---

## Resumo

| Onde roda   | O quê                          |
|------------|---------------------------------|
| Windows    | Painel (Docker Desktop), navegador |
| WSL2 (Ubuntu) | Wings + containers dos jogos (Docker no Linux) |

- **Painel** → acessa o **Wings** em `IP_WSL2:8080`.
- **Jogo (cliente)** → conecta em `IP_WSL2:porta_do_servidor` (ou IP do Windows/localhost, conforme rede/firewall).

Assim você “resolve” a limitação do Docker no Windows: o Wings roda em ambiente Linux (WSL2) e o `network_mode: host` passa a funcionar como no Linux.
