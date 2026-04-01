# Exercise 04: App of Apps

## What is App of Apps?

Instead of creating each ArgoCD Application manually, you create one **parent** Application that manages **child** Applications. The parent watches a directory of Application manifests in Git.

```
Parent Application (watches apps/ directory)
├── frontend Application → deploys frontend manifests
└── backend Application  → deploys backend manifests
```

When you add a new app YAML to the `apps/` directory, the parent automatically creates it. Delete the YAML, and the parent removes it. One place to manage everything.

## Setup

```bash
# Update all manifests with your details
# Child app definitions
sed -i '' "s|YOUR_BRANCH|$BRANCH_NAME|g" apps/frontend.yaml apps/backend.yaml
sed -i '' "s|CHILD_APP_PREFIX|aoa-$K8S_USERNAME|g" apps/frontend.yaml apps/backend.yaml
sed -i '' "s|ARGOCD_NAMESPACE|aoa-$K8S_USERNAME|g" apps/frontend.yaml apps/backend.yaml
sed -i '' "s|ARGOCD_MODULE_LABEL|argocd-deep-dive-$K8S_USERNAME|g" apps/frontend.yaml apps/backend.yaml

# Parent app
sed -i '' "s|YOUR_BRANCH|$BRANCH_NAME|" parent-app.yaml
sed -i '' "s|ARGOCD_APP_NAME|aoa-parent-$K8S_USERNAME|" parent-app.yaml
sed -i '' "s|ARGOCD_MODULE_LABEL|argocd-deep-dive-$K8S_USERNAME|" parent-app.yaml

# App manifests
sed -i '' "s|DOCKERHUB_USERNAME|$DOCKERHUB_USERNAME|" manifests/frontend/app.yaml manifests/backend/app.yaml

# Commit and push
git add .
git commit -m "Setup app of apps exercise"
git push origin $BRANCH_NAME

# Deploy ONLY the parent — it creates everything else
kubectl apply -f parent-app.yaml
```

## Exercise

### Part 1: Watch the Cascade

Open the ArgoCD UI at https://localhost:8080.

You'll see:
1. `aoa-parent-$K8S_USERNAME` — the parent app (syncs the `apps/` directory)
2. `aoa-$K8S_USERNAME-frontend` — created automatically by the parent
3. `aoa-$K8S_USERNAME-backend` — created automatically by the parent

Each child app deploys its own resources:
```bash
kubectl get pods -n aoa-$K8S_USERNAME
# Should see frontend and backend pods
```

### Part 2: Add a New App via Git

Create a new child app by adding a YAML file to the `apps/` directory:

```bash
cat > apps/cache.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: aoa-$K8S_USERNAME-cache
  namespace: argocd
  labels:
    app: cache
    module: argocd-deep-dive-$K8S_USERNAME
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/Edgar-Liu/argocd-tutorial-clean.git
    targetRevision: $BRANCH_NAME
    path: 03-argocd-deep-dive/exercises/04-app-of-apps/manifests/frontend
  destination:
    server: https://kubernetes.default.svc
    namespace: aoa-$K8S_USERNAME
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# Commit and push
git add apps/cache.yaml
git commit -m "Add cache app"
git push origin $BRANCH_NAME
```

Within 3 minutes, check the ArgoCD UI — a new `aoa-$K8S_USERNAME-cache` application appears automatically!

```bash
kubectl get pods -n aoa-$K8S_USERNAME
# Now shows frontend, backend, AND cache pods
```

### Part 3: Remove an App via Git

```bash
# Delete the cache app definition
rm apps/cache.yaml

# Commit and push
git add -A
git commit -m "Remove cache app"
git push origin $BRANCH_NAME
```

Within 3 minutes, the parent detects the deletion and removes the cache application and all its resources.

```bash
kubectl get pods -n aoa-$K8S_USERNAME
# Back to just frontend and backend
```

## Key Takeaways

- **One parent** manages all child applications — single point of control
- **Add an app** = add a YAML file to the apps directory and push
- **Remove an app** = delete the YAML file and push (prune removes it)
- In production, teams use this to manage dozens of microservices from one repo
- The parent app only creates ArgoCD Applications — each child handles its own deployment

## Cleanup

```bash
# Delete the parent — it cascades and deletes all children
kubectl delete application aoa-parent-$K8S_USERNAME -n argocd
```
