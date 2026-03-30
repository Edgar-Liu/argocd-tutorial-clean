# Exercise 05: Failing Readiness & Liveness Probes

## Scenario

The app is deployed and the container is running, but the pod shows `0/1 Ready` and eventually keeps restarting. Traffic never reaches the app.

## Deploy

```bash
kubectl apply -f broken.yaml -n debug-$K8S_USERNAME
```

## Observe

```bash
kubectl get pods -n debug-$K8S_USERNAME -w
```

You should see the pod `Running` but `0/1` Ready, and eventually restarting.

## Your Task

Figure out **why** the pod never becomes Ready and keeps restarting, then fix it.

**Useful commands:**
```bash
kubectl describe pod <POD_NAME> -n debug-$K8S_USERNAME
kubectl logs <POD_NAME> -n debug-$K8S_USERNAME

# Test what endpoints the app responds to (run from inside the cluster)
kubectl run curl-test --rm -it --image=curlimages/curl -n debug-$K8S_USERNAME -- sh
# Then inside the pod, try:
#   curl http://<POD_IP>:3000/
#   curl http://<POD_IP>:3000/health
#   curl http://<POD_IP>:3000/ready
#   curl http://<POD_IP>:3000/healthz
```

**Hint:** Get the pod IP with `kubectl get pod <POD_NAME> -n debug-$K8S_USERNAME -o wide`

## Cleanup

```bash
kubectl delete -f broken.yaml -n debug-$K8S_USERNAME
```
