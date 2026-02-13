# MacBook (Apple Silicon) Users Guide

## Critical Issue: Architecture Mismatch

If you're using a MacBook with Apple Silicon (M1, M2, M3), you **MUST** build Docker images for the correct architecture.

### The Problem

- Your MacBook uses **ARM64** architecture
- Most Kubernetes clusters use **AMD64** (x86_64) architecture
- If you build with regular `docker build`, it creates ARM64 images
- These will **FAIL** on AMD64 clusters with: `exec format error`

### The Solution

**Always use `docker buildx` with `--platform linux/amd64`:**

```bash
# ❌ WRONG - builds for ARM64
docker build -t myimage:tag .

# ✅ CORRECT - builds for AMD64
docker buildx build --platform linux/amd64 -t myimage:tag --push .
```

## Complete Build Instructions

### For AWS ECR

```bash
export AWS_REGION=ap-southeast-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export IMAGE_NAME=demo-app
export IMAGE_TAG=$(git rev-parse --short HEAD)

# Login to ECR
aws ecr get-login-password --region $AWS_REGION --profile YOUR_PROFILE | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build for AMD64 and push
cd app
docker buildx build --platform linux/amd64 \
  -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_NAME:$IMAGE_TAG \
  --push .
cd ..
```

### For Docker Hub

```bash
export DOCKER_USERNAME=your-dockerhub-username
export IMAGE_NAME=demo-app
export IMAGE_TAG=$(git rev-parse --short HEAD)

# Login
docker login

# Build for AMD64 and push
cd app
docker buildx build --platform linux/amd64 \
  -t $DOCKER_USERNAME/$IMAGE_NAME:$IMAGE_TAG \
  --push .
cd ..
```

## Setup Docker Buildx (First Time Only)

If `docker buildx` doesn't work, set it up:

```bash
# Create a new builder
docker buildx create --name multiarch --use

# Verify it works
docker buildx inspect --bootstrap
```

## Troubleshooting

### Error: "exec format error"

**Symptom:**
```bash
kubectl logs -n demo-app POD_NAME
# Output: exec /usr/local/bin/docker-entrypoint.sh: exec format error
```

**Cause:** You built an ARM64 image but your cluster needs AMD64.

**Fix:**
1. Rebuild with `--platform linux/amd64`
2. Use a new tag (e.g., `v1-amd64`)
3. Update deployment manifest
4. Push to Git
5. Let ArgoCD sync

### Verify Image Architecture

```bash
# Check what architecture your image has
docker buildx imagetools inspect YOUR_IMAGE:TAG

# Look for:
# Platform: linux/amd64  ✅ Correct
# Platform: linux/arm64  ❌ Wrong for most clusters
```

### Force Kubernetes to Pull New Image

If you rebuilt but pods still crash:

```bash
# Delete pods to force recreation
kubectl delete pods -n demo-app --all

# Or use image digest to force pull
kubectl set image deployment/demo-app -n demo-app \
  demo-app=YOUR_IMAGE@sha256:DIGEST_HERE
```

## Why This Happens

Docker on Apple Silicon defaults to building images for the host architecture (ARM64). When you push these to a registry and deploy to an AMD64 Kubernetes cluster, the binaries are incompatible.

The `--platform linux/amd64` flag tells Docker to cross-compile for AMD64 instead.

## Best Practice

**Always specify the platform explicitly:**

```bash
# In your build scripts
docker buildx build --platform linux/amd64 ...

# Or build for multiple platforms
docker buildx build --platform linux/amd64,linux/arm64 ...
```

## Quick Reference

```bash
# Build for AMD64 (most common)
docker buildx build --platform linux/amd64 -t IMAGE:TAG --push .

# Build for both AMD64 and ARM64
docker buildx build --platform linux/amd64,linux/arm64 -t IMAGE:TAG --push .

# Check image architecture
docker buildx imagetools inspect IMAGE:TAG

# Test locally with AMD64 emulation
docker run --platform linux/amd64 IMAGE:TAG
```

## Additional Resources

- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [Multi-platform Images](https://docs.docker.com/build/building/multi-platform/)
- [Apple Silicon Docker Issues](https://docs.docker.com/desktop/mac/apple-silicon/)
