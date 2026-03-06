# Tutorial – Clonar e configurar o projeto cs2-csgo

Esta pasta contém guias passo a passo para:

1. **Clonar o projeto e configurar em outra máquina local** (Windows com Docker Desktop)
2. **Configurar na AWS EC2** (instâncias Linux com Docker)
3. **Configurar na AWS ECS** (Fargate/EC2 com ALB)
4. **Configurar na AWS EKS** (Kubernetes)

---

## Índice

| Tutorial | Descrição |
|----------|-----------|
| [01 – Clonar e configurar local](01-clonar-e-configurar-local.md) | Clonar o repositório e rodar painel + Wings em outro PC Windows |
| [02 – AWS EC2](02-aws-ec2.md) | Subir o stack em uma ou duas instâncias EC2 (Linux) |
| [03 – AWS ECS](03-aws-ecs.md) | Painel e Wings como tarefas ECS (Fargate + EC2 para Wings) |
| [04 – AWS EKS](04-aws-eks.md) | Deploy no Kubernetes (EKS) com Ingress |

---

## Pré-requisitos gerais

- **Git** instalado
- **Docker** e **Docker Compose** (v2+)
- Para **local (Windows):** Docker Desktop com motor **WSL2**
- Para **AWS:** conta AWS e, opcionalmente, AWS CLI configurado

---

## URL do repositório

Substitua `<URL-DO-REPOSITORIO>` pelo endereço real do seu repositório, por exemplo:

- `https://github.com/seu-usuario/cs2-csgo.git`
- ou o caminho local/remoto que você usar (ex.: pasta compartilhada, outro Git host).

Se o projeto ainda não estiver em um repositório Git, você pode criar um no GitHub/GitLab e fazer o primeiro push a partir da pasta do projeto.

---

## Documentação adicional

- Guia completo de setup (local + AWS): **[docs/setup/README.md](../docs/setup/README.md)**
- Erros ao conectar o node: **[docs/erro-conectando-node.md](../docs/erro-conectando-node.md)**
- Subir servidor CS2: **[docs/subir-servidor-cs2.md](../docs/subir-servidor-cs2.md)**
