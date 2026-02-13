#!/bin/bash

set -e

# Script to update image tag in Kubernetes deployment manifest
# Usage: ./update-image.sh <new-image-tag>

if [ -z "$1" ]; then
  echo "Usage: $0 <image-tag>"
  echo "Example: $0 a3f5c21"
  exit 1
fi

NEW_TAG=$1
DEPLOYMENT_FILE="k8s/deployment.yaml"

# Detect OS for sed compatibility
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  SED_CMD="sed -i ''"
else
  # Linux
  SED_CMD="sed -i"
fi

echo "Updating image tag to: $NEW_TAG"

# Update the image line in deployment.yaml
# This assumes your image line looks like: image: <registry>/<repo>:<tag>
$SED_CMD "s|image:.*|image: ${IMAGE_REGISTRY}/${IMAGE_NAME}:${NEW_TAG}|" $DEPLOYMENT_FILE

echo "✓ Updated $DEPLOYMENT_FILE"
echo ""
echo "Next steps:"
echo "  git add $DEPLOYMENT_FILE"
echo "  git commit -m 'Update image tag to $NEW_TAG'"
echo "  git push origin main"
