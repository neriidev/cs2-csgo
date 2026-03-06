@echo off
REM Backup do painel Pterodactyl - banco e pasta var
REM Uso: backup-painel.bat
REM Requer: Docker rodando, painel no ar (docker-compose-painel)

setlocal
set FECHA=%date:~-4%%date:~3,2%%date:~0,2%
set DIR=%~dp0
set BACKUP_DIR=%DIR%backups

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo Backup do banco...
docker compose -f "%DIR%docker-compose-painel.yml" exec -T database mysqldump -u pterodactyl -p"%MYSQL_PASSWORD%" panel > "%BACKUP_DIR%\panel-%FECHA%.sql" 2>nul
if errorlevel 1 (
  echo Defina MYSQL_PASSWORD no ambiente ou no .env antes de rodar.
  echo Ex: set MYSQL_PASSWORD=sua_senha
  exit /b 1
)

echo Backup da pasta var...
tar -czf "%BACKUP_DIR%\panel-var-%FECHA%.tar.gz" -C "%DIR%" var 2>nul
if errorlevel 1 (
  echo tar nao encontrado ou falha. No Windows instale tar ou use 7-Zip.
)

echo Backup concluido em %BACKUP_DIR%
endlocal
