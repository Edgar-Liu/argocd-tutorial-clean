# Exercise 01: CrashLoopBackOff

## Scenario

Your team deployed a new version of the app, but pods keep restarting.

## Deploy

```bash
kubectl create namespace debug-$K8S_USERNAME
```

```bash
kubectl apply -f broken.yaml -n debug-$K8S_USERNAME
```

## Observe

```bash
kubectl get pods -n debug-$K8S_USERNAME -w
```

You should see the pod cycling through `CrashLoopBackOff`.

## Your Task

Figure out **why** the pod is crashing and fix it.

**Useful commands:**
```bash
kubectl logs <POD_NAME> -n debug-$K8S_USERNAME
kubectl describe pod <POD_NAME> -n debug-$K8S_USERNAME

# Inspect what files are in the container image
docker run --rm $DOCKERHUB_USERNAME/demo-app:v1 ls /app
```

## Cleanup

```bash
kubectl delete -f broken.yaml -n debug-$K8S_USERNAME
```
