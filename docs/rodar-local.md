# Rodar e testar localmente (Windows)

## Em outro PC (clone/cópia do projeto)

No **novo computador**:

1. **Configurar variáveis** (uma vez):
   ```powershell
   .\scripts\setup-env.ps1
   ```
   O script cria `.env` e `var/.env` e pede a senha do banco (ou Enter para `panel123`).

2. **Subir os containers**:
   ```powershell
   docker compose -f docker-compose-painel.yml up -d
   ```
   O compose **constrói** a imagem do painel (pasta `panel/`, com cliente MySQL) na primeira vez. O banco inicializa sozinho; não é preciso rodar o `panel-init-db.ps1`.

3. Abrir **http://localhost** e criar a primeira conta.

Resumo: em qualquer PC novo você roda **setup-env.ps1** uma vez e depois **docker compose up -d**. Nada mais.

---

## 1. Criar o arquivo `.env` na raiz do projeto

Na pasta `cs2-csgo`, crie um arquivo chamado **`.env`** (na mesma pasta do `docker-compose-painel.yml`) com o seguinte conteúdo, **trocando as senhas** por algo seguro:

```env
MYSQL_ROOT_PASSWORD=SenhaRoot123
MYSQL_PASSWORD=SenhaPanel123

APP_URL=http://localhost
APP_SERVICE_AUTHOR=admin@localhost
```

- `MYSQL_ROOT_PASSWORD` e `MYSQL_PASSWORD` são **obrigatórios** (escolha senhas fortes).
- Para teste local, `APP_URL=http://localhost` está correto.

## 2. Subir o painel

Abra o **PowerShell** ou **Prompt de Comando** na pasta do projeto e rode:

```powershell
cd C:\Users\rodri\OneDrive\Desktop\cs2-csgo

docker compose -f docker-compose-painel.yml up -d
```

Aguarde os containers subirem (database, redis, panel). Na primeira vez pode demorar um pouco para baixar as imagens.

## 3. Verificar se está no ar

- Abra o navegador em: **http://localhost**
- Você deve ver a tela do Pterodactyl (registro ou login).

## 4. Primeiro acesso

1. **Crie a conta de administrador** (primeiro usuário vira admin).
2. Depois faça login e explore: **Admin** → Configuration, Nodes, Nests, etc.

## 5. Parar os containers

```powershell
docker compose -f docker-compose-painel.yml down
```

Para parar e **remover os dados do banco** (começar do zero):

```powershell
docker compose -f docker-compose-painel.yml down -v
```

E apague a pasta `db` se existir: `Remove-Item -Recurse -Force db`

**Se você resetou o banco** (apagou a pasta `db` e subiu de novo), basta dar `up -d` de novo. A imagem do painel (construída em `panel/`) já inclui o cliente MySQL e o banco volta a ser criado/migrado sozinho.

---

## Sobre o Wings (servidores de jogo)

O **Wings** usa `network_mode: host` no Linux; no **Windows** com Docker Desktop isso não funciona. Para rodar servidores de jogo no seu PC você pode:

- **Opção A:** Rodar o Wings **no Docker do Windows em modo bridge** (sem host) – portas expostas no Windows. Use `docker-compose-wings-windows.yml` e o guia **[docs/wings-docker-windows.md](wings-docker-windows.md)**.
- **Opção B:** Usar **WSL2** e rodar o Wings dentro do Linux. Passo a passo: **[docs/wings-windows.md](wings-windows.md)**.
- **Opção C:** Uma máquina ou VM **Linux** com Docker – use o `docker-compose-wings.yml` e o `pterodactyl/config.yml` lá.
- **Opção B:** WSL2 com Docker dentro do WSL (configuração mais avançada).

Para **só testar o painel** (criar usuários, nodes, configuração), rodar o painel local como acima já basta.

## Problemas comuns

- **"Defina MYSQL_PASSWORD no arquivo .env"**  
  O arquivo `.env` está na raiz do projeto (junto de `docker-compose-painel.yml`)? Tem as linhas `MYSQL_PASSWORD=...` e `MYSQL_ROOT_PASSWORD=...`?

- **Porta 80 em uso**  
  Outro programa (IIS, Skype, outro container) está usando a porta 80. Pare o outro serviço ou altere no `docker-compose-painel.yml` para algo como `"8080:80"` e acesse **http://localhost:8080**.

- **Painel em branco ou 500**  
  Veja os logs:  
  `docker compose -f docker-compose-painel.yml logs panel`  
  e a pasta `logs/` no projeto.

- **Só aparece tela de login (sem opção de Registrar)**  
  O registro pode estar desativado. Crie o primeiro usuário **admin** pelo terminal (troque email e senha se quiser):
  ```powershell
  docker compose -f docker-compose-painel.yml exec panel php artisan p:user:make --email=admin@localhost --username=admin --name-first=Admin --name-last=Local --password=admin123 --admin=1
  ```
  Depois faça login com esse **email** e **senha**. Dentro do painel, em **Admin → Configuration**, você pode habilitar o registro de novos usuários se quiser.

- **"Access denied for user 'pterodactyl'"**  
  A senha do banco não bate com a do painel. Confira: **raiz do projeto** `.env` tem `MYSQL_PASSWORD=...` e **var/.env** tem `DB_PASSWORD=...` com o **mesmo valor**. Se o banco foi criado antes com outra senha, recrie o banco: `docker compose -f docker-compose-painel.yml down`, apague a pasta `db`, depois `up -d` e rode o script **scripts/panel-init-db.ps1** (veja abaixo).

- **"mysql: not found" ao subir o painel**  
  Só ocorre se você estiver usando a imagem **oficial** (`ghcr.io/pterodactyl/panel:latest`) em vez da imagem local. Use o compose deste projeto, que **constrói** a imagem em `panel/` (com cliente MySQL). Não use `image: ghcr.io/pterodactyl/panel:latest` no lugar de `build: ./panel`.
