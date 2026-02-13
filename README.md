# ArgoCD Tutorial: Complete GitOps Workflow

A hands-on tutorial demonstrating ArgoCD and GitOps principles with a real-world example.

## 📚 What You'll Learn

- What GitOps is and why it matters
- How ArgoCD monitors Git repositories and syncs Kubernetes clusters
- Complete CI/CD pipeline with automated image tag updates
- Real Git workflow with commits, pushes, and pull requests
- How changes propagate from code to production

## 🎯 What is GitOps?

GitOps is a paradigm where Git is the single source of truth for declarative infrastructure and applications. Key principles:

1. **Declarative**: System state described declaratively (YAML manifests)
2. **Versioned**: All changes tracked in Git with full history
3. **Immutable**: Changes create new versions, never modify in place
4. **Automated**: Changes automatically applied to target environment
5. **Continuously Reconciled**: Actual state continuously matched to desired state

## 🚀 What is ArgoCD?

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It:

- Monitors Git repositories for changes
- Compares desired state (Git) vs actual state (cluster)
- Automatically syncs differences
- Provides visualization and rollback capabilities
- Detects and corrects configuration drift

### How ArgoCD Works

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│             │         │              │         │             │
│  Developer  │────────▶│  Git Repo    │◀────────│   ArgoCD    │
│             │  push   │  (manifests) │  poll   │             │
└─────────────┘         └──────────────┘         └──────┬──────┘
                                                         │
                                                         │ sync
                                                         │
                                                         ▼
                                                  ┌─────────────┐
                                                  │             │
                                                  │ Kubernetes  │
                                                  │  Cluster    │
                                                  │             │
                                                  └─────────────┘
```

**Reconciliation Loop:**
1. ArgoCD polls Git repository (default: every 3 minutes)
2. Compares Git manifests with cluster state
3. Detects differences (drift)
4. Applies changes to cluster (if auto-sync enabled)
5. Reports sync status

## 📁 Repository Structure

```
argocd-tutorial/
├── app/                    # Example application
│   ├── server.js          # Simple Node.js web server
│   ├── package.json       # Node dependencies
│   └── Dockerfile         # Container image definition
├── k8s/                   # Kubernetes manifests
│   ├── namespace.yaml     # Namespace definition
│   ├── deployment.yaml    # Application deployment
│   ├── service.yaml       # Service definition
│   └── ingress.yaml       # Ingress configuration
├── argocd/                # ArgoCD configuration
│   └── application.yaml   # ArgoCD Application manifest
├── scripts/               # Automation scripts
│   └── update-image.sh    # Script to update image tags
├── .github/               # CI/CD pipeline
│   └── workflows/
│       └── ci.yaml        # GitHub Actions workflow
├── docs/                  # Documentation
│   ├── setup.md          # Setup instructions
│   ├── workflow.md       # Git workflow guide
│   └── troubleshooting.md # Common issues
└── README.md             # This file
```

## 🏃 Quick Start

> **⚠️ IMPORTANT FOR MACBOOK USERS (Apple Silicon M1/M2/M3)**  
> You MUST build images with `docker buildx build --platform linux/amd64` instead of regular `docker build`.  
> See [MacBook Users Guide](docs/macbook-users.md) for details.

### Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured
- Docker installed
- Git installed
- AWS CLI (for ECR) or Docker Hub account

### 1. Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Access ArgoCD UI (in new terminal)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Access UI at: https://localhost:8080 (username: `admin`, password: from above command)

### 2. Fork and Clone This Repository

```bash
# Fork this repo on GitHub, then:
git clone https://github.com/Edgar-Liu/argocd-tutorial.git
cd argocd-tutorial
```

### 3. Build and Push Application Image

**Option A: AWS ECR**

```bash
# Set variables
export AWS_REGION=ap-southeast-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export IMAGE_NAME=demo-app
export IMAGE_TAG=$(git rev-parse --short HEAD)

# Create ECR repository
aws ecr create-repository --repository-name $IMAGE_NAME --region $AWS_REGION --profile raid-commonsvcs-prod

# Login to ECR
aws ecr get-login-password --region $AWS_REGION --profile raid-commonsvcs-prod | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and push
cd app

# IMPORTANT: For MacBook users (Apple Silicon M1/M2/M3)
# You MUST build for linux/amd64 platform, not ARM64
docker buildx build --platform linux/amd64 \
  -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_NAME:$IMAGE_TAG \
  --push .

cd -
```

**Option B: Docker Hub**

```bash
# Set variables
export DOCKER_USERNAME=your-dockerhub-username
export IMAGE_NAME=demo-app
export IMAGE_TAG=$(git rev-parse --short HEAD)

# Login
docker login

# Build and push
cd app

# IMPORTANT: For MacBook users (Apple Silicon M1/M2/M3)
# You MUST build for linux/amd64 platform
docker buildx build --platform linux/amd64 \
  -t $DOCKER_USERNAME/$IMAGE_NAME:$IMAGE_TAG \
  --push .

cd -
```

### 4. Update Kubernetes Manifest

**IMPORTANT NOTE FOR MACBOOK USERS:**
If you're using Apple Silicon (M1/M2/M3), you MUST use `docker buildx build --platform linux/amd64` instead of regular `docker build`. Otherwise your app will crash with "exec format error" on AMD64 Kubernetes nodes.

```bash
# Update image tag in deployment
export IMAGE_FULL_PATH="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_NAME:$IMAGE_TAG"
# OR for Docker Hub:
# export IMAGE_FULL_PATH="$DOCKER_USERNAME/$IMAGE_NAME:$IMAGE_TAG"

sed -i '' "s|image:.*|image: $IMAGE_FULL_PATH|" k8s/deployment.yaml

# Commit and push
git add k8s/deployment.yaml
git commit -m "Update image tag to $IMAGE_TAG"
git push origin main
```

### 5. Deploy ArgoCD Application

```bash
# Update argocd/application.yaml with your repo URL
# Then apply:
kubectl apply -f argocd/application.yaml

# Watch sync status
kubectl get application -n argocd demo-app -w
```

### 6. Verify Deployment

```bash
# Check application status
kubectl get pods -n demo-app

# Access application
kubectl port-forward -n demo-app svc/demo-app 3000:80

# Visit http://localhost:3000
```

## 🔄 Complete GitOps Workflow Example

### Scenario: Developer Updates Application

**Step 1: Developer makes code change**

```bash
# Create feature branch
git checkout -b feature/update-message

# Edit app/server.js (change welcome message)
# Commit change
git add app/server.js
git commit -m "feat: update welcome message"
git push origin feature/update-message
```

**Step 2: Create Pull Request**

- Open PR on GitHub
- CI pipeline automatically triggers
- Pipeline builds new image with commit SHA tag

**Step 3: CI Pipeline Executes** (see `.github/workflows/ci.yaml`)

```
✓ Checkout code
✓ Build Docker image
✓ Tag image: demo-app:a3f5c21
✓ Push to registry
✓ Update k8s/deployment.yaml with new tag
✓ Commit and push manifest change
```

**Step 4: Merge PR**

```bash
# After approval, merge to main
git checkout main
git pull origin main
```

**Step 5: ArgoCD Detects Change**

```
ArgoCD polls Git repository (every 3 minutes)
├─ Detects new commit in main branch
├─ Compares manifest with cluster state
├─ Status: OutOfSync
└─ Triggers sync (if auto-sync enabled)
```

**Step 6: ArgoCD Syncs Cluster**

```
Sync Operation:
├─ Applies new deployment.yaml
├─ Kubernetes creates new ReplicaSet
├─ New pods created with image: demo-app:a3f5c21
├─ Rolling update: old pods terminated
└─ Status: Synced, Healthy
```

**Step 7: Verify Update**

```bash
# Check rollout status
kubectl rollout status deployment/demo-app -n demo-app

# Verify new image
kubectl get pods -n demo-app -o jsonpath='{.items[0].spec.containers[0].image}'
```

## 🔧 ArgoCD Configuration Explained

### Application Manifest (`argocd/application.yaml`)

```yaml
spec:
  source:
    repoURL: https://github.com/Edgar-Liu/argocd-tutorial.git
    # Git repository to monitor
    
    targetRevision: main
    # Branch, tag, or commit to track
    
    path: k8s
    # Directory containing Kubernetes manifests
  
  destination:
    server: https://kubernetes.default.svc
    # Target cluster (in-cluster)
    
    namespace: demo-app
    # Target namespace
  
  syncPolicy:
    automated:
      prune: true
      # Delete resources not in Git
      
      selfHeal: true
      # Revert manual changes
    
    syncOptions:
    - CreateNamespace=true
      # Auto-create namespace if missing
```

### Sync Policies

**Manual Sync**: Changes require manual approval in UI or CLI
```yaml
syncPolicy: {}
```

**Automatic Sync**: Changes applied automatically
```yaml
syncPolicy:
  automated: {}
```

**Prune**: Remove resources deleted from Git
```yaml
syncPolicy:
  automated:
    prune: true
```

**Self-Heal**: Revert manual cluster changes
```yaml
syncPolicy:
  automated:
    selfHeal: true
```

## 🔍 Understanding Drift

**Drift** occurs when cluster state differs from Git state.

### Example: Manual Change

```bash
# Someone manually scales deployment
kubectl scale deployment demo-app -n demo-app --replicas=5

# ArgoCD detects drift
# Status: OutOfSync

# With selfHeal enabled:
# ArgoCD reverts to Git state (replicas: 3)
# Status: Synced
```

### Drift Detection

ArgoCD compares:
- **Desired State**: Manifests in Git
- **Actual State**: Resources in cluster

Differences trigger OutOfSync status.

## 📊 Monitoring ArgoCD

### CLI Commands

```bash
# Install ArgoCD CLI
brew install argocd  # macOS
# or download from https://github.com/argoproj/argo-cd/releases

# Login
argocd login localhost:8080

# List applications
argocd app list

# Get application details
argocd app get demo-app

# Sync application
argocd app sync demo-app

# View sync history
argocd app history demo-app

# Rollback to previous version
argocd app rollback demo-app
```

### UI Features

- **Application Overview**: Health and sync status
- **Resource Tree**: Visual representation of all resources
- **Sync Status**: Detailed diff between Git and cluster
- **Events**: Timeline of sync operations
- **Logs**: Pod logs directly in UI

## 🎓 Key Concepts

### Image Tag Strategy

**Bad Practice**: Using `latest` tag
```yaml
image: demo-app:latest  # ❌ No version tracking
```

**Good Practice**: Using commit SHA
```yaml
image: demo-app:a3f5c21  # ✅ Immutable, traceable
```

### Git Workflow

1. **Feature Branch**: Develop in isolation
2. **Pull Request**: Code review and CI checks
3. **Merge to Main**: Triggers deployment
4. **ArgoCD Sync**: Automatic cluster update

### Reconciliation

ArgoCD continuously ensures cluster matches Git:
- **Poll Interval**: 3 minutes (configurable)
- **Webhook**: Instant notification (optional)
- **Manual Sync**: On-demand via UI/CLI

## 🐛 Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for common issues and solutions.

## 📖 Additional Resources

- [ArgoCD Official Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://opengitops.dev/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Contributing

This is a tutorial project. Feel free to:
- Open issues for questions
- Submit PRs for improvements
- Fork and customize for your needs

## 📝 License

MIT License - feel free to use for learning and teaching.

---

**Next Steps**: Follow [docs/setup.md](docs/setup.md) for detailed setup instructions.
