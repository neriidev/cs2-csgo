# Fase 2 – Múltiplos servidores de jogo (faixa de portas)

## Definir faixa de portas

Para evitar conflito entre servidores, reserve uma faixa de portas por jogo no **host** onde roda o Wings.

Exemplos:

| Jogo   | Porta padrão | Faixa sugerida   |
|--------|--------------|------------------|
| CS2/CS:GO | 27015     | 27015–27030      |
| Minecraft (Java) | 25565 | 25565–25580   |
| FiveM  | 30120       | 30120–30135      |

No **painel**:

1. **Admin → Nodes → [seu node] → Allocations**
2. Adicione as portas (ex.: 27015 a 27030) ou permita que o painel crie automaticamente a partir de um range.

Ao criar cada **Server**, escolha uma alocação (porta) livre para aquele servidor.

## Vários “Servers” no mesmo node

- Crie quantos **Servers** precisar no painel.
- Cada um usa uma **porta diferente** (uma alocação por servidor).
- Todos rodam no mesmo Wings (mesma máquina) até você adicionar outro node.

## Segundo host (segundo node)

Para escalar:

1. Instale Docker no novo host.
2. Configure o Wings nesse host (outro `/etc/pterodactyl/config.yml` com o mesmo painel, mas **novo node** no painel).
3. No painel: **Admin → Nodes → Add Node** – FQDN/IP do novo host, porta 8080.
4. Ao criar um **Server**, escolha em qual **Node** ele vai rodar.
