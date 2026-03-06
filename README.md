# Painel Pterodactyl + Wings (servidores de jogos)

## Primeira vez ou em outro PC

1. **Configurar variáveis** (uma vez):
   ```powershell
   .\scripts\setup-env.ps1
   ```
   O script cria `.env` e `var/.env` a partir dos exemplos e pede a senha do banco (ou use Enter para `panel123`).

2. **Subir o painel**:
   ```powershell
   docker compose -f docker-compose-painel.yml up -d
   ```
   Na primeira vez o compose **constrói** a imagem do painel (com cliente MySQL) e sobe os containers. O banco inicializa sozinho; não é preciso rodar nenhum script extra.

3. Acesse **http://localhost** e crie a primeira conta.

Se preferir fazer à mão: copie `.env.example` → `.env` e `var/.env.example` → `var/.env`, defina `MYSQL_PASSWORD` e `MYSQL_ROOT_PASSWORD` no `.env` e o **mesmo** valor em `DB_PASSWORD` no `var/.env`. Depois `docker compose -f docker-compose-painel.yml up -d`.

**Wings (servidores de jogo) no Windows:** o Wings precisa de Linux para `network_mode: host`. No Windows você pode:
- **Opção A:** Rodar o Wings em **modo bridge** no Docker Desktop – [docs/wings-docker-windows.md](docs/wings-docker-windows.md) (sem WSL2).
- **Opção B:** Usar **WSL2** e rodar o Wings dentro do Linux – [docs/wings-windows.md](docs/wings-windows.md).

**Subir servidor CS2:** depois do node configurado, use [docs/subir-servidor-cs2.md](docs/subir-servidor-cs2.md).

Guia completo: [docs/rodar-local.md](docs/rodar-local.md).  
Performance e evitar timeout: [docs/performance-timeout.md](docs/performance-timeout.md).  
Planejamento: [PLANO-SISTEMA.md](PLANO-SISTEMA.md).
