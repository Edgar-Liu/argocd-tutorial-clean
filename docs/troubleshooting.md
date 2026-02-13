# Troubleshooting Guide

Common issues and solutions for the ArgoCD tutorial.

## ArgoCD Issues

### Issue: ArgoCD Application Stuck in "Progressing"

**Symptoms:**
```bash
kubectl get application -n argocd demo-app
# STATUS: Progressing (for more than 5 minutes)
```

**Diagnosis:**
```bash
# Check application details
argocd app get demo-app

# Check pod status
kubectl get pods -n demo-app

# View pod events
kubectl describe pod -n demo-app POD_NAME
```

**Solutions:**

1. **Image pull errors:**
```bash
# Verify image exists
docker pull YOUR_IMAGE:TAG

# Check image pull secrets
kubectl get secrets -n demo-app

# Recreate secret if needed
kubectl delete secret ecr-secret -n demo-app
kubectl create secret docker-registry ecr-secret \
  --docker-server=REGISTRY \
  --docker-username=USERNAME \
  --docker-password=PASSWORD \
  --namespace=demo-app
```

2. **Resource constraints:**
```bash
# Check node resources
kubectl top nodes

# Reduce resource requests in deployment.yaml
```

3. **Failed health checks:**
```bash
# Check logs
kubectl logs -n demo-app -l app=demo-app --tail=50

# Adjust probe timing in deployment.yaml
```

### Issue: Application Shows "OutOfSync" but Won't Sync

**Symptoms:**
```bash
argocd app get demo-app
# Sync Status: OutOfSync
# Auto-sync enabled but not syncing
```

**Solutions:**

1. **Manual sync:**
```bash
argocd app sync demo-app --force
```

2. **Check sync policy:**
```bash
# Verify automated sync is enabled
kubectl get application demo-app -n argocd -o yaml | grep -A 5 syncPolicy
```

3. **Check application controller:**
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=100
```

4. **Refresh application:**
```bash
argocd app get demo-app --refresh --hard-refresh
```

### Issue: "Unknown" Health Status

**Symptoms:**
```bash
argocd app get demo-app
# Health Status: Unknown
```

**Cause:** ArgoCD doesn't recognize resource type or health check failed

**Solutions:**

1. **Check resource definitions:**
```bash
kubectl get all -n demo-app
```

2. **Verify CRDs installed:**
```bash
kubectl get crd
```

3. **Check ArgoCD version compatibility:**
```bash
argocd version
```

### Issue: Cannot Access ArgoCD UI

**Symptoms:**
- Browser shows "Connection refused"
- Port forward not working

**Solutions:**

1. **Verify ArgoCD is running:**
```bash
kubectl get pods -n argocd
# All pods should be Running
```

2. **Check port forward:**
```bash
# Kill existing port forwards
pkill -f "port-forward.*argocd"

# Start new port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

3. **Try different port:**
```bash
kubectl port-forward svc/argocd-server -n argocd 9090:443
# Access at https://localhost:9090
```

4. **Check service:**
```bash
kubectl get svc -n argocd argocd-server
```

### Issue: Forgot ArgoCD Admin Password

**Solution:**
```bash
# Get initial password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Or reset password
kubectl -n argocd delete secret argocd-initial-admin-secret
kubectl -n argocd rollout restart deployment argocd-server

# Wait for restart, then get new password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Kubernetes Issues

### Issue: Pods in CrashLoopBackOff

**Diagnosis:**
```bash
# Check pod status
kubectl get pods -n demo-app

# View logs
kubectl logs -n demo-app POD_NAME

# Check previous container logs
kubectl logs -n demo-app POD_NAME --previous

# Describe pod
kubectl describe pod -n demo-app POD_NAME
```

**Common Causes:**

1. **Application error:**
```bash
# Check application logs for errors
kubectl logs -n demo-app -l app=demo-app --tail=100
```

2. **Missing dependencies:**
```bash
# Verify all required secrets/configmaps exist
kubectl get secrets,configmaps -n demo-app
```

3. **Port already in use:**
```bash
# Check if port is exposed correctly
kubectl get svc -n demo-app
```

### Issue: ImagePullBackOff

**Symptoms:**
```bash
kubectl get pods -n demo-app
# STATUS: ImagePullBackOff or ErrImagePull
```

**Diagnosis:**
```bash
kubectl describe pod -n demo-app POD_NAME
# Look for "Failed to pull image" message
```

**Solutions:**

1. **Verify image exists:**
```bash
# For ECR
aws ecr describe-images --repository-name demo-app --region us-east-1

# For Docker Hub
docker pull YOUR_USERNAME/demo-app:TAG
```

2. **Check image name in deployment:**
```bash
kubectl get deployment demo-app -n demo-app -o yaml | grep image:
```

3. **Verify registry credentials:**
```bash
# Check secret exists
kubectl get secret -n demo-app

# Test credentials manually
docker login YOUR_REGISTRY
```

4. **For ECR, refresh credentials:**
```bash
# ECR tokens expire after 12 hours
kubectl delete secret ecr-secret -n demo-app

aws ecr get-login-password --region us-east-1 | \
  kubectl create secret docker-registry ecr-secret \
  --docker-server=ACCOUNT.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password-stdin \
  --namespace=demo-app
```

### Issue: Service Not Accessible

**Symptoms:**
- Cannot access application via port-forward
- Connection timeout

**Diagnosis:**
```bash
# Check service
kubectl get svc -n demo-app

# Check endpoints
kubectl get endpoints -n demo-app

# Verify pods are ready
kubectl get pods -n demo-app
```

**Solutions:**

1. **Verify selector matches:**
```bash
# Check service selector
kubectl get svc demo-app -n demo-app -o yaml | grep -A 2 selector

# Check pod labels
kubectl get pods -n demo-app --show-labels
```

2. **Test from within cluster:**
```bash
# Create test pod
kubectl run test-pod --image=curlimages/curl -n demo-app --rm -it -- sh

# Inside pod:
curl http://demo-app.demo-app.svc.cluster.local
```

3. **Check network policies:**
```bash
kubectl get networkpolicies -n demo-app
```

## Docker Issues

### Issue: Docker Build Fails

**Common Errors:**

1. **"Cannot find module":**
```bash
# Ensure package.json is copied before npm install
# Check Dockerfile order
```

2. **"Permission denied":**
```bash
# Check file permissions
ls -la app/

# Fix permissions
chmod +x app/server.js
```

3. **"No space left on device":**
```bash
# Clean up Docker
docker system prune -a --volumes

# Check disk space
df -h
```

### Issue: Docker Push Fails

**Solutions:**

1. **Authentication error:**
```bash
# For ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

# For Docker Hub
docker login
```

2. **Repository doesn't exist:**
```bash
# Create ECR repository
aws ecr create-repository --repository-name demo-app --region us-east-1

# Or create on Docker Hub website
```

3. **Network timeout:**
```bash
# Retry push
docker push YOUR_IMAGE:TAG

# Or increase timeout
export DOCKER_CLIENT_TIMEOUT=300
export COMPOSE_HTTP_TIMEOUT=300
```

## Git Issues

### Issue: Push Rejected

**Error:**
```
! [rejected]        main -> main (fetch first)
```

**Solution:**
```bash
# Pull latest changes
git pull origin main --rebase

# Resolve conflicts if any
# Then push
git push origin main
```

### Issue: Merge Conflicts

**Solution:**
```bash
# Update your branch
git fetch origin
git merge origin/main

# View conflicts
git status

# Edit conflicted files
# Look for <<<<<<< HEAD markers

# After resolving
git add .
git commit -m "chore: resolve merge conflicts"
git push origin your-branch
```

### Issue: Accidentally Committed Secrets

**Immediate Action:**
```bash
# DO NOT just delete the file and commit
# The secret is still in Git history

# Remove from history (if not pushed yet)
git reset --soft HEAD~1
git restore --staged SENSITIVE_FILE
echo "SENSITIVE_FILE" >> .gitignore
git add .gitignore
git commit -m "chore: remove sensitive file"

# If already pushed, rotate the credentials immediately
# Then use git-filter-repo or BFG Repo-Cleaner
```

## CI/CD Issues

### Issue: GitHub Actions Workflow Fails

**Diagnosis:**
```bash
# View logs on GitHub
# Go to Actions tab → Click failed workflow
```

**Common Failures:**

1. **Missing secrets:**
```
Error: AWS credentials not found
```
**Solution:** Add secrets in GitHub Settings → Secrets

2. **Docker build fails:**
```bash
# Test build locally
cd app
docker build -t test .
```

3. **Git push fails:**
```
Permission denied (publickey)
```
**Solution:** Ensure workflow has write permissions in workflow YAML

### Issue: Image Tag Not Updating

**Diagnosis:**
```bash
# Check if CI ran
# View GitHub Actions logs

# Check if manifest was updated
git log -1 k8s/deployment.yaml
```

**Solutions:**

1. **CI didn't run:**
- Check workflow triggers in `.github/workflows/ci.yaml`
- Ensure branch name matches trigger

2. **Manifest not committed:**
- Check CI logs for commit step
- Verify GitHub token has write permissions

## Performance Issues

### Issue: ArgoCD Slow to Sync

**Solutions:**

1. **Enable webhooks:**
```bash
# Configure webhook in GitHub
# Settings → Webhooks → Add webhook
# Payload URL: https://ARGOCD_URL/api/webhook
# Content type: application/json
# Events: Just the push event
```

2. **Reduce poll interval:**
```bash
# Edit argocd-cm configmap
kubectl edit configmap argocd-cm -n argocd

# Add:
# data:
#   timeout.reconciliation: 60s  # Default is 180s
```

3. **Optimize repository size:**
```bash
# Use shallow clones
# In application.yaml, add:
# source:
#   repoURL: ...
#   targetRevision: main
#   path: k8s
#   helm:
#     skipCrds: true
```

### Issue: High Memory Usage

**ArgoCD consuming too much memory:**

```bash
# Check resource usage
kubectl top pods -n argocd

# Increase limits
kubectl edit deployment argocd-server -n argocd
# Increase memory limits

# Or reduce tracked applications
```

## Debugging Commands

### Comprehensive Health Check

```bash
#!/bin/bash
echo "=== ArgoCD Status ==="
kubectl get pods -n argocd
echo ""

echo "=== Application Status ==="
argocd app get demo-app
echo ""

echo "=== Demo App Pods ==="
kubectl get pods -n demo-app
echo ""

echo "=== Recent Events ==="
kubectl get events -n demo-app --sort-by='.lastTimestamp' | tail -10
echo ""

echo "=== Service Endpoints ==="
kubectl get endpoints -n demo-app
```

### View All Logs

```bash
# ArgoCD application controller
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=50

# ArgoCD server
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=50

# Demo app
kubectl logs -n demo-app -l app=demo-app --tail=50 --all-containers=true
```

## Getting Help

### Collect Diagnostic Information

```bash
# ArgoCD version
argocd version

# Kubernetes version
kubectl version

# Application details
argocd app get demo-app > app-details.txt

# Pod descriptions
kubectl describe pods -n demo-app > pod-details.txt

# Logs
kubectl logs -n demo-app -l app=demo-app --tail=200 > app-logs.txt
```

### Useful Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD GitHub Issues](https://github.com/argoproj/argo-cd/issues)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)

### Reset Everything

If all else fails:

```bash
# Delete application
kubectl delete -f argocd/application.yaml

# Delete namespace
kubectl delete namespace demo-app

# Restart ArgoCD
kubectl rollout restart deployment -n argocd

# Wait for restart
kubectl wait --for=condition=ready pod --all -n argocd --timeout=300s

# Redeploy
kubectl apply -f argocd/application.yaml
```
