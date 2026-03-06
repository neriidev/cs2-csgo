# Onde achar o System Token e a Node API Key no painel

O **System Token** e a **Node API Key** **não** ficam em **Settings** (General, Mail, Advanced). Eles ficam na tela do **Node**.

---

## Onde encontrar

1. No painel, clique em **Admin** (menu superior ou lateral).
2. No menu lateral, clique em **Nodes**.
3. Clique no **nome do seu node** (ex.: **cs2**).
4. Abra a aba **Configuration** (Configuração).

Nessa aba você verá:
- Um **bloco de código** com o **config.yml** do Wings. Copie **token_id**, **token** (e **system.token**).
- O Wings envia ao painel **Bearer token_id.token** — os dois são obrigatórios. Só **api.key** (ptla_...) gera erro 400 "Authorization header not in valid format".

---

## O que copiar

- **token_id** – identificador do token (ex.: `OpH3UWmX7CtoQCW9`). No bloco: `token_id: OpH3UWmX7CtoQCW9`.
- **token** – string longa (o mesmo valor costuma aparecer em **system.token**). No bloco: `token: "xxxx"`.
- **system.token** – mesma string do **token**. Em `system.token: "xxxx"`.

Use no **wings-config/config.yml** (na raiz do YAML):

```yaml
token_id: "COLE_O_TOKEN_ID"
token: "COLE_O_TOKEN"
```

E em **system:** mantenha `token: "COLE_O_TOKEN"`. No **.env** (para o wings-init):

```env
WINGS_TOKEN_ID=COLE_O_TOKEN_ID
WINGS_SYSTEM_TOKEN=COLE_O_TOKEN
```

**api.key** (ptla_...) sozinha não basta; o painel exige **token_id** e **token** no header.

---

## Resumo

| O que você quer | Onde no painel |
|-----------------|----------------|
| **token_id** (obrigatório com token) | **Admin** → **Nodes** → **[seu node]** → aba **Configuration** |
| **token** / **system.token** | **Admin** → **Nodes** → **[seu node]** → aba **Configuration** |
| **api.key** (ptla_..., opcional no config) | mesma aba Configuration |

**Não** é em: Settings, Advanced, Application API (essa é outra chave, para API do painel).
