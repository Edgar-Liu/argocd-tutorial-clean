#!/bin/bash

# Helper script to deploy with your local values
# Usage: ./deploy-local.sh

set -e

if [ ! -f k8s/overlays/local/kustomization.yaml ]; then
  echo "❌ k8s/overlays/local/kustomization.yaml not found!"
  echo "Copy k8s/overlays/local/kustomization.yaml.example and update with your values"
  exit 1
fi

echo "📦 Deploying with local overlay..."

# Apply using kustomize
kubectl apply -k k8s/overlays/local/

echo "✅ Deployed successfully!"
echo ""
echo "Check status:"
echo "  kubectl get pods -n demo-app"
