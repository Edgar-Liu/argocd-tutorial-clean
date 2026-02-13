# Beginner's Quick Start

## Step 1: Set Up Local Cluster (5 minutes)

```bash
# Install kind
brew install kind  # macOS
# or for Linux: curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64

# Create cluster
kind create cluster --name argocd-tutorial

# Verify
kubectl get nodes
```

## Step 2: Install ArgoCD (5 minutes)

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods (takes 2-3 minutes)
kubectl wait --for=condition=ready pod --all -n argocd --timeout=300s

# Check status
kubectl get pods -n argocd
```

## Step 3: Access ArgoCD UI (2 minutes)

```bash
# In one terminal, start port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# In another terminal, get password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Open browser: https://localhost:8080
# Username: admin
# Password: (from above command)
```

## Step 4: Prepare Your Application (10 minutes)

```bash
# You need a container registry - choose one:

# Option A: Docker Hub (easiest)
docker login
export DOCKER_USERNAME=your-dockerhub-username
export IMAGE_NAME=demo-app
export IMAGE_TAG=v1

# Option B: AWS ECR
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr create-repository --repository-name demo-app --region $AWS_REGION
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

## Step 5: Build and Push Image (5 minutes)

```bash
# Build the demo app
cd app
docker build -t $DOCKER_USERNAME/demo-app:v1 .

# Push to registry
docker push $DOCKER_USERNAME/demo-app:v1

# Go back to repo root
cd ..
```

## Step 6: Update Kubernetes Manifest (2 minutes)

```bash
# Update the image in deployment
sed -i '' "s|image:.*|image: $DOCKER_USERNAME/demo-app:v1|" k8s/deployment.yaml

# Verify the change
grep "image:" k8s/deployment.yaml

# Commit (if you forked the repo)
git add k8s/deployment.yaml
git commit -m "chore: update image to v1"
git push origin main
```

## Step 7: Deploy with ArgoCD (5 minutes)

```bash
# Update the ArgoCD application with your GitHub username
# Edit argocd/application.yaml and change YOUR_USERNAME to your actual username

# Apply the ArgoCD application
kubectl apply -f argocd/application.yaml

# Watch it sync
kubectl get application -n argocd demo-app -w
```

## Step 8: Verify It Works (2 minutes)

```bash
# Check pods
kubectl get pods -n demo-app

# Port forward to the app
kubectl port-forward -n demo-app svc/demo-app 3000:80

# Test it (in another terminal)
curl http://localhost:3000

# You should see:
# {
#   "message": "Welcome to ArgoCD Tutorial Demo App!",
#   "version": "v1.0.0",
#   ...
# }
```

## 🎉 Success!

You now have:
- ✅ Local Kubernetes cluster
- ✅ ArgoCD installed and running
- ✅ Your first application deployed via GitOps
- ✅ Understanding of the basic workflow

## What to Try Next

1. **Make a change**: Edit `app/server.js`, rebuild, push, update manifest
2. **Watch ArgoCD sync**: See it automatically deploy your change
3. **Try drift detection**: Manually scale pods, watch ArgoCD revert it
4. **Practice rollback**: Use `argocd app history` and `argocd app rollback`

## Common Issues

**Pods not starting?**
```bash
kubectl describe pod -n demo-app POD_NAME
kubectl logs -n demo-app POD_NAME
```

**ArgoCD UI not accessible?**
```bash
# Kill old port-forward
pkill -f "port-forward.*argocd"
# Start new one
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Image pull errors?**
```bash
# Verify image exists
docker pull $DOCKER_USERNAME/demo-app:v1

# Check if you're logged in
docker login
```

## Learning Resources

- Full setup: [docs/setup.md](docs/setup.md)
- Git workflows: [docs/workflow.md](docs/workflow.md)
- Troubleshooting: [docs/troubleshooting.md](docs/troubleshooting.md)
- Quick commands: [docs/quick-reference.md](docs/quick-reference.md)

## Time Estimate

- Total setup time: ~30-40 minutes
- Understanding concepts: ~30 minutes
- First deployment: ~10 minutes
- Experimenting: As long as you want!

Good luck! 🚀
