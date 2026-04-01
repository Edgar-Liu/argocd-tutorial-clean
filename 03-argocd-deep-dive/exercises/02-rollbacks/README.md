# Exercise 02: Rollbacks

## Why Rollbacks Matter

Bad deployments happen. You need to know how to quickly revert to a working version. ArgoCD gives you multiple rollback strategies.

## Setup

```bash
# Update manifests with your details
sed -i '' "s|DOCKERHUB_USERNAME|$DOCKERHUB_USERNAME|" app.yaml
sed -i '' "s|YOUR_BRANCH|$BRANCH_NAME|" argocd-app.yaml
sed -i '' "s|ARGOCD_APP_NAME|rollback-app-$K8S_USERNAME|" argocd-app.yaml
sed -i '' "s|ARGOCD_NAMESPACE|rollback-$K8S_USERNAME|" argocd-app.yaml
sed -i '' "s|ARGOCD_MODULE_LABEL|argocd-deep-dive-$K8S_USERNAME|" argocd-app.yaml

# Commit and push
git add .
git commit -m "Setup rollback exercise"
git push origin $BRANCH_NAME

# Deploy
kubectl apply -f argocd-app.yaml

# Wait for pods
kubectl get pods -n rollback-$K8S_USERNAME -w
```

Verify the app works:
```bash
kubectl port-forward -n rollback-$K8S_USERNAME svc/rollback-app 3003:80
curl http://localhost:3003
# Should return a JSON response
```

## Exercise

### Part 1: Deploy a Bad Version

Simulate a bad deployment by changing the image to one that doesn't exist:

```bash
# Break the deployment
sed -i '' "s|image:.*|image: $DOCKERHUB_USERNAME/demo-app:bad-version|" app.yaml

# Commit and push
git add app.yaml
git commit -m "Deploy bad version"
git push origin $BRANCH_NAME

# Watch the pods fail (within 3 minutes)
kubectl get pods -n rollback-$K8S_USERNAME -w
```

You should see new pods stuck in `ImagePullBackOff` while old pods are still running (Kubernetes keeps old pods until new ones are ready).

### Part 2: Rollback via Git Revert

The GitOps way to rollback — revert the commit:

```bash
# Revert the last commit
git revert HEAD --no-edit

# Push the revert
git push origin $BRANCH_NAME

# Watch ArgoCD sync the revert (within 3 minutes)
kubectl get pods -n rollback-$K8S_USERNAME -w
```

Verify it's working again:
```bash
curl http://localhost:3003
```

### Part 3: View Sync History

```bash
# Check ArgoCD sync history
kubectl get application rollback-app-$K8S_USERNAME -n argocd -o jsonpath='{.status.history}' | python3 -m json.tool
```

You'll see the history of syncs — the original deploy, the bad deploy, and the revert.

### Part 4: Rollback via ArgoCD CLI (Optional)

If you have the ArgoCD CLI installed:

```bash
# Install ArgoCD CLI (if not already)
brew install argocd

# Login
argocd login localhost:8080 --insecure

# View history
argocd app history rollback-app-$K8S_USERNAME

# Rollback to a specific revision
argocd app rollback rollback-app-$K8S_USERNAME <REVISION_ID>
```

> **Note:** ArgoCD CLI rollback is temporary — the next Git sync will override it. Git revert (Part 2) is the recommended approach because it keeps Git as the source of truth.

## Key Takeaways

- **Git revert** is the preferred rollback method — it maintains Git as source of truth
- **ArgoCD CLI rollback** is quick but temporary — next sync overrides it
- Kubernetes keeps old pods running during a bad deployment (if readiness probes are configured)
- Always check sync history to understand what changed

## Cleanup

```bash
kubectl delete application rollback-app-$K8S_USERNAME -n argocd
```
