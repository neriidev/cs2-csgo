# Fase 3 – Produção com Nginx Proxy Manager

Com o NPM na frente do painel, apenas o NPM escuta 80/443; o painel fica em uma porta interna.

## 1. Criar a rede compartilhada

Uma vez no host:

```bash
docker network create proxy_net
```

## 2. Subir o Nginx Proxy Manager

```bash
docker compose -f docker-compose-proxy.yml up -d
```

- **Admin do NPM:** `http://SEU_IP:81`
- **Login padrão:** `admin@example.com` / `changeme` (troque no primeiro acesso)

## 3. Subir o painel em modo “atrás do NPM”

O painel passa a escutar só nas portas 8080 (HTTP) e 8443 (HTTPS), na rede interna:

```bash
docker compose -f docker-compose-painel.yml -f docker-compose-painel.npm.yml up -d
```

O container do painel terá o nome **panel** e estará na rede `proxy_net`, acessível ao NPM.

## 4. Configurar o proxy no NPM

1. Acesse o NPM em `http://SEU_IP:81`.
2. **Hosts → Proxy Hosts → Add Proxy Host**
   - **Domain Names:** domínio do painel (ex: `painel.seudominio.com`)
   - **Scheme:** http
   - **Forward Hostname / IP:** `panel`
   - **Forward Port:** `8080`
3. **SSL:** marque **SSL Certificate** e use **Request a new SSL Certificate** (Let’s Encrypt). Informe e-mail e aceite os termos.
4. Salve.

## 5. Ajustar o painel

No `.env` (raiz do projeto) e em **var/.env**, defina:

```env
APP_URL=https://painel.seudominio.com
```

Reinicie o painel:

```bash
docker compose -f docker-compose-painel.yml -f docker-compose-painel.npm.yml restart panel
```

O Wings e os usuários devem usar sempre essa URL (`APP_URL`) para acessar o painel e para a API.

## 6. Resumo de portas

| Serviço | Portas expostas (host) | Uso |
|--------|------------------------|-----|
| NPM    | 80, 443, 81            | HTTP, HTTPS, admin |
| Painel | 8080, 8443             | Só rede interna (NPM faz proxy para 80/443) |
