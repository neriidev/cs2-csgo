# Login no painel Pterodactyl

## Primeiro acesso

O painel **não vem** com usuário e senha prontos. Você precisa criar o primeiro usuário de uma destas formas:

---

### Opção 1: Registrar pela tela (se aparecer "Registrar")

1. Abra **http://localhost** (ou a URL do seu painel).
2. Clique em **Register** / **Registrar**.
3. Preencha:
   - **Email** – e-mail para login
   - **Username** – nome de usuário
   - **First Name** / **Last Name**
   - **Password** – senha de acesso
4. Envie o formulário.
5. A **primeira conta** criada vira **administrador**. Use **Login** com esse e-mail e senha.

---

### Opção 2: Só aparece "Login" (sem Registrar)

Quando o registro está desativado, a tela mostra apenas o formulário de login. Crie o primeiro usuário **admin** pelo terminal.

**PowerShell** (na pasta do projeto):

```powershell
cd C:\Users\rodri\OneDrive\Desktop\cs2-csgo

docker compose -f docker-compose-painel.yml exec panel php artisan p:user:make --email=admin@localhost --username=admin --name-first=Admin --name-last=Local --password=admin123 --admin=1
```

Troque se quiser:
- `--email=admin@localhost` → seu e-mail
- `--username=admin` → nome de usuário
- `--name-first=Admin` e `--name-last=Local` → nome e sobrenome
- `--password=admin123` → senha de acesso

Depois acesse o painel e faça **Login** com esse **e-mail** e **senha**.

---

## Login normal (já tem conta)

1. Abra a URL do painel (ex.: **http://localhost**).
2. Informe:
   - **Email** – o e-mail da sua conta
   - **Password** – a senha
3. Clique em **Login**.

---

## Habilitar registro (para outros usuários)

Depois de logado como **admin**:

1. Vá em **Admin** (canto superior).
2. **Configuration** (ou **Settings**).
3. Procure a opção de **registro** / **registration** e ative.
4. Salve. A partir daí, outras pessoas poderão usar o link **Registrar** na tela inicial.

---

## Esqueci a senha

Se você já tem uma conta mas esqueceu a senha, um administrador pode alterar no painel:

- **Admin** → **Users** → clique no usuário → **Edit** e defina uma nova senha.

Se for a **única** conta (admin) e você esqueceu a senha, crie outro admin pelo terminal (comando da Opção 2 acima com outro e-mail) e use esse usuário para entrar e alterar a senha do primeiro, ou redefinir pelo mesmo comando `p:user:make` (o comando não altera usuário existente; para resetar senha existe `p:user:password` – consulte a documentação do Pterodactyl).
