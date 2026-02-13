# Advanced Topics

Advanced ArgoCD concepts and configurations for production use.

## Multi-Environment Setup

### Directory Structure

```
argocd-tutorial/
├── base/                    # Base manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
├── overlays/
│   ├── dev/                # Development environment
│   │   ├── kustomization.yaml
│   │   └── patch-replicas.yaml
│   ├── staging/            # Staging environment
│   │   ├── kustomization.yaml
│   │   └── patch-replicas.yaml
│   └── production/         # Production environment
│       ├── kustomization.yaml
│       └── patch-replicas.yaml
└── argocd/
    ├── app-dev.yaml
    ├── app-staging.yaml
    └── app-production.yaml
```

### Environment-Specific Applications

**Development:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app-dev
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/YOUR_USERNAME/argocd-tutorial.git
    targetRevision: develop
    path: overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: demo-app-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**Production:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app-prod
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/YOUR_USERNAME/argocd-tutorial.git
    targetRevision: main
    path: overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: demo-app-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: false  # Manual approval for production
```

## Webhooks for Instant Sync

### GitHub Webhook Setup

1. **Get ArgoCD webhook URL:**
```bash
echo "https://$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')/api/webhook"
```

2. **Configure in GitHub:**
- Go to repository Settings → Webhooks
- Add webhook:
  - Payload URL: `https://argocd.example.com/api/webhook`
  - Content type: `application/json`
  - Secret: (optional, recommended)
  - Events: Just the push event

3. **Configure ArgoCD webhook secret:**
```bash
kubectl -n argocd create secret generic argocd-webhook-secret \
  --from-literal=webhook.github.secret=YOUR_SECRET
```

## App of Apps Pattern

Deploy multiple applications with a single ArgoCD application.

### Root Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/YOUR_USERNAME/argocd-tutorial.git
    targetRevision: main
    path: argocd/apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Child Applications Directory

```
argocd/apps/
├── demo-app.yaml
├── monitoring.yaml
└── logging.yaml
```

## Helm Integration

### Using Helm Charts

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app-helm
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/YOUR_USERNAME/argocd-tutorial.git
    targetRevision: main
    path: helm/demo-app
    helm:
      valueFiles:
      - values.yaml
      - values-prod.yaml
      parameters:
      - name: image.tag
        value: a3f5c21
      - name: replicaCount
        value: "3"
  destination:
    server: https://kubernetes.default.svc
    namespace: demo-app
```

## Sync Waves and Hooks

Control deployment order with sync waves.

### Example with Sync Waves

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo-app
  annotations:
    argocd.argoproj.io/sync-wave: "0"  # Deploy first
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: demo-app
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Deploy second
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: demo-app
  annotations:
    argocd.argoproj.io/sync-wave: "2"  # Deploy last
```

### Pre-Sync Hook

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: migrate-tool:latest
        command: ["migrate", "up"]
      restartPolicy: Never
```

## Resource Hooks

### Post-Sync Notification

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: notify-deployment
  annotations:
    argocd.argoproj.io/hook: PostSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
      - name: notify
        image: curlimages/curl
        command:
        - sh
        - -c
        - |
          curl -X POST https://slack.com/api/chat.postMessage \
            -H "Authorization: Bearer $SLACK_TOKEN" \
            -d "text=Deployment successful!"
      restartPolicy: Never
```

## RBAC Configuration

### Project-Specific Access

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.csv: |
    p, role:dev-team, applications, get, demo-app/*, allow
    p, role:dev-team, applications, sync, demo-app/*, allow
    g, dev-user@example.com, role:dev-team
```

## Notifications

### Configure Slack Notifications

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.slack: |
    token: $slack-token
  template.app-deployed: |
    message: |
      Application {{.app.metadata.name}} is now running new version.
  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-deployed]
```

## Image Updater

Automatically update image tags in Git.

### Install ArgoCD Image Updater

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
```

### Configure Image Updater

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
  namespace: argocd
  annotations:
    argocd-image-updater.argoproj.io/image-list: demo-app=123456789.dkr.ecr.us-east-1.amazonaws.com/demo-app
    argocd-image-updater.argoproj.io/demo-app.update-strategy: latest
    argocd-image-updater.argoproj.io/write-back-method: git
```

## Disaster Recovery

### Backup ArgoCD Configuration

```bash
# Backup all applications
kubectl get applications -n argocd -o yaml > argocd-apps-backup.yaml

# Backup ArgoCD settings
kubectl get configmaps -n argocd -o yaml > argocd-config-backup.yaml
kubectl get secrets -n argocd -o yaml > argocd-secrets-backup.yaml
```

### Restore from Backup

```bash
kubectl apply -f argocd-apps-backup.yaml
kubectl apply -f argocd-config-backup.yaml
```

## High Availability

### HA ArgoCD Installation

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/ha/install.yaml
```

### Scale Components

```bash
# Scale application controller
kubectl scale deployment argocd-application-controller -n argocd --replicas=3

# Scale repo server
kubectl scale deployment argocd-repo-server -n argocd --replicas=3

# Scale server
kubectl scale deployment argocd-server -n argocd --replicas=3
```

## Monitoring and Metrics

### Prometheus Integration

```yaml
apiVersion: v1
kind: Service
metadata:
  name: argocd-metrics
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-metrics
spec:
  ports:
  - name: metrics
    port: 8082
    protocol: TCP
    targetPort: 8082
  selector:
    app.kubernetes.io/name: argocd-application-controller
```

### Grafana Dashboard

Import ArgoCD dashboard: https://grafana.com/grafana/dashboards/14584

## Security Best Practices

### 1. Use Private Repositories

```bash
# Add private repo credentials
argocd repo add https://github.com/private/repo.git \
  --username YOUR_USERNAME \
  --password YOUR_TOKEN
```

### 2. Enable SSO

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  url: https://argocd.example.com
  dex.config: |
    connectors:
    - type: github
      id: github
      name: GitHub
      config:
        clientID: $github-client-id
        clientSecret: $github-client-secret
        orgs:
        - name: your-org
```

### 3. Encrypt Secrets

Use sealed-secrets or external-secrets:

```bash
# Install sealed-secrets
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Create sealed secret
kubeseal --format yaml < secret.yaml > sealed-secret.yaml
```

### 4. Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: argocd-network-policy
  namespace: argocd
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/part-of: argocd
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: argocd
  egress:
  - to:
    - namespaceSelector: {}
```

## Progressive Delivery

### Canary Deployments with Argo Rollouts

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: demo-app
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 1m}
      - setWeight: 40
      - pause: {duration: 1m}
      - setWeight: 60
      - pause: {duration: 1m}
      - setWeight: 80
      - pause: {duration: 1m}
  template:
    spec:
      containers:
      - name: demo-app
        image: demo-app:latest
```

## Multi-Cluster Management

### Add External Cluster

```bash
# Get cluster context
kubectl config get-contexts

# Add cluster to ArgoCD
argocd cluster add CONTEXT_NAME

# List clusters
argocd cluster list
```

### Deploy to Multiple Clusters

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app-cluster2
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/YOUR_USERNAME/argocd-tutorial.git
    targetRevision: main
    path: k8s
  destination:
    server: https://cluster2.example.com
    namespace: demo-app
```

## Performance Tuning

### Optimize Repository Polling

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  timeout.reconciliation: 180s  # Default: 180s
  timeout.reconciliation.jitter: 30s
```

### Resource Limits

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-application-controller
spec:
  template:
    spec:
      containers:
      - name: argocd-application-controller
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi
```

## Further Reading

- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [GitOps Principles](https://opengitops.dev/)
- [Argo Rollouts](https://argoproj.github.io/argo-rollouts/)
- [ArgoCD Notifications](https://argocd-notifications.readthedocs.io/)
