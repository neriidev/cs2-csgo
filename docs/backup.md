# Fase 4 – Backup

## O que fazer backup

- **MariaDB:** banco do painel (usuários, servidores, nodes, etc.)
- **Volumes do painel:** `./var/`, `./db/` (ou apenas dump do DB)
- **Dados dos jogos:** em cada host com Wings, `/var/lib/pterodactyl/volumes` (cada servidor tem sua pasta)

## Backup do banco (MariaDB)

Com o painel no ar:

```bash
docker compose -f docker-compose-painel.yml exec database mysqldump -u pterodactyl -p panel > backup-panel-$(date +%Y%m%d).sql
```

Ou usando a senha do `.env` (Linux/macOS):

```bash
source .env 2>/dev/null || true
docker compose -f docker-compose-painel.yml exec -T database mysqldump -u pterodactyl -p"${MYSQL_PASSWORD}" panel > backup-panel-$(date +%Y%m%d).sql
```

Guarde o `.sql` em um local seguro (outro disco, nuvem).

## Backup dos arquivos do painel

```bash
tar -czvf backup-painel-var-$(date +%Y%m%d).tar.gz var/
```

Inclui o `.env` e arquivos de configuração do Laravel.

## Backup dos servidores de jogo (Wings)

No **host** onde roda o Wings:

```bash
sudo tar -czvf backup-pterodactyl-volumes-$(date +%Y%m%d).tar.gz -C /var/lib/pterodactyl volumes
```

Restaurar: parar o Wings, descompactar em `/var/lib/pterodactyl/`, ajustar dono `988:988`, subir o Wings de novo.

## Automatização

Use **cron** (Linux) ou **Agendador de Tarefas** (Windows) para rodar os comandos de backup periodicamente (ex.: todo dia às 3h). Mantenha retenção (ex.: últimos 7 dias) e teste a restauração de um dump.
