# Exercise 04: Pending Pods

## Scenario

A deployment was created but the pod never starts — it's stuck in `Pending` forever.

## Deploy

```bash
kubectl apply -f broken.yaml -n debug-$K8S_USERNAME
```

## Observe

```bash
kubectl get pods -n debug-$K8S_USERNAME -w
```

You should see the pod stuck in `Pending` status.

## Your Task

Figure out **why** the pod can't be scheduled and fix it.

**Useful commands:**
```bash
kubectl describe pod <POD_NAME> -n debug-$K8S_USERNAME
kubectl describe nodes | grep -A 5 "Allocated resources"
```

## Cleanup

```bash
kubectl delete -f broken.yaml -n debug-$K8S_USERNAME
```
