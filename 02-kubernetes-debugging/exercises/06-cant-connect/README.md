# Exercise 06: Service Misconfiguration

## Scenario

The pods are running and healthy, but when you try to access the app through the service, you get "connection refused" or no response.

## Deploy

```bash
kubectl apply -f broken.yaml -n debug-$K8S_USERNAME
```

## Observe

```bash
# Pods look fine
kubectl get pods -n debug-$K8S_USERNAME

# But port-forward to the service fails
kubectl port-forward -n debug-$K8S_USERNAME svc/misconfig-app 3002:80
curl http://localhost:3002
# Connection refused or empty response
```

## Your Task

The pods are running. The service exists. But traffic doesn't reach the app. Find **two problems** and fix them.

**Useful commands:**
```bash
kubectl get endpoints misconfig-app -n debug-$K8S_USERNAME
kubectl get svc misconfig-app -n debug-$K8S_USERNAME -o yaml
kubectl get pods -n debug-$K8S_USERNAME --show-labels
```

## Cleanup

```bash
kubectl delete -f broken.yaml -n debug-$K8S_USERNAME
```
