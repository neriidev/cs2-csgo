# Próximos passos: subir servidor CS2

Com o **painel** e o **node (Wings)** já configurados, siga estes passos para criar e subir um servidor de **Counter-Strike 2**.

---

## 1. Alocações de portas no node

O servidor CS2 usa a porta **27015** (e opcionalmente 27020 para Source TV). O node precisa ter essas portas como “alocações”.

1. No painel: **Admin** → **Nodes** → clique no seu node (ex.: **cs2**).
2. Abra a aba **Allocations**.
3. Clique em **Create Allocation**.
4. **IP:** deixe em branco ou use o mesmo do node (ex.: `0.0.0.0` ou o IP do node).
5. **Ports:** adicione pelo menos **27015**. Exemplos:
   - Uma porta: `27015`
   - Ou um range: `27015-27020` (vários servidores no mesmo node).
6. Salve.

Sem alocações, o painel não deixa criar servidor nesse node.

**Não é preciso configurar nada no Wings:** as alocações são só no painel. O Wings usa as portas automaticamente quando você cria e inicia um servidor.

---

## 2. Egg/Nest do CS2 no painel

O painel precisa de um **Nest** (grupo) e um **Egg** (tipo de servidor) para CS2.

- Se já existir **Counter-Strike 2** ou **Source Engine** com opção CS2 em **Admin → Nests**, use esse.
- Se **não** existir:
  1. Acesse [Pterodactyl Eggs – Counter-Strike 2](https://eggs.pterodactyl.io/egg/games-counter-strike-2/).
  2. Baixe o JSON do egg.
  3. No painel: **Admin** → **Nests** → escolha um nest (ex.: **Source Engine**) → **Import Egg** e importe o JSON.

Para servidor **público** (listado na Valve), você vai precisar de um **Steam Game Server Login Token (GSLT)** em [Steam – Gerenciar servidores](https://steamcommunity.com/dev/managegameservers). Para teste local pode não ser obrigatório.

---

## 3. Criar o servidor no painel

1. No painel: **Servers** (ou **Dashboard**) → **Create Server** (ou **New Server**).
2. **Owner:** sua conta (já deve estar selecionada).
3. **Server Name:** ex. `Meu CS2`.
4. **Node:** escolha o node onde o Wings está (ex.: **cs2**).
5. **Nest:** ex. **Source Engine** (ou o nest onde está o egg CS2).
6. **Egg:** **Counter-Strike 2** (ou o egg que você importou).
7. **Memory / CPU / Disk:** ex. 2048 MiB RAM, 1 CPU, 35000 MiB disco (CS2 pede ~33 GB).
8. Na etapa de **Allocation**:
   - Marque **Assign Port** e escolha uma alocação livre (ex.: **27015**).
   - Se pedir IP, deixe o padrão.
9. Avance e clique em **Create** (ou **Create Server**).

O painel cria o servidor e inicia a **instalação** (download dos arquivos do jogo). Isso pode demorar vários minutos.

---

## 4. Instalação e primeiro start

1. Abra o servidor que você criou (lista em **Servers** ou **Dashboard**).
2. Na aba **Console** ou **Overview**, deve aparecer a instalação rodando (ou um botão **Install** / **Reinstall**).
3. Aguarde a instalação terminar (barra de progresso ou log na console).
4. Depois, use **Start** para iniciar o servidor.
5. Acompanhe pela **Console**; quando aparecer algo como “Server is running” ou a porta **27015** em uso, o servidor está no ar.

Se der erro na instalação, confira os logs na **Console** e se o node tem **disco** e **memória** suficientes.

---

## 5. Conectar no servidor (jogo no seu PC)

- **No mesmo Windows:** abra o CS2, no menu **Jogar** → **Comunidade** ou **Conectar**, e use:
  - **localhost:27015**  
  ou
  - **host.docker.internal:27015**
- **De outro PC na rede:** use o **IP do seu PC** (ex.: `192.168.1.10`) e a porta: **192.168.1.10:27015**.

No CS2 (console ou tela de conectar): `connect localhost:27015` (ou o IP:porta correto).

**Atenção:** Não use **`connect 0.0.0.0:27015`** no cliente. O endereço **0.0.0.0** é só para o *servidor* escutar em todas as interfaces; no *cliente* ele é inválido e gera erro "O endereço solicitado não é válido no contexto" e timeout. Use **`127.0.0.1`** ou **`localhost`** para conectar ao servidor na mesma máquina.

---

## 6. (Opcional) Servidor público e GSLT

Para o servidor aparecer na lista de servidores da Valve e evitar aviso de “insecure”:

1. Acesse [https://steamcommunity.com/dev/managegameservers](https://steamcommunity.com/dev/managegameservers).
2. Crie um **Game Server Account** para **App ID 730** (CS2).
3. Copie o **Login Token** (GSLT).
4. No painel, no seu servidor: **Startup** ou **Variables** e preencha a variável do **GSLT** (nome pode ser `SRCDS_TOKEN` ou similar, conforme o egg). Reinicie o servidor.

---

## Resumo rápido

| Passo | Onde | O quê |
|-------|------|--------|
| 1 | Admin → Nodes → [seu node] → Allocations | Criar alocação **27015** (e mais se quiser vários servidores). |
| 2 | Admin → Nests | Garantir que existe egg **CS2** (ou importar do repositório de eggs). |
| 3 | Servers → Create Server | Node, Nest, Egg CS2, recursos, alocação 27015. |
| 4 | Servidor → Console | Esperar instalação e dar **Start**. |
| 5 | CS2 no PC | Conectar em **localhost:27015** (ou IP:27015). |
| 6 | (Opcional) Steam + variável GSLT | Para servidor público na lista da Valve. |

Se em algum passo aparecer mensagem de erro (por exemplo “no allocations”, “egg not found” ou erro na console), diga em qual passo e qual texto aparece que ajustamos o próximo passo.
