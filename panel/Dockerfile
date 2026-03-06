# Estende a imagem oficial do painel com o cliente MySQL para o schema/migrate funcionar
# (a imagem oficial não tem o binário "mysql", gerando "mysql: not found" na primeira subida)
FROM ghcr.io/pterodactyl/panel:latest
RUN apk add --no-cache mariadb-client
