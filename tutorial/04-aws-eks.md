# Tutorial 04 – Configurar na AWS EKS

Este tutorial descreve os **conceitos e passos** para rodar o projeto **cs2-csgo** (Pterodactyl Panel + Wings) no **Amazon EKS** (Kubernetes), com Ingress para o painel e nós com Docker para o Wings.

---

## O que você precisa saber

- **EKS** é Kubernetes gerido pela AWS. Você cria um cluster e depois define **Deployments**, **Services**, **Ingress**, **Secrets**, **ConfigMaps** e **PersistentVolumeClaims**.
- O **Wings** precisa de acesso ao **Docker daemon** para criar containers dos servidores de jogo. Por isso o Wings deve correr em **nodes que tenham Docker** (montando `/var/run/docker.sock`) ou usar uma solução tipo **Docker-in-Docker (DinD)** com cuidado de segurança. Em EKS, a abordagem comum é ter **node groups** dedicados com Docker instalado e o Wings em modo **privileged** com o socket montado.

---

## Pré-requisitos

- Conta AWS
- **kubectl** instalado e configurado para o cluster EKS (`aws eks update-kubeconfig --region <region> --name <cluster-name>`)
- **Helm** (opcional, para empacotar o painel/DB/Redis)
- Domínio (opcional) e certificado para o Ingress (ex.: ACM + Ingress Controller)

---

## Passo 1 – Criar o cluster EKS

1. **AWS Console** → **EKS** → **Clusters** → **Create cluster**.
2. **Name:** ex. `pterodactyl-eks`.
3. **Kubernetes version:** escolha uma versão suportada.
4. **Cluster service role:** use o role criado automaticamente ou um existente com permissões EKS.
5. **VPC e subnets:** escolha uma VPC com subnets públicas/privadas. Para o Wings com portas de jogo, pode ser útil ter nós em subnets públicas ou um Load Balancer para expor portas.
6. Crie o cluster e aguarde o estado **Active**.

Adicione um **Node Group** (EC2) com capacidade para rodar o painel e o Wings. Para o Wings, use instâncias com mais CPU/RAM (ex.: `t3.medium` ou maiores). Se quiser separar nós de aplicação dos nós de jogos, crie dois node groups e use **taints/tolerations** para agendar o Wings apenas nos nós de jogos.

---

## Passo 2 – Configurar kubectl

```bash
aws eks update-kubeconfig --region sa-east-1 --name pterodactyl-eks
kubectl get nodes
```

---

## Passo 3 – Namespace e Secrets

```bash
kubectl create namespace pterodactyl
```

Crie um **Secret** com as senhas do painel (e token do Wings, se preferir):

```bash
kubectl create secret generic panel-secrets -n pterodactyl \
  --from-literal=db-password='panel123' \
  --from-literal=mysql-root-password='root123'
```

Ou use **AWS Secrets Manager** com o CSI driver e referencie no Deployment.

---

## Passo 4 – Deploy MariaDB e Redis

Pode usar Helm charts estáveis (ex.: `bitnami/mariadb`, `bitnami/redis`) ou manifestos YAML.

Exemplo mínimo de **PersistentVolumeClaim** e **Deployment** para MariaDB:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb-pvc
  namespace: pterodactyl
spec:
  accessModes: [ "ReadWriteOnce" ]
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
  namespace: pterodactyl
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
      - name: mariadb
        image: mariadb:10.5
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: panel-secrets
              key: mysql-root-password
        - name: MYSQL_DATABASE
          value: panel
        - name: MYSQL_USER
          value: pterodactyl
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: panel-secrets
              key: db-password
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: mariadb-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mariadb
  namespace: pterodactyl
spec:
  selector:
    app: mariadb
  ports:
  - port: 3306
    targetPort: 3306
  type: ClusterIP
```

Redis pode ser um Deployment + Service ClusterIP simples (imagem `redis:alpine`). Aplique os manifestos com `kubectl apply -f ...`.

---

## Passo 5 – Deploy do painel

1. **Imagem:** construa a imagem do painel (a partir de `./panel`) e envie para o **ECR** (como no tutorial ECS). Ou use uma imagem pública do Pterodactyl se compatível com o projeto.
2. **Deployment** do painel:
   - **Image:** URI do ECR (ex.: `<account-id>.dkr.ecr.sa-east-1.amazonaws.com/pterodactyl-panel:latest`).
   - **Env:** `APP_URL`, `APP_SERVICE_AUTHOR`, `DB_HOST=mariadb`, `DB_PASSWORD` (from Secret), `REDIS_HOST=redis`, `CACHE_DRIVER=redis`, `SESSION_DRIVER=redis`, `QUEUE_CONNECTION=redis`.
   - **Port:** 80 (ou 443 se o painel terminar SSL).
   - **Volume:** para storage e logs (PVC ou emptyDir conforme necessidade).
3. **Service** do tipo **ClusterIP** (ou LoadBalancer para teste) apontando para o Deployment do painel na porta 80.

---

## Passo 6 – Ingress para o painel

Instale um **Ingress Controller** (ex.: AWS Load Balancer Controller, ou NGINX Ingress) no cluster. Crie um recurso **Ingress**:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pterodactyl-panel
  namespace: pterodactyl
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
  - host: painel.seudominio.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: panel
            port:
              number: 80
```

Para HTTPS, use anotação com certificado ACM (ex.: `alb.ingress.kubernetes.io/certificate-arn`). O endereço do painel será `https://painel.seudominio.com` (ou o host que configurar).

---

## Passo 7 – Deploy do Wings

O Wings deve rodar em **nodes com Docker**. Opções:

- **Node group dedicado:** crie um node group com **User Data** que instale o Docker e exponha o socket. Use **taints** nesses nós e **tolerations** no Deployment do Wings para que só o Wings agende aí.
- **Montar o socket do Docker:** no Pod do Wings, monte `/var/run/docker.sock` do host e use **securityContext privileged: true** (ou as capabilities necessárias). Isso exige que os nós tenham Docker e que o kubelet permita esse mount.

Exemplo de **Deployment** do Wings (conceito):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wings
  namespace: pterodactyl
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wings
  template:
    metadata:
      labels:
        app: wings
    spec:
      # tolerations para nós dedicados a jogos (opcional)
      containers:
      - name: wings
        image: ghcr.io/pterodactyl/wings:latest
        securityContext:
          privileged: true
        volumeMounts:
        - name: docker-socket
          mountPath: /var/run/docker.sock
        - name: pterodactyl-volumes
          mountPath: /var/lib/pterodactyl/volumes
        - name: tmp-pterodactyl
          mountPath: /tmp/pterodactyl
        env:
        - name: WINGS_TOKEN_ID
          valueFrom:
            secretKeyRef:
              name: wings-secrets
              key: token-id
        - name: WINGS_SYSTEM_TOKEN
          valueFrom:
            secretKeyRef:
              name: wings-secrets
              key: token
        ports:
        - containerPort: 8080
        - containerPort: 2022
      volumes:
      - name: docker-socket
        hostPath:
          path: /var/run/docker.sock
      - name: pterodactyl-volumes
        persistentVolumeClaim:
          claimName: wings-volumes-pvc
      - name: tmp-pterodactyl
        hostPath:
          path: /tmp/pterodactyl
          type: DirectoryOrCreate
```

Crie **PVC** para `wings-volumes-pvc` e **Secret** `wings-secrets` com o token do painel. Para expor a porta 8080 e as portas dos jogos (ex.: 27015), use **Service** do tipo **LoadBalancer** ou **NodePort** e abra as portas no Security Group dos nós.

---

## Passo 8 – Configurar o node no painel

No painel Pterodactyl, **Admin** → **Nodes** → **Create Node**:

- **FQDN:** hostname ou IP pelo qual o painel e os clientes alcançam o Wings (ex.: nome do Service do tipo LoadBalancer, ou DNS do NLB). A porta 8080 deve estar acessível.
- **Daemon Port:** 8080.

Crie **Allocations** (ex.: 27015–27020) e crie servidores CS2 pelo painel.

---

## Resumo EKS

| Componente | Recurso Kubernetes | Notas |
|------------|-------------------|--------|
| Painel | Deployment + Service + Ingress | Imagem no ECR; env para DB e Redis |
| MariaDB / Redis | Deployment + Service + PVC | Ou use RDS/ElastiCache fora do cluster |
| Wings | Deployment + Service (LoadBalancer/NodePort) | Nodes com Docker; mount do docker.sock; PVC para volumes |

Para mais detalhes e exemplos completos, consulte **[docs/setup/README.md](../docs/setup/README.md)** (secção AWS EKS).
