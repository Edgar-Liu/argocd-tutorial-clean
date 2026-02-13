# Setup Checklist

Use this checklist to ensure you've completed all setup steps correctly.

## Prerequisites ✓

- [ ] Kubernetes cluster is running
  ```bash
  kubectl cluster-info
  ```

- [ ] kubectl is installed and configured
  ```bash
  kubectl version --client
  ```

- [ ] Docker is installed
  ```bash
  docker --version
  ```

- [ ] Git is installed
  ```bash
  git --version
  ```

- [ ] AWS CLI installed (if using ECR)
  ```bash
  aws --version
  ```

## ArgoCD Installation ✓

- [ ] ArgoCD namespace created
  ```bash
  kubectl get namespace argocd
  ```

- [ ] ArgoCD installed
  ```bash
  kubectl get pods -n argocd
  ```

- [ ] All ArgoCD pods are Running
  ```bash
  kubectl wait --for=condition=ready pod --all -n argocd --timeout=300s
  ```

- [ ] ArgoCD UI is accessible
  ```bash
  kubectl port-forward svc/argocd-server -n argocd 8080:443
  # Visit https://localhost:8080
  ```

- [ ] ArgoCD admin password retrieved
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  ```

- [ ] ArgoCD CLI installed (optional)
  ```bash
  argocd version
  ```

## Repository Setup ✓

- [ ] Repository forked on GitHub
  - Visit: https://github.com/ORIGINAL_OWNER/argocd-tutorial
  - Click "Fork"

- [ ] Repository cloned locally
  ```bash
  git clone https://github.com/YOUR_USERNAME/argocd-tutorial.git
  cd argocd-tutorial
  ```

- [ ] All files present
  ```bash
  ls -la app/ k8s/ argocd/ scripts/ docs/
  ```

## Container Registry Setup ✓

### Option A: AWS ECR

- [ ] ECR repository created
  ```bash
  aws ecr describe-repositories --repository-name demo-app --region us-east-1
  ```

- [ ] Logged into ECR
  ```bash
  aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.us-east-1.amazonaws.com
  ```

### Option B: Docker Hub

- [ ] Docker Hub account created
- [ ] Logged into Docker Hub
  ```bash
  docker login
  ```

## Application Build ✓

- [ ] Environment variables set
  ```bash
  # For ECR:
  export AWS_REGION=us-east-1
  export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  export IMAGE_NAME=demo-app
  export IMAGE_TAG=$(git rev-parse --short HEAD)
  
  # For Docker Hub:
  export DOCKER_USERNAME=your-username
  export IMAGE_NAME=demo-app
  export IMAGE_TAG=$(git rev-parse --short HEAD)
  ```

- [ ] Docker image built
  ```bash
  cd app
  docker build -t REGISTRY/demo-app:TAG .
  ```

- [ ] Docker image pushed
  ```bash
  docker push REGISTRY/demo-app:TAG
  ```

- [ ] Image verified in registry
  ```bash
  # For ECR:
  aws ecr describe-images --repository-name demo-app --region us-east-1
  
  # For Docker Hub:
  docker pull YOUR_USERNAME/demo-app:TAG
  ```

## Kubernetes Manifests ✓

- [ ] Deployment manifest updated with correct image
  ```bash
  grep "image:" k8s/deployment.yaml
  # Should show your registry and image tag
  ```

- [ ] Changes committed to Git
  ```bash
  git add k8s/deployment.yaml
  git commit -m "chore: update image to TAG"
  ```

- [ ] Changes pushed to GitHub
  ```bash
  git push origin main
  ```

## ArgoCD Application ✓

- [ ] ArgoCD application manifest updated with your GitHub username
  ```bash
  grep "repoURL" argocd/application.yaml
  # Should show: https://github.com/YOUR_USERNAME/argocd-tutorial.git
  ```

- [ ] ArgoCD application created
  ```bash
  kubectl apply -f argocd/application.yaml
  ```

- [ ] Application appears in ArgoCD
  ```bash
  kubectl get application -n argocd demo-app
  ```

- [ ] Application is syncing
  ```bash
  argocd app get demo-app
  # Check Sync Status and Health Status
  ```

## Deployment Verification ✓

- [ ] demo-app namespace created
  ```bash
  kubectl get namespace demo-app
  ```

- [ ] Pods are running
  ```bash
  kubectl get pods -n demo-app
  # All pods should be Running
  ```

- [ ] Service is created
  ```bash
  kubectl get svc -n demo-app
  ```

- [ ] Application is healthy in ArgoCD
  ```bash
  argocd app get demo-app
  # Health Status: Healthy
  # Sync Status: Synced
  ```

- [ ] Application responds correctly
  ```bash
  kubectl port-forward -n demo-app svc/demo-app 3000:80
  curl http://localhost:3000
  # Should return JSON with welcome message
  ```

- [ ] Health endpoint works
  ```bash
  curl http://localhost:3000/health
  # Should return: {"status":"healthy"}
  ```

## CI/CD Setup (Optional) ✓

- [ ] GitHub secrets configured
  - Go to: Settings → Secrets and variables → Actions
  - For ECR: Add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
  - For Docker Hub: Add `DOCKER_USERNAME` and `DOCKER_PASSWORD`

- [ ] GitHub variables configured (if using ECR)
  - Go to: Settings → Secrets and variables → Actions → Variables
  - Add `USE_ECR` = `true`

- [ ] CI workflow file present
  ```bash
  cat .github/workflows/ci.yaml
  ```

- [ ] Test CI pipeline
  ```bash
  git checkout -b test-ci
  echo "# Test" >> README.md
  git add README.md
  git commit -m "test: trigger CI"
  git push origin test-ci
  # Check Actions tab on GitHub
  ```

## Final Checks ✓

- [ ] Can access ArgoCD UI
  - URL: https://localhost:8080
  - Login with admin credentials

- [ ] Application visible in UI
  - Navigate to Applications
  - See "demo-app" with Healthy status

- [ ] Can view application logs
  ```bash
  kubectl logs -n demo-app -l app=demo-app --tail=20
  ```

- [ ] Can manually sync application
  ```bash
  argocd app sync demo-app
  ```

- [ ] Documentation reviewed
  - [ ] Read README.md
  - [ ] Read docs/setup.md
  - [ ] Read docs/workflow.md
  - [ ] Bookmark docs/troubleshooting.md
  - [ ] Bookmark docs/quick-reference.md

## Test GitOps Workflow ✓

- [ ] Make code change
  ```bash
  git checkout -b feature/test-update
  # Edit app/server.js
  ```

- [ ] Commit and push
  ```bash
  git add app/server.js
  git commit -m "feat: test update"
  git push origin feature/test-update
  ```

- [ ] Create pull request on GitHub

- [ ] CI pipeline runs successfully

- [ ] Merge pull request

- [ ] ArgoCD detects change
  ```bash
  argocd app get demo-app --refresh
  ```

- [ ] ArgoCD syncs automatically
  ```bash
  kubectl get pods -n demo-app -w
  # Watch pods rolling update
  ```

- [ ] Verify new version deployed
  ```bash
  curl http://localhost:3000
  # Should show updated message
  ```

## Troubleshooting ✓

If any step fails, refer to:
- [docs/troubleshooting.md](docs/troubleshooting.md) - Common issues and solutions
- [docs/quick-reference.md](docs/quick-reference.md) - Quick command reference
- [docs/examples.md](docs/examples.md) - Example outputs

## Success Criteria

You've successfully completed the setup when:

✅ ArgoCD is running and accessible
✅ Application is deployed and healthy
✅ Application responds to HTTP requests
✅ ArgoCD shows "Synced" and "Healthy" status
✅ You can make changes and see them deployed automatically

## Next Steps

1. Explore ArgoCD UI features
2. Try the workflows in [docs/workflow.md](docs/workflow.md)
3. Experiment with manual changes and drift detection
4. Set up webhooks for instant sync
5. Review [docs/advanced.md](docs/advanced.md) for production features

## Clean Up (When Done)

To remove everything:

```bash
# Delete ArgoCD application
kubectl delete -f argocd/application.yaml

# Delete demo-app namespace
kubectl delete namespace demo-app

# Uninstall ArgoCD
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd

# Delete ECR repository (if using AWS)
aws ecr delete-repository --repository-name demo-app --region us-east-1 --force

# Delete local cluster (if using kind/minikube)
kind delete cluster --name argocd-tutorial
# or
minikube delete
```

---

**Congratulations!** 🎉

You now have a fully functional GitOps setup with ArgoCD!
