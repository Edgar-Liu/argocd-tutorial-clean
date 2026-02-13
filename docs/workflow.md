# Git Workflow Guide

Complete GitOps workflow examples demonstrating how code changes propagate to production.

## Overview

This guide demonstrates a complete development cycle:
1. Developer makes code change
2. CI builds and pushes Docker image
3. CI updates Kubernetes manifest
4. ArgoCD detects change
5. ArgoCD syncs to cluster

## Workflow 1: Feature Development

### Step 1: Create Feature Branch

```bash
# Update main branch
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/update-welcome-message

# Verify branch
git branch
```

### Step 2: Make Code Changes

```bash
# Edit the application
cat > app/server.js << 'EOF'
const express = require('express');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.VERSION || 'v1.0.0';

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from ArgoCD! This is an updated message.',
    version: VERSION,
    hostname: os.hostname(),
    timestamp: new Date().toISOString(),
    environment: 'production'
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Version: ${VERSION}`);
});
EOF
```

### Step 3: Test Locally

```bash
# Build Docker image
cd app
docker build -t demo-app:test .

# Run container
docker run -d -p 3000:3000 --name demo-app-test demo-app:test

# Test endpoint
curl http://localhost:3000

# Clean up
docker stop demo-app-test
docker rm demo-app-test
cd ..
```

### Step 4: Commit Changes

```bash
# Stage changes
git add app/server.js

# Commit with conventional commit message
git commit -m "feat: update welcome message with environment info"

# View commit
git log -1 --oneline
```

### Step 5: Push and Create PR

```bash
# Push feature branch
git push origin feature/update-welcome-message

# Output example:
# Enumerating objects: 7, done.
# Counting objects: 100% (7/7), done.
# Delta compression using up to 8 threads
# Compressing objects: 100% (4/4), done.
# Writing objects: 100% (4/4), 456 bytes | 456.00 KiB/s, done.
# Total 4 (delta 2), reused 0 (delta 0), pack-reused 0
# To github.com:YOUR_USERNAME/argocd-tutorial.git
#  * [new branch]      feature/update-welcome-message -> feature/update-welcome-message
```

Create PR on GitHub:
- Go to repository
- Click "Compare & pull request"
- Fill in PR details
- Submit PR

### Step 6: CI Pipeline Executes

GitHub Actions automatically runs:

```
Run CI/CD Pipeline
├─ Checkout code ✓
├─ Set up Docker Buildx ✓
├─ Generate image tag: a3f5c21 ✓
├─ Login to registry ✓
├─ Build Docker image ✓
│  Step 1/8 : FROM node:18-alpine
│  Step 2/8 : WORKDIR /app
│  Step 3/8 : COPY package*.json ./
│  Step 4/8 : RUN npm install --production
│  Step 5/8 : COPY server.js ./
│  Step 6/8 : EXPOSE 3000
│  Step 7/8 : USER node
│  Step 8/8 : CMD ["npm", "start"]
│  Successfully built 9a8b7c6d5e4f
├─ Push to registry ✓
│  a3f5c21: digest: sha256:abc123... size: 1234
└─ Comment on PR ✓
   "Docker image built successfully!"
```

### Step 7: Review and Merge

```bash
# After approval, merge PR on GitHub
# Then update local main branch
git checkout main
git pull origin main

# Delete feature branch
git branch -d feature/update-welcome-message
git push origin --delete feature/update-welcome-message
```

### Step 8: CI Updates Manifest

After merge to main, CI pipeline:

```
Run CI/CD Pipeline (main branch)
├─ Build and push image: demo-app:a3f5c21 ✓
├─ Update k8s/deployment.yaml ✓
│  - image: 123456789.dkr.ecr.us-east-1.amazonaws.com/demo-app:old-tag
│  + image: 123456789.dkr.ecr.us-east-1.amazonaws.com/demo-app:a3f5c21
├─ Commit changes ✓
│  [main b7c8d9e] chore: update image tag to a3f5c21 [skip ci]
│   1 file changed, 1 insertion(+), 1 deletion(-)
└─ Push to repository ✓
```

### Step 9: ArgoCD Detects Change

```bash
# ArgoCD polls repository (within 3 minutes)
# Or trigger manual refresh:
argocd app get demo-app --refresh

# Output:
# Name:               demo-app
# Project:            default
# Server:             https://kubernetes.default.svc
# Namespace:          demo-app
# URL:                https://localhost:8080/applications/demo-app
# Repo:               https://github.com/YOUR_USERNAME/argocd-tutorial.git
# Target:             main
# Path:               k8s
# SyncWindow:         Sync Allowed
# Sync Policy:        Automated (Prune)
# Sync Status:        OutOfSync from main (b7c8d9e)
# Health Status:      Healthy
```

### Step 10: ArgoCD Syncs Cluster

```bash
# Watch sync in real-time
argocd app sync demo-app --watch

# Output:
# TIMESTAMP           GROUP        KIND         NAMESPACE  NAME      STATUS    HEALTH   HOOK  MESSAGE
# 2024-01-15T10:30:00 apps         Deployment   demo-app   demo-app  OutOfSync Healthy        
# 2024-01-15T10:30:01 apps         Deployment   demo-app   demo-app  Synced    Progressing    
# 2024-01-15T10:30:15 apps         Deployment   demo-app   demo-app  Synced    Healthy        

# Verify new pods
kubectl get pods -n demo-app -o wide

# Check image version
kubectl get pods -n demo-app -o jsonpath='{.items[0].spec.containers[0].image}'
# Output: 123456789.dkr.ecr.us-east-1.amazonaws.com/demo-app:a3f5c21
```

### Step 11: Verify Deployment

```bash
# Port forward to service
kubectl port-forward -n demo-app svc/demo-app 3000:80

# Test new version
curl http://localhost:3000

# Expected output:
# {
#   "message": "Hello from ArgoCD! This is an updated message.",
#   "version": "v1.0.0",
#   "hostname": "demo-app-7d8f9c6b5-x7z9k",
#   "timestamp": "2024-01-15T10:35:00.000Z",
#   "environment": "production"
# }
```

## Workflow 2: Hotfix

### Emergency Production Fix

```bash
# Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/fix-health-endpoint

# Make fix
# Edit app/server.js to fix health check

# Commit
git add app/server.js
git commit -m "fix: correct health endpoint response"

# Push
git push origin hotfix/fix-health-endpoint

# Create PR with "hotfix" label
# Fast-track review and merge
```

## Workflow 3: Rollback

### Scenario: Bad Deployment

```bash
# View deployment history
argocd app history demo-app

# Output:
# ID  DATE                           REVISION
# 1   2024-01-15 09:00:00 +0000 UTC  a1b2c3d (Initial deployment)
# 2   2024-01-15 10:30:00 +0000 UTC  b7c8d9e (Update welcome message)
# 3   2024-01-15 11:00:00 +0000 UTC  e4f5g6h (Bad deployment)

# Rollback to previous version
argocd app rollback demo-app 2

# Or revert Git commit
git revert HEAD
git push origin main
# ArgoCD will automatically sync the revert
```

## Workflow 4: Manual Image Update

### Without CI Pipeline

```bash
# Build new image
export IMAGE_TAG=$(git rev-parse --short HEAD)
docker build -t YOUR_REGISTRY/demo-app:$IMAGE_TAG app/
docker push YOUR_REGISTRY/demo-app:$IMAGE_TAG

# Update manifest
./scripts/update-image.sh $IMAGE_TAG

# Commit and push
git add k8s/deployment.yaml
git commit -m "chore: update image to $IMAGE_TAG"
git push origin main

# ArgoCD will detect and sync automatically
```

## Workflow 5: Multi-Environment

### Separate Branches for Environments

```
main (production)
├── staging
└── development
```

```bash
# Deploy to development
git checkout development
git merge feature/new-feature
git push origin development

# ArgoCD app for dev watches 'development' branch

# Promote to staging
git checkout staging
git merge development
git push origin staging

# Promote to production
git checkout main
git merge staging
git push origin main
```

## Common Git Commands

### View Commit History

```bash
# Last 10 commits
git log --oneline -10

# Commits affecting k8s/
git log --oneline -- k8s/

# Show file changes in commit
git show COMMIT_HASH
```

### Compare Branches

```bash
# See differences between branches
git diff main..feature/new-feature

# See only changed files
git diff --name-only main..feature/new-feature
```

### Sync Fork with Upstream

```bash
# Add upstream remote (once)
git remote add upstream https://github.com/ORIGINAL_OWNER/argocd-tutorial.git

# Fetch upstream changes
git fetch upstream

# Merge into your main
git checkout main
git merge upstream/main
git push origin main
```

## Best Practices

### Commit Messages

Use conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `chore:` Maintenance
- `docs:` Documentation
- `refactor:` Code refactoring
- `test:` Tests

Examples:
```bash
git commit -m "feat: add metrics endpoint"
git commit -m "fix: resolve memory leak in handler"
git commit -m "chore: update image tag to a3f5c21"
```

### Branch Naming

- `feature/description` - New features
- `fix/description` - Bug fixes
- `hotfix/description` - Emergency fixes
- `chore/description` - Maintenance

### Pull Request Workflow

1. Create feature branch
2. Make changes and commit
3. Push and create PR
4. Wait for CI checks
5. Request review
6. Address feedback
7. Merge when approved
8. Delete branch

### Image Tagging Strategy

**Good:**
- Git commit SHA: `a3f5c21`
- Semantic version: `v1.2.3`
- Build number: `build-456`

**Bad:**
- `latest` (not immutable)
- `dev` (ambiguous)
- `prod` (not versioned)

## Troubleshooting

### CI Pipeline Fails

```bash
# View GitHub Actions logs
# Go to: https://github.com/YOUR_USERNAME/argocd-tutorial/actions

# Re-run failed job
# Click on failed workflow → Re-run jobs
```

### Merge Conflicts

```bash
# Update your branch with main
git checkout feature/your-feature
git fetch origin
git merge origin/main

# Resolve conflicts in editor
# Then:
git add .
git commit -m "chore: resolve merge conflicts"
git push origin feature/your-feature
```

### ArgoCD Not Syncing

```bash
# Force refresh
argocd app get demo-app --refresh --hard-refresh

# Manual sync
argocd app sync demo-app

# Check application controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=100
```

## Next Steps

- Set up branch protection rules
- Configure required status checks
- Implement code review requirements
- Add automated testing
- Set up deployment notifications
