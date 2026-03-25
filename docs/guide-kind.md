# Guide: KIND Cluster + Docker Hub

A hands-on tutorial using a local KIND cluster with Docker Hub for container images.

> **💡 NOTE:** KIND runs on your Mac's native architecture, so you do NOT need `--platform linux/amd64`.  
> Regular `docker build` works fine. The `--platform linux/amd64` flag is only needed for remote clusters (EKS) with AMD64 nodes.

## Prerequisites

- Docker installed
- Git installed
- GitHub account
- Docker Hub account ([sign up free](https://hub.docker.com/signup))

## Step 1: Install KIND and Create Cluster

```bash
# Install KIND
brew install kind

# Create a cluster
kind create cluster --name argocd-tutorial

# Verify
kubectl cluster-info --context kind-argocd-tutorial
```

## Step 2: Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods (takes 2-3 minutes)
kubectl wait --for=condition=ready pod --all -n argocd --timeout=300s

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

**Access ArgoCD UI:**
```bash
# In a separate terminal, keep this running
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open: https://localhost:8080
# Username: admin
# Password: (from command above)
```

## Step 3: Fork and Clone Repository

1. Fork this repo on GitHub: https://github.com/Edgar-Liu/argocd-tutorial-clean
2. Clone your fork and create your personal branch:

```bash
# Set your GitHub username (REQUIRED - replace with your actual username)
export GITHUB_USERNAME=your-github-username

# Set your Docker Hub username (REQUIRED - replace with your actual username)
export DOCKERHUB_USERNAME=your-dockerhub-username

# Clone your fork
git clone https://github.com/$GITHUB_USERNAME/argocd-tutorial-clean.git
cd argocd-tutorial-clean

# Create your personal branch (use your name, e.g., john-doe)
export BRANCH_NAME=$GITHUB_USERNAME
git checkout -b $BRANCH_NAME
```

> **💡 IMPORTANT:** Keep this terminal window open throughout the tutorial! If you close it, you'll need to re-export all variables.

## Step 4: Build and Push Initial Image (v1)

```bash
export IMAGE_TAG=v1

# Login to Docker Hub
docker login -u $DOCKERHUB_USERNAME

# Build and push
cd app
docker build -t $DOCKERHUB_USERNAME/demo-app:$IMAGE_TAG .
docker push $DOCKERHUB_USERNAME/demo-app:$IMAGE_TAG
cd ..
```

## Step 5: Update Manifests

```bash
# Verify your variables are set
echo "GITHUB_USERNAME: $GITHUB_USERNAME"
echo "DOCKERHUB_USERNAME: $DOCKERHUB_USERNAME"
# If empty, re-export them from Step 3

# Normalize username for Kubernetes (lowercase, replace underscores/dots with hyphens)
export K8S_USERNAME=$(echo $GITHUB_USERNAME | tr '[:upper:]' '[:lower:]' | tr '_.' '-')

# Update image in deployment
sed -i '' "s|image:.*|image: $DOCKERHUB_USERNAME/demo-app:$IMAGE_TAG|" k8s/base/deployment.yaml
sed -i '' "s|value: \".*\" # IMAGE_TAG|value: \"$IMAGE_TAG\" # IMAGE_TAG|" k8s/base/deployment.yaml

# Update ArgoCD application with your GitHub username and branch
sed -i '' "s|YOUR_USERNAME|$GITHUB_USERNAME|" argocd/application.yaml
sed -i '' "s|targetRevision: main|targetRevision: $BRANCH_NAME|" argocd/application.yaml
sed -i '' "s|  name: demo-app|  name: demo-app-$K8S_USERNAME|" argocd/application.yaml
sed -i '' "s|    namespace: demo-app|    namespace: demo-app-$K8S_USERNAME|" argocd/application.yaml

# Verify changes
echo "\n=== Deployment image ==="
grep -E "image:|IMAGE_TAG" k8s/base/deployment.yaml
echo "\n=== ArgoCD config ==="
grep -E "name:|repoURL|targetRevision|namespace:" argocd/application.yaml | head -6
echo ""

# IMPORTANT: Verify everything shows YOUR username and branch, not placeholders
```

## Step 6: Commit and Deploy with ArgoCD

```bash
# Commit and push to YOUR branch
git add k8s/base/deployment.yaml argocd/application.yaml
git commit -m "Initial setup with image $IMAGE_TAG"
git push -u origin $BRANCH_NAME

# Create ArgoCD application (this will deploy the app)
kubectl apply -f argocd/application.yaml

# Watch ArgoCD create the namespace and deploy pods (takes 1-2 minutes)
kubectl get pods -n demo-app-$K8S_USERNAME -w
```

**What's happening:**
- ArgoCD reads your Git repo (your branch: `$BRANCH_NAME`)
- Creates the `demo-app-$K8S_USERNAME` namespace
- Deploys all resources from `k8s/base/`
- Pods start running

**Expected output:**
```
NAME                       READY   STATUS              RESTARTS   AGE
demo-app-646f6fdc9b-8j25v  0/1     ContainerCreating   0          5s
demo-app-646f6fdc9b-hf4ts  0/1     ContainerCreating   0          5s
demo-app-646f6fdc9b-lm92j  0/1     ContainerCreating   0          5s
demo-app-646f6fdc9b-8j25v  1/1     Running             0          30s
demo-app-646f6fdc9b-hf4ts  1/1     Running             0          30s
demo-app-646f6fdc9b-lm92j  1/1     Running             0          30s
```

## Step 7: Test the Application (v1)

```bash
# Port forward (in separate terminal)
kubectl port-forward -n demo-app-$K8S_USERNAME svc/demo-app 3000:80

# Test
curl http://localhost:3000
```

**Expected response:**
```json
{
  "message": "Welcome to ArgoCD Tutorial Demo App!",
  "version": "v1.0.0",
  "imageTag": "v1",
  "hostname": "demo-app-646f6fdc9b-8j25v",
  "timestamp": "2026-02-13T05:30:00.000Z"
}
```

✅ **Success!** Your GitOps setup is working with v1!

## Step 8: Update to v2 and Watch ArgoCD Sync

Now let's update to v2 and see ArgoCD automatically detect and deploy the change:

```bash
# 1. Build and push v2 image
export IMAGE_TAG=v2
cd app
docker build -t $DOCKERHUB_USERNAME/demo-app:$IMAGE_TAG .
docker push $DOCKERHUB_USERNAME/demo-app:$IMAGE_TAG
cd ..

# 2. Update deployment manifest (image and IMAGE_TAG env var)
sed -i '' "s|image:.*|image: $DOCKERHUB_USERNAME/demo-app:$IMAGE_TAG|" k8s/base/deployment.yaml
sed -i '' "s|value: \".*\" # IMAGE_TAG|value: \"$IMAGE_TAG\" # IMAGE_TAG|" k8s/base/deployment.yaml

# 3. Verify the update
grep -E "image:|IMAGE_TAG" k8s/base/deployment.yaml

# 4. Commit and push
git add k8s/base/deployment.yaml
git commit -m "Update to $IMAGE_TAG"
git pull --rebase origin $BRANCH_NAME
git push origin $BRANCH_NAME

# 5. Watch ArgoCD detect and sync (within 3 minutes)
kubectl get pods -n demo-app-$K8S_USERNAME -w
```

**Test the v2 update:**
```bash
curl http://localhost:3000
```

**Expected response:**
```json
{
  "message": "Welcome to ArgoCD Tutorial Demo App!",
  "version": "v1.0.0",
  "imageTag": "v2",
  "hostname": "demo-app-7d8f9c6b5-x7z9k",
  "timestamp": "2026-02-13T06:00:00.000Z"
}
```

🎉 **You just experienced GitOps!**
- Changed manifest in Git (v1 → v2)
- ArgoCD detected the change
- Automatically synced to Kubernetes
- Notice `imageTag` changed from `v1` to `v2`

> **💡 Deploying further updates (v3, v4, etc.):**  
> Repeat Step 8 with a new `IMAGE_TAG` value each time. The sed commands use wildcard patterns (`image:.*` and `value: ".*"`), so they work regardless of the current tag. Just change `export IMAGE_TAG=v3` and run the same commands.

## Step 9: Enable CI/CD for Your Branch (Optional)

Set up automated builds so every code change triggers CI/CD.

### 9a: Add GitHub Secrets

1. Go to: `https://github.com/$GITHUB_USERNAME/argocd-tutorial-clean/settings/secrets/actions`
2. Add two secrets:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username
   - `DOCKERHUB_TOKEN`: Your Docker Hub access token ([create one here](https://hub.docker.com/settings/security))

### 9b: Enable the CI Workflow for Your Branch

```bash
# Update CI workflow to watch YOUR branch
sed -i '' "s|YOUR_BRANCH_NAME|$BRANCH_NAME|" .github/workflows/ci-dockerhub.yaml

# Verify the change
grep "branches:" -A 1 .github/workflows/ci-dockerhub.yaml

# Commit and push
git add .github/workflows/ci-dockerhub.yaml
git commit -m "Enable CI/CD for $BRANCH_NAME"
git pull --rebase origin $BRANCH_NAME
git push origin $BRANCH_NAME
```

## Step 10: Test Automated CI/CD

Now let's make a code change and watch the full automation:

```bash
# 1. Make a code change
sed -i '' 's/Welcome to ArgoCD Tutorial Demo App!/Welcome to ArgoCD with CI\/CD!/' app/server.js

# 2. Commit and push (CI will build image with Git SHA tag)
git add app/server.js
git commit -m "feat: update welcome message"
git pull --rebase origin $BRANCH_NAME
git push origin $BRANCH_NAME

# 3. Watch GitHub Actions build and push
# Go to: https://github.com/$GITHUB_USERNAME/argocd-tutorial-clean/actions

# 4. After CI completes, watch ArgoCD sync (within 3 minutes)
kubectl get pods -n demo-app-$K8S_USERNAME -w
```

**Test the CI/CD update:**
```bash
curl http://localhost:3000
```

**Expected response:**
```json
{
  "message": "Welcome to ArgoCD with CI/CD!",
  "version": "v1.0.0",
  "imageTag": "a3f5c21",
  "hostname": "demo-app-9f8e7d6c5-b4a3z",
  "timestamp": "2026-02-13T07:00:00.000Z"
}
```

🚀 **You just experienced automated GitOps!**
- Code change → Git → CI builds image (Git SHA tag) → CI updates manifest → ArgoCD syncs → Pods updated
- Notice `imageTag` is now the Git commit SHA (`a3f5c21`), not a manual version!

## Cleanup

```bash
# Delete ArgoCD application
kubectl delete application -n argocd demo-app-$K8S_USERNAME

# Delete KIND cluster
kind delete cluster --name argocd-tutorial
```
