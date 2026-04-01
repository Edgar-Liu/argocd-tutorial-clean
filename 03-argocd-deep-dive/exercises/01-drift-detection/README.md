# Exercise 01: Drift Detection & Self-Heal

## What is Drift?

Drift occurs when someone makes a manual change to the cluster that doesn't match what's in Git. ArgoCD can detect this and automatically revert it.

## Setup

```bash
# Update the app manifest with your Docker Hub image
sed -i '' "s|DOCKERHUB_USERNAME|$DOCKERHUB_USERNAME|" app.yaml

# Update the ArgoCD application with your details
sed -i '' "s|YOUR_BRANCH|$BRANCH_NAME|" argocd-app.yaml
sed -i '' "s|ARGOCD_APP_NAME|drift-app-$K8S_USERNAME|" argocd-app.yaml
sed -i '' "s|ARGOCD_NAMESPACE|drift-$K8S_USERNAME|" argocd-app.yaml
sed -i '' "s|ARGOCD_MODULE_LABEL|argocd-deep-dive-$K8S_USERNAME|" argocd-app.yaml

# Commit and push (ArgoCD reads from Git)
git add .
git commit -m "Setup drift detection exercise"
git push origin $BRANCH_NAME

# Deploy the ArgoCD application
kubectl apply -f argocd-app.yaml

# Wait for pods
kubectl get pods -n drift-$K8S_USERNAME -w
```

## Exercise

### Part 1: Scale Drift

ArgoCD says 2 replicas. Let's manually change it to 5.

```bash
# Manually scale to 5 replicas
kubectl scale deployment drift-app -n drift-$K8S_USERNAME --replicas=5

# Quickly check - you'll see 5 pods briefly
kubectl get pods -n drift-$K8S_USERNAME

# Wait 30 seconds, then check again
sleep 30
kubectl get pods -n drift-$K8S_USERNAME
```

**What happened?** ArgoCD detected the drift and reverted back to 2 replicas.

Check the ArgoCD UI at https://localhost:8080 — you'll see a sync event showing it corrected the drift.

### Part 2: Environment Variable Drift

```bash
# Manually change an environment variable
kubectl set env deployment/drift-app -n drift-$K8S_USERNAME VERSION=hacked

# Watch what happens
kubectl get pods -n drift-$K8S_USERNAME -w
```

**What happened?** ArgoCD detected the env var change and redeployed with the original value from Git.

### Part 3: Delete a Resource

```bash
# Delete the service
kubectl delete svc drift-app -n drift-$K8S_USERNAME

# Check if it comes back
sleep 30
kubectl get svc -n drift-$K8S_USERNAME
```

**What happened?** ArgoCD recreated the service because it's defined in Git.

### Part 4: Disable Self-Heal

What if you WANT manual changes to stick? Edit `argocd-app.yaml` and change:

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: false    # Changed from true
```

```bash
# Apply the change
kubectl apply -f argocd-app.yaml

# Now scale manually
kubectl scale deployment drift-app -n drift-$K8S_USERNAME --replicas=5

# Wait and check - it should stay at 5
sleep 30
kubectl get pods -n drift-$K8S_USERNAME
```

**What happened?** With `selfHeal: false`, ArgoCD shows the app as `OutOfSync` but doesn't revert it. You'd need to manually sync from the UI or CLI.

```bash
# Check sync status
kubectl get application drift-app-$K8S_USERNAME -n argocd
# Should show OutOfSync
```

## Key Takeaways

- `selfHeal: true` — ArgoCD automatically reverts manual changes (recommended for production)
- `selfHeal: false` — ArgoCD detects drift but waits for manual sync
- Git is always the source of truth
- Any manual `kubectl` change is temporary when self-heal is enabled

## Cleanup

```bash
kubectl delete application drift-app-$K8S_USERNAME -n argocd
```
