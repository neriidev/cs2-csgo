#!/bin/bash
# Backup do painel Pterodactyl - banco e pasta var
# Uso: ./scripts/backup-painel.sh (execute na raiz do projeto ou ajuste COMPOSE_FILE)
# Requer: Docker, painel no ar

set -e
FECHA=$(date +%Y%m%d)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${DIR}/backups"

mkdir -p "$BACKUP_DIR"

if [ -f "${DIR}/.env" ]; then
  source "${DIR}/.env"
fi

if [ -z "$MYSQL_PASSWORD" ]; then
  echo "Defina MYSQL_PASSWORD no .env"
  exit 1
fi

echo "Backup do banco..."
docker compose -f "${DIR}/docker-compose-painel.yml" exec -T database \
  mysqldump -u pterodactyl -p"${MYSQL_PASSWORD}" panel > "${BACKUP_DIR}/panel-${FECHA}.sql"

echo "Backup da pasta var..."
tar -czf "${BACKUP_DIR}/panel-var-${FECHA}.tar.gz" -C "${DIR}" var

echo "Backup concluído em ${BACKUP_DIR}"
ls -la "${BACKUP_DIR}"
