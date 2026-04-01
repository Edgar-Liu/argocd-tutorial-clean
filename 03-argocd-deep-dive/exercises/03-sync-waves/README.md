# Exercise 03: Sync Waves

## Why Sync Waves?

Some resources need to exist before others. For example:
- ConfigMaps and Secrets must exist before the Deployment that references them
- A database must be ready before the app that connects to it
- A Service should be created after the Deployment has healthy pods

Sync waves let you control the order ArgoCD deploys resources.

## How Sync Waves Work

Add an annotation to each resource:
```yaml
annotations:
  argocd.argoproj.io/sync-wave: "0"   # Deployed first
```

- Lower numbers deploy first
- Resources in the same wave deploy together
- ArgoCD waits for each wave to be healthy before starting the next

## Setup

```bash
# Update manifests with your details
sed -i '' "s|DOCKERHUB_USERNAME|$DOCKERHUB_USERNAME|" app.yaml
sed -i '' "s|YOUR_BRANCH|$BRANCH_NAME|" argocd-app.yaml
sed -i '' "s|ARGOCD_APP_NAME|wave-app-$K8S_USERNAME|" argocd-app.yaml
sed -i '' "s|ARGOCD_NAMESPACE|wave-$K8S_USERNAME|" argocd-app.yaml
sed -i '' "s|ARGOCD_MODULE_LABEL|argocd-deep-dive-$K8S_USERNAME|" argocd-app.yaml

# Commit and push
git add .
git commit -m "Setup sync waves exercise"
git push origin $BRANCH_NAME

# Deploy
kubectl apply -f argocd-app.yaml
```

## Exercise

### Part 1: Observe the Deployment Order

Open the ArgoCD UI at https://localhost:8080 and click on the `wave-app-$K8S_USERNAME` application.

Watch the sync — you'll see resources deploy in order:

```
Wave 0: ConfigMap (app-config) + Secret (app-secret)
    ↓ waits until healthy
Wave 1: Deployment (wave-app)
    ↓ waits until healthy
Wave 2: Service (wave-app)
```

Verify from the CLI:
```bash
# Check all resources
kubectl get configmap,secret,deployment,svc -n wave-$K8S_USERNAME

# The app has access to the config
kubectl port-forward -n wave-$K8S_USERNAME svc/wave-app 3004:80
curl http://localhost:3004
```

### Part 2: Examine the Annotations

Look at `app.yaml` and find the sync wave annotations:

```bash
grep -B 2 "sync-wave" app.yaml
```

Notice:
- ConfigMap and Secret: `sync-wave: "0"` (deployed first)
- Deployment: `sync-wave: "1"` (deployed after config exists)
- Service: `sync-wave: "2"` (deployed after pods are ready)

### Part 3: What Happens Without Sync Waves?

Without sync waves, ArgoCD deploys everything simultaneously. This can cause:
- Pods crash because ConfigMap doesn't exist yet
- Service has no endpoints because pods aren't ready
- Race conditions between dependent resources

Sync waves eliminate these timing issues.

## Key Takeaways

- Use `argocd.argoproj.io/sync-wave` annotation to control deployment order
- Lower numbers deploy first, ArgoCD waits for health between waves
- Common pattern: `0` = config/secrets, `1` = deployments, `2` = services/ingress
- Without sync waves, everything deploys simultaneously (risky for dependent resources)

## Cleanup

```bash
kubectl delete application wave-app-$K8S_USERNAME -n argocd
```
