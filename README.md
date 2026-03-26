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
├── app/                          # Example application
│   ├── server.js                # Simple Node.js web server
│   ├── package.json             # Node dependencies
│   └── Dockerfile               # Container image definition
├── k8s/                          # Kubernetes manifests
│   └── base/
│       ├── deployment.yaml      # Application deployment
│       ├── service.yaml         # Service definition
│       └── kustomization.yaml   # Kustomize configuration
├── argocd/                       # ArgoCD configuration
│   └── application.yaml         # ArgoCD Application manifest (template)
├── .github/                      # CI/CD pipelines
│   └── workflows/
│       ├── ci-dockerhub.yaml    # CI for Docker Hub (KIND guide)
│       └── ci-ecr.yaml          # CI for ECR (EKS guide)
├── docs/                         # Tutorial guides
│   ├── guide-kind.md            # KIND + Docker Hub guide
│   └── guide-eks.md             # EKS + ECR guide
└── README.md                    # This file
```

## 🏃 Choose Your Guide

Pick the guide that matches your setup:

### Option A: [KIND + Docker Hub](docs/guide-kind.md) (Recommended for Learning)

- ✅ No cloud account needed
- ✅ Runs entirely on your laptop
- ✅ Free (Docker Hub free tier)
- ✅ Quick setup (~10 minutes)
- Uses: KIND cluster + Docker Hub for images

### Option B: [EKS + ECR](docs/guide-eks.md) (Production-like)

- ✅ Real cloud environment
- ✅ Uses AWS services (ECR, EKS, IAM OIDC)
- ✅ Closer to production workflows
- Requires: AWS account + existing EKS cluster

Both guides follow the same progression:
1. Install ArgoCD
2. Clone repo and create personal branch
3. Build and push v1 image
4. Deploy with ArgoCD (GitOps!)
5. Update to v2 and watch ArgoCD auto-sync
6. Enable CI/CD for automated deployments

## 👥 For Junior Engineers

Each engineer gets their own isolated environment:
- **Personal branch**: `$GITHUB_USERNAME` (e.g., `john-doe`)
- **Personal namespace**: `demo-app-$K8S_USERNAME` (e.g., `demo-app-john-doe`)
- **Personal CI/CD**: Triggers only on YOUR branch
- **Personal container repo**: `demo-app-$USERNAME`

No conflicts between team members!

## 📖 Additional Resources

- [ArgoCD Official Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://opengitops.dev/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 📝 License

MIT License - feel free to use for learning and teaching.
