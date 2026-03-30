# Exercise 03: OOMKilled

## Scenario

The app starts but gets killed almost immediately, and keeps restarting.

## Deploy

```bash
kubectl apply -f broken.yaml -n debug-$K8S_USERNAME
```

## Observe

```bash
kubectl get pods -n debug-$K8S_USERNAME -w
```

## Your Task

Figure out **why** the pod is being killed and fix it.

**Useful commands:**
```bash
kubectl describe pod <POD_NAME> -n debug-$K8S_USERNAME
kubectl logs <POD_NAME> -n debug-$K8S_USERNAME --previous
```

## Cleanup

```bash
kubectl delete -f broken.yaml -n debug-$K8S_USERNAME
```
