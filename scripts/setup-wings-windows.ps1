# Cria pastas e config do Wings para Windows (modo bridge).
# Preenche api.host, ssl.verify e allowed_origins. Opcionalmente pede api.key e system.token.
# Uso: .\scripts\setup-wings-windows.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
if (Test-Path "$PSScriptRoot\..\docker-compose-wings-windows.yml") { $ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path }
Set-Location $ProjectRoot

Write-Host "Criando pastas..."
New-Item -ItemType Directory -Force -Path "wings-config" | Out-Null
New-Item -ItemType Directory -Force -Path "wings-data\volumes" | Out-Null
New-Item -ItemType Directory -Force -Path "wings-data\tmp" | Out-Null

$examplePath = "pterodactyl\config.yml.example"
$configPath = "wings-config\config.yml"

if (-not (Test-Path $examplePath)) {
    Write-Host "Erro: $examplePath nao encontrado."
    exit 1
}

Write-Host "Copiando config de exemplo para $configPath..."
Copy-Item -Path $examplePath -Destination $configPath -Force

$content = Get-Content $configPath -Raw -Encoding UTF8

# Ajustes para painel local no Windows (Docker)
$content = $content -replace 'host:\s*"[^"]*"', 'host: "http://host.docker.internal"'
$content = $content -replace 'verify:\s*true', 'verify: false'
$content = $content -replace '  - "https://[^"]*"', "  - `"http://localhost`"`n  - `"http://host.docker.internal`""

# Perguntar Node API Key (api.key)
$apiKey = Read-Host "Cole a Node API Key do painel (Admin -> Nodes -> [seu node]) ou Enter para pular"
if (-not [string]::IsNullOrWhiteSpace($apiKey)) {
    $content = $content -replace 'key:\s*"ptla_[^"]*"', "key: `"$($apiKey.Trim())`""
    Write-Host "api.key definido."
}

# Perguntar System Token
$systemToken = Read-Host "Cole o System Token (Admin -> Configuration -> Wings) ou Enter para pular"
if (-not [string]::IsNullOrWhiteSpace($systemToken)) {
    $content = $content -replace 'token:\s*"[^"]*"', "token: `"$($systemToken.Trim())`""
    Write-Host "system.token definido."
}

Set-Content -Path $configPath -Value $content -NoNewline -Encoding UTF8

Write-Host ""
Write-Host "Pronto. Config salvo em $configPath"
if ([string]::IsNullOrWhiteSpace($apiKey) -or [string]::IsNullOrWhiteSpace($systemToken)) {
    Write-Host "Se pulou alguma chave, edite wings-config\config.yml e preencha api.key e system.token."
}
Write-Host ""
Write-Host "Proximo passo: docker compose -f docker-compose-wings-windows.yml up -d"
