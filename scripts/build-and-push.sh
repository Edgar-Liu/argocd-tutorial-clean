#!/bin/bash

set -e

# Build and push script for demo application
# Usage: ./build-and-push.sh [tag]

# Load environment variables if .env exists
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

# Use provided tag or generate from git commit
IMAGE_TAG=${1:-$(git rev-parse --short HEAD)}

echo "Building and pushing demo-app:$IMAGE_TAG"
echo ""

# Detect registry type
if [ -n "$AWS_ACCOUNT_ID" ] && [ -n "$AWS_REGION" ]; then
  echo "Using AWS ECR"
  REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
  
  # Login to ECR
  echo "Logging in to ECR..."
  aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin $REGISTRY
  
elif [ -n "$DOCKER_USERNAME" ]; then
  echo "Using Docker Hub"
  REGISTRY="docker.io/$DOCKER_USERNAME"
  
  # Login to Docker Hub
  echo "Logging in to Docker Hub..."
  docker login
  
else
  echo "Error: No registry configured"
  echo "Set AWS_ACCOUNT_ID and AWS_REGION for ECR"
  echo "Or set DOCKER_USERNAME for Docker Hub"
  exit 1
fi

IMAGE_FULL_PATH="$REGISTRY/${IMAGE_NAME:-demo-app}:$IMAGE_TAG"

# Build image
echo ""
echo "Building image: $IMAGE_FULL_PATH"
docker build -t $IMAGE_FULL_PATH app/

# Push image
echo ""
echo "Pushing image: $IMAGE_FULL_PATH"
docker push $IMAGE_FULL_PATH

echo ""
echo "✓ Successfully built and pushed: $IMAGE_FULL_PATH"
echo ""
echo "Next steps:"
echo "  1. Update k8s/deployment.yaml with new image"
echo "  2. Commit and push changes"
echo "  3. ArgoCD will automatically sync"
