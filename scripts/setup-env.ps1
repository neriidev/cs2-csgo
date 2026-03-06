# Cria .env e var/.env a partir dos exemplos e define a mesma senha nos dois.
# Uso: .\scripts\setup-env.ps1
# Depois: docker compose -f docker-compose-painel.yml up -d

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not (Test-Path "$ProjectRoot\docker-compose-painel.yml")) {
    $ProjectRoot = $PSScriptRoot
}
Set-Location $ProjectRoot

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Criado .env a partir de .env.example"
} else {
    Write-Host ".env ja existe"
}

if (-not (Test-Path "var\.env")) {
    Copy-Item "var\.env.example" "var\.env"
    Write-Host "Criado var\.env a partir de var\.env.example"
} else {
    Write-Host "var\.env ja existe"
}

$senha = Read-Host "Digite a senha do banco (MYSQL_PASSWORD / DB_PASSWORD) ou Enter para usar 'panel123'"
if ([string]::IsNullOrWhiteSpace($senha)) { $senha = "panel123" }

# Atualiza .env
(Get-Content ".env") | ForEach-Object {
    if ($_ -match '^MYSQL_ROOT_PASSWORD=\s*$') { "MYSQL_ROOT_PASSWORD=$senha" }
    elseif ($_ -match '^MYSQL_PASSWORD=\s*$') { "MYSQL_PASSWORD=$senha" }
    else { $_ }
} | Set-Content ".env"

# Atualiza var/.env
$varEnvPath = "var\.env"
(Get-Content $varEnvPath) | ForEach-Object {
    if ($_ -match '^DB_PASSWORD=\s*$') { "DB_PASSWORD=$senha" }
    else { $_ }
} | Set-Content $varEnvPath

Write-Host "Senha definida nos dois arquivos."
Write-Host ""
Write-Host "Proximo passo: docker compose -f docker-compose-painel.yml up -d"
Write-Host "Depois acesse http://localhost e crie a primeira conta."
