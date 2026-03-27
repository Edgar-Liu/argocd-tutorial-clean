# Kubernetes & ArgoCD Learning Path

A hands-on, sequential learning path for Kubernetes and GitOps with ArgoCD.

## 🗺️ Learning Path

| Module | Topic | What You'll Learn |
|--------|-------|-------------------|
| [01 - GitOps Basics](01-gitops-basics/) | ArgoCD + GitOps | Deploy apps with ArgoCD, CI/CD pipelines, auto-sync |
| [02 - Kubernetes Debugging](02-kubernetes-debugging/) | Troubleshooting | Diagnose CrashLoopBackOff, OOMKilled, networking issues |
| [03 - ArgoCD Deep Dive](03-argocd-deep-dive/) | Advanced ArgoCD | Drift detection, rollbacks, sync waves, App of Apps |
| [04 - Helm + ArgoCD](04-helm-argocd/) | Helm Charts | Deploy Helm charts via ArgoCD, multi-environment configs |

## 🏁 Getting Started

1. Start with **Module 01** — choose either the [KIND (local)](01-gitops-basics/docs/guide-kind.md) or [EKS (AWS)](01-gitops-basics/docs/guide-eks.md) guide
2. Keep your cluster running — each module builds on the previous one
3. Work through the modules in order

## 👥 For Learners

Each engineer gets their own isolated environment:
- **Personal branch**: `$GITHUB_USERNAME`
- **Personal namespace**: `demo-app-$K8S_USERNAME`
- **Personal CI/CD**: Triggers only on YOUR branch

No conflicts between team members!

## 📖 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GitOps Principles](https://opengitops.dev/)

## 📝 License

MIT License - feel free to use for learning and teaching.
