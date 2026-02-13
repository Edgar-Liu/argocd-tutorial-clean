# Quick Reference

Fast reference guide for common ArgoCD operations.

## Essential Commands

### ArgoCD CLI

```bash
# Login
argocd login localhost:8080

# List applications
argocd app list

# Get application details
argocd app get demo-app

# Sync application
argocd app sync demo-app

# Watch sync progress
argocd app sync demo-app --watch

# Get sync history
argocd app history demo-app

# Rollback to previous version
argocd app rollback demo-app <REVISION_ID>

# Delete application
argocd app delete demo-app

# Refresh application (force check Git)
argocd app get demo-app --refresh

# Hard refresh (clear cache)
argocd app get demo-app --hard-refresh

# View application logs
argocd app logs demo-app

# Set sync policy to auto
argocd app set demo-app --sync-policy automated

# Disable auto-sync
argocd app set demo-app --sync-policy none
```

### Kubectl Commands

```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Check application status
kubectl get application -n argocd

# Check demo app pods
kubectl get pods -n demo-app

# View application details
kubectl describe application demo-app -n argocd

# Port forward to ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Port forward to demo app
kubectl port-forward -n demo-app svc/demo-app 3000:80

# View logs
kubectl logs -n demo-app -l app=demo-app --tail=50

# Check rollout status
kubectl rollout status deployment/demo-app -n demo-app

# Restart deployment
kubectl rollout restart deployment/demo-app -n demo-app

# View deployment history
kubectl rollout history deployment/demo-app -n demo-app

# Scale deployment
kubectl scale deployment demo-app -n demo-app --replicas=5
```

### Docker Commands

```bash
# Build image
docker build -t IMAGE_NAME:TAG app/

# Tag image
docker tag SOURCE_IMAGE:TAG TARGET_IMAGE:TAG

# Push image
docker push IMAGE_NAME:TAG

# Login to ECR
aws ecr get-login-password --region REGION | \
  docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.REGION.amazonaws.com

# Login to Docker Hub
docker login

# List local images
docker images

# Remove image
docker rmi IMAGE_NAME:TAG

# Clean up
docker system prune -a
```

### Git Commands

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/argocd-tutorial.git

# Create branch
git checkout -b feature/new-feature

# Stage changes
git add .

# Commit changes
git commit -m "feat: add new feature"

# Push changes
git push origin feature/new-feature

# Pull latest changes
git pull origin main

# View commit history
git log --oneline -10

# View file changes
git diff

# Revert commit
git revert HEAD

# Reset to previous commit (careful!)
git reset --hard HEAD~1
```

## Common Workflows

### Deploy New Version

```bash
# 1. Build and push image
export IMAGE_TAG=$(git rev-parse --short HEAD)
docker build -t REGISTRY/demo-app:$IMAGE_TAG app/
docker push REGISTRY/demo-app:$IMAGE_TAG

# 2. Update manifest
sed -i "s|image:.*|image: REGISTRY/demo-app:$IMAGE_TAG|" k8s/deployment.yaml

# 3. Commit and push
git add k8s/deployment.yaml
git commit -m "chore: update image to $IMAGE_TAG"
git push origin main

# 4. Watch ArgoCD sync
argocd app sync demo-app --watch
```

### Rollback Deployment

```bash
# Option 1: ArgoCD rollback
argocd app history demo-app
argocd app rollback demo-app <REVISION_ID>

# Option 2: Git revert
git revert HEAD
git push origin main
# ArgoCD will auto-sync

# Option 3: Kubectl rollback
kubectl rollout undo deployment/demo-app -n demo-app
```

### Debug Application Issues

```bash
# 1. Check application status
argocd app get demo-app

# 2. Check pods
kubectl get pods -n demo-app

# 3. Describe problematic pod
kubectl describe pod POD_NAME -n demo-app

# 4. View logs
kubectl logs POD_NAME -n demo-app

# 5. Check events
kubectl get events -n demo-app --sort-by='.lastTimestamp'

# 6. Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=100
```

## Configuration Files

### ArgoCD Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/argocd-tutorial.git
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: demo-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: demo-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
      - name: demo-app
        image: REGISTRY/demo-app:TAG
        ports:
        - containerPort: 3000
```

## Environment Variables

```bash
# AWS ECR
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export IMAGE_NAME=demo-app
export IMAGE_TAG=$(git rev-parse --short HEAD)

# Docker Hub
export DOCKER_USERNAME=your-username
export IMAGE_NAME=demo-app
export IMAGE_TAG=$(git rev-parse --short HEAD)
```

## Troubleshooting Quick Fixes

### ArgoCD UI Not Accessible

```bash
pkill -f "port-forward.*argocd"
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Application OutOfSync

```bash
argocd app sync demo-app --force
```

### Pods Not Starting

```bash
kubectl describe pod POD_NAME -n demo-app
kubectl logs POD_NAME -n demo-app
```

### Image Pull Errors

```bash
# Verify image exists
docker pull IMAGE:TAG

# Check/recreate secret
kubectl get secret -n demo-app
kubectl delete secret IMAGE_PULL_SECRET -n demo-app
# Recreate secret...
```

### Forgot ArgoCD Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## URLs and Endpoints

```bash
# ArgoCD UI
https://localhost:8080

# Demo App (via port-forward)
http://localhost:3000

# Demo App Health Check
http://localhost:3000/health

# ArgoCD API
https://localhost:8080/api/v1/applications
```

## File Locations

```
Repository Structure:
├── app/                          # Application code
│   ├── server.js                # Node.js server
│   ├── package.json             # Dependencies
│   └── Dockerfile               # Container definition
├── k8s/                         # Kubernetes manifests
│   ├── namespace.yaml           # Namespace
│   ├── deployment.yaml          # Deployment
│   ├── service.yaml             # Service
│   └── ingress.yaml             # Ingress
├── argocd/                      # ArgoCD config
│   └── application.yaml         # Application manifest
├── scripts/                     # Helper scripts
│   ├── build-and-push.sh       # Build/push automation
│   └── update-image.sh         # Update image tag
├── .github/workflows/           # CI/CD
│   └── ci.yaml                 # GitHub Actions
└── docs/                        # Documentation
    ├── setup.md                # Setup guide
    ├── workflow.md             # Git workflow
    ├── troubleshooting.md      # Common issues
    ├── advanced.md             # Advanced topics
    └── examples.md             # Example outputs
```

## Status Meanings

### Sync Status
- **Synced**: Git matches cluster
- **OutOfSync**: Git differs from cluster
- **Unknown**: Cannot determine status

### Health Status
- **Healthy**: All resources running correctly
- **Progressing**: Deployment in progress
- **Degraded**: Some resources unhealthy
- **Suspended**: Resource suspended
- **Missing**: Resource not found
- **Unknown**: Cannot determine health

## Useful Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# ArgoCD
alias argocd-login='argocd login localhost:8080'
alias argocd-apps='argocd app list'
alias argocd-sync='argocd app sync'
alias argocd-get='argocd app get'

# Kubectl
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias klf='kubectl logs -f'

# ArgoCD specific
alias kga='kubectl get application -n argocd'
alias kgaa='kubectl get application -n argocd -o wide'
```

## Quick Setup Checklist

- [ ] Kubernetes cluster running
- [ ] kubectl configured
- [ ] ArgoCD installed
- [ ] ArgoCD UI accessible
- [ ] Repository forked and cloned
- [ ] Container registry configured
- [ ] Image built and pushed
- [ ] Deployment manifest updated
- [ ] ArgoCD application created
- [ ] Application synced and healthy

## Support

- Documentation: See `docs/` directory
- Issues: GitHub Issues
- Examples: See `docs/examples.md`
- Advanced: See `docs/advanced.md`
