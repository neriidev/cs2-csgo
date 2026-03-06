# Patch do painel: permitir Disk I/O = 0

O ficheiro `Server.php` substitui `/app/app/Models/Server.php` no container do painel.

**Motivo:** No Windows com Docker/WSL2, o Docker não suporta o cgroup `io.weight`. Quando o servidor tem um limite de I/O (ex.: 10–1000), o Wings envia isso ao Docker e o arranque do container falha com:

```
error setting cgroup config: .../io.weight: no such file or directory
```

O painel original só aceita I/O entre **10 e 1000**. Este patch altera a validação para **0–1000**, para que possas usar **0** (sem limite) e o Wings não aplique `io.weight`, evitando o erro no Windows.

**Alteração:** na regra de validação do campo `io`, `between:10,1000` foi substituído por `min:0|max:1000`.

O volume está configurado em `docker-compose-painel.yml`:
`./panel-patch/Server.php:/app/app/Models/Server.php`

Se atualizares a imagem do painel, este ficheiro continua a ser montado por cima; mantém a alteração até o painel oficial suportar I/O = 0.
