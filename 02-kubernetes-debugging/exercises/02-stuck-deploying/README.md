# Exercise 02: ImagePullBackOff

## Scenario

A deployment was pushed with a new image tag, but pods are stuck and never start.

## Deploy

```bash
kubectl apply -f broken.yaml -n debug-$K8S_USERNAME
```

## Observe

```bash
kubectl get pods -n debug-$K8S_USERNAME -w
```

You should see the pod stuck in `ImagePullBackOff` or `ErrImagePull`.

## Your Task

Figure out **why** the image can't be pulled and fix it.

**Useful commands:**
```bash
kubectl describe pod <POD_NAME> -n debug-$K8S_USERNAME
kubectl get events -n debug-$K8S_USERNAME --sort-by='.lastTimestamp'
```

## Cleanup

```bash
kubectl delete -f broken.yaml -n debug-$K8S_USERNAME
```
