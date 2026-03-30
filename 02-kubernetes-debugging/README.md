# Module 02: Kubernetes Debugging & Troubleshooting

> **Prerequisite:** Complete [Module 01: GitOps Basics](../01-gitops-basics/) first. Uses the same cluster.

Learn to diagnose and fix common Kubernetes issues using intentionally broken deployments.

## What You'll Learn

- Reading pod status, events, and logs
- Diagnosing CrashLoopBackOff, ImagePullBackOff, OOMKilled
- Fixing pending pods (resource constraints)
- Debugging probes and service connectivity
- Using `kubectl describe`, `kubectl logs`, and `kubectl get events`

## Setup

```bash
# Set your variables (same as Module 01)
export GITHUB_USERNAME=your-github-username
export DOCKERHUB_USERNAME=your-dockerhub-username
export K8S_USERNAME=$(echo $GITHUB_USERNAME | tr '[:upper:]' '[:lower:]' | tr '_.' '-')

# Navigate to this module
cd 02-kubernetes-debugging

# Create your personal debugging namespace
kubectl create namespace debug-$K8S_USERNAME

# Update all exercises to use YOUR Docker Hub image
find exercises -name 'broken.yaml' -exec sed -i '' "s|image: .*/demo-app|image: $DOCKERHUB_USERNAME/demo-app|" {} \;

# Verify
grep 'image:' exercises/*/broken.yaml
```

## Exercises

Work through these in order. Each exercise deploys a broken manifest — your job is to figure out what's wrong and fix it.

| # | Exercise | Symptom | Difficulty |
|---|----------|---------|------------|
| 01 | [App Won't Start](exercises/01-app-wont-start/) | Pod keeps restarting | ⭐ |
| 02 | [Stuck Deploying](exercises/02-stuck-deploying/) | Pod never starts | ⭐ |
| 03 | [App Keeps Dying](exercises/03-app-keeps-dying/) | Pod gets killed repeatedly | ⭐⭐ |
| 04 | [Nothing Happens](exercises/04-nothing-happens/) | Pod stuck, no progress | ⭐⭐ |
| 05 | [App Not Reachable](exercises/05-app-not-reachable/) | Pod running but broken | ⭐⭐ |
| 06 | [Can't Connect](exercises/06-cant-connect/) | Everything looks fine but... | ⭐⭐⭐ |

## How Each Exercise Works

1. Read the scenario in the exercise README
2. Deploy the broken manifest: `kubectl apply -f broken.yaml`
3. Observe the symptoms: `kubectl get pods -n debug-$K8S_USERNAME`
4. Diagnose using kubectl commands (hints provided if you're stuck)
5. Fix the manifest and re-deploy
6. Verify it's working

## Essential Debugging Commands

```bash
# Check pod status
kubectl get pods -n debug-$K8S_USERNAME

# Detailed pod info (events at the bottom are key!)
kubectl describe pod <POD_NAME> -n debug-$K8S_USERNAME

# View container logs
kubectl logs <POD_NAME> -n debug-$K8S_USERNAME

# View logs from a crashed container
kubectl logs <POD_NAME> -n debug-$K8S_USERNAME --previous

# View namespace events (sorted by time)
kubectl get events -n debug-$K8S_USERNAME --sort-by='.lastTimestamp'

# Check node resources
kubectl top nodes
```

## Cleanup

```bash
kubectl delete namespace debug-$K8S_USERNAME
```

## Next Module

Once you've completed all exercises, proceed to [Module 03: ArgoCD Deep Dive](../03-argocd-deep-dive/).
