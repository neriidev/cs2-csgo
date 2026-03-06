# Inicializa o banco do painel quando a imagem falha com "mysql: not found".
# Uso: .\scripts\panel-init-db.ps1
# Requer: containers do painel no ar (docker compose -f docker-compose-painel.yml up -d)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not (Test-Path "$ProjectRoot\docker-compose-painel.yml")) {
    $ProjectRoot = $PSScriptRoot
}
Set-Location $ProjectRoot

# Carrega MYSQL_PASSWORD do .env
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^\s*MYSQL_PASSWORD=(.+)$') {
            $script:MYSQL_PASSWORD = $Matches[1].Trim()
        }
    }
}
if (-not $MYSQL_PASSWORD) {
    Write-Host "Defina MYSQL_PASSWORD no arquivo .env da raiz do projeto."
    exit 1
}

Write-Host "Extraindo schema do container do painel..."
docker compose -f docker-compose-painel.yml exec panel cat /app/database/schema/mysql-schema.sql 2>$null | Set-Content -Path "$ProjectRoot\schema-temp.sql" -Encoding UTF8

Write-Host "Carregando schema no MariaDB..."
Get-Content "$ProjectRoot\schema-temp.sql" -Raw | docker compose -f docker-compose-painel.yml exec -T database mysql -u pterodactyl -p"$MYSQL_PASSWORD" panel 2>$null

Remove-Item "$ProjectRoot\schema-temp.sql" -ErrorAction SilentlyContinue

Write-Host "Rodando migrations..."
docker compose -f docker-compose-painel.yml exec -T panel php artisan migrate --force 2>$null

Write-Host "Rodando seeders..."
docker compose -f docker-compose-painel.yml exec -T panel php artisan db:seed --force 2>$null

Write-Host "Banco inicializado. Acesse http://localhost e crie a primeira conta."
exit 0
