# Module 03: ArgoCD Deep Dive

> **Prerequisite:** Complete [Module 01](../01-gitops-basics/) and [Module 02](../02-kubernetes-debugging/) first. Uses the same cluster and ArgoCD installation.

Explore advanced ArgoCD features that make GitOps powerful in production.

## What You'll Learn

- How ArgoCD detects and reverts manual changes (drift detection)
- Rolling back bad deployments via CLI and Git
- Controlling deployment order with sync waves
- Managing multiple applications with the App of Apps pattern

## Setup

```bash
# Set your variables (same as Module 01)
export GITHUB_USERNAME=your-github-username
export DOCKERHUB_USERNAME=your-dockerhub-username
export K8S_USERNAME=$(echo $GITHUB_USERNAME | tr '[:upper:]' '[:lower:]' | tr '_.' '-')
export BRANCH_NAME=$GITHUB_USERNAME

# Navigate to this module
cd 03-argocd-deep-dive

# Verify ArgoCD is running
kubectl get pods -n argocd
```

## Exercises

| # | Exercise | What You'll Experience |
|---|----------|----------------------|
| 01 | [Drift Detection](exercises/01-drift-detection/) | Make manual changes, watch ArgoCD revert them |
| 02 | [Rollbacks](exercises/02-rollbacks/) | Deploy a bad version, learn to roll back |
| 03 | [Sync Waves](exercises/03-sync-waves/) | Control the order resources are deployed |
| 04 | [App of Apps](exercises/04-app-of-apps/) | Manage multiple apps from one parent |

## Cleanup

```bash
# Exercises include their own cleanup steps
# To remove everything from this module:
kubectl delete applications -n argocd -l module=argocd-deep-dive-$K8S_USERNAME
```

## Next Module

Once you've completed all exercises, proceed to [Module 04: Kustomize](../04-kustomize/).
