# Example Outputs and Logs

Real-world examples of command outputs and logs you'll see during the tutorial.

## Docker Build Output

```bash
$ docker build -t 123456789.dkr.ecr.us-east-1.amazonaws.com/demo-app:a3f5c21 app/

[+] Building 45.2s (10/10) FINISHED
 => [internal] load build definition from Dockerfile                      0.0s
 => => transferring dockerfile: 203B                                      0.0s
 => [internal] load .dockerignore                                         0.0s
 => => transferring context: 89B                                          0.0s
 => [internal] load metadata for docker.io/library/node:18-alpine         1.2s
 => [1/5] FROM docker.io/library/node:18-alpine@sha256:abc123...         15.3s
 => => resolve docker.io/library/node:18-alpine@sha256:abc123...          0.0s
 => => sha256:abc123... 1.65kB / 1.65kB                                   0.0s
 => => sha256:def456... 6.53kB / 6.53kB                                   0.0s
 => => sha256:ghi789... 41.35MB / 41.35MB                                 8.2s
 => => extracting sha256:ghi789...                                        5.1s
 => [internal] load build context                                         0.0s
 => => transferring context: 1.23kB                                       0.0s
 => [2/5] WORKDIR /app                                                    0.3s
 => [3/5] COPY package*.json ./                                           0.0s
 => [4/5] RUN npm install --production                                   25.8s
 => [5/5] COPY server.js ./                                               0.0s
 => exporting to image                                                    2.1s
 => => exporting layers                                                   2.0s
 => => writing image sha256:9a8b7c6d5e4f...                              0.0s
 => => naming to 123456789.dkr.ecr.us-east-1.amazonaws.com/demo-app:...  0.0s
```

## Docker Push Output

```bash
$ docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/demo-app:a3f5c21

The push refers to repository [123456789.dkr.ecr.us-east-1.amazonaws.com/demo-app]
5f70bf18a086: Pushed
d8d1f5b28f42: Pushed
4e2c8b5f3a21: Pushed
9f54eef41275: Pushed
a3f5c21: digest: sha256:1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z size: 1234
```

## Git Commit Output

```bash
$ git add k8s/deployment.yaml
$ git commit -m "chore: update image tag to a3f5c21"

[main b7c8d9e] chore: update image tag to a3f5c21
 1 file changed, 1 insertion(+), 1 deletion(-)

$ git push origin main

Enumerating objects: 7, done.
Counting objects: 100% (7/7), done.
Delta compression using up to 8 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 456 bytes | 456.00 KiB/s, done.
Total 4 (delta 2), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
To github.com:YOUR_USERNAME/argocd-tutorial.git
   a1b2c3d..b7c8d9e  main -> main
```

## ArgoCD Application Status

```bash
$ argocd app get demo-app

Name:               argocd/demo-app
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          demo-app
URL:                https://localhost:8080/applications/demo-app
Repo:               https://github.com/YOUR_USERNAME/argocd-tutorial.git
Target:             main
Path:               k8s
SyncWindow:         Sync Allowed
Sync Policy:        Automated (Prune)
Sync Status:        Synced to main (b7c8d9e)
Health Status:      Healthy

GROUP  KIND        NAMESPACE  NAME      STATUS  HEALTH   HOOK  MESSAGE
       Namespace   demo-app   demo-app  Synced                 namespace/demo-app created
       Service     demo-app   demo-app  Synced  Healthy        service/demo-app created
apps   Deployment  demo-app   demo-app  Synced  Healthy        deployment.apps/demo-app created
```

## ArgoCD Sync Operation

```bash
$ argocd app sync demo-app

TIMESTAMP                  GROUP        KIND         NAMESPACE  NAME      STATUS    HEALTH        HOOK  MESSAGE
2024-01-15T10:30:00+00:00             Namespace    demo-app   demo-app  Running   Synced              namespace/demo-app created
2024-01-15T10:30:00+00:00             Service      demo-app   demo-app  Synced    Healthy             service/demo-app unchanged
2024-01-15T10:30:01+00:00  apps       Deployment   demo-app   demo-app  Synced    Progressing         deployment.apps/demo-app configured
2024-01-15T10:30:15+00:00  apps       Deployment   demo-app   demo-app  Synced    Healthy             deployment.apps/demo-app configured

Name:               argocd/demo-app
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          demo-app
URL:                https://localhost:8080/applications/demo-app
Repo:               https://github.com/YOUR_USERNAME/argocd-tutorial.git
Target:             main
Path:               k8s
SyncWindow:         Sync Allowed
Sync Policy:        Automated (Prune)
Sync Status:        Synced to main (b7c8d9e)
Health Status:      Healthy

Operation:          Sync
Sync Revision:      b7c8d9e1f2a3b4c5d6e7f8g9h0i1j2k3l4m5n6o7
Phase:              Succeeded
Start:              2024-01-15 10:30:00 +0000 UTC
Finished:           2024-01-15 10:30:15 +0000 UTC
Duration:           15s
Message:            successfully synced (all tasks run)

GROUP  KIND        NAMESPACE  NAME      STATUS  HEALTH   HOOK  MESSAGE
       Namespace   demo-app   demo-app  Synced                 namespace/demo-app created
       Service     demo-app   demo-app  Synced  Healthy        service/demo-app unchanged
apps   Deployment  demo-app   demo-app  Synced  Healthy        deployment.apps/demo-app configured
```

## Kubernetes Pod Status

```bash
$ kubectl get pods -n demo-app

NAME                        READY   STATUS    RESTARTS   AGE
demo-app-7d8f9c6b5-k2m4n   1/1     Running   0          2m15s
demo-app-7d8f9c6b5-p7q9r   1/1     Running   0          2m15s
demo-app-7d8f9c6b5-x7z9k   1/1     Running   0          2m15s
```

## Kubernetes Rollout Status

```bash
$ kubectl rollout status deployment/demo-app -n demo-app

Waiting for deployment "demo-app" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "demo-app" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "demo-app" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "demo-app" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "demo-app" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "demo-app" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "demo-app" rollout to finish: 1 old replicas are pending termination...
deployment "demo-app" successfully rolled out
```

## Application Response

```bash
$ curl http://localhost:3000

{
  "message": "Welcome to ArgoCD Tutorial Demo App!",
  "version": "v1.0.0",
  "hostname": "demo-app-7d8f9c6b5-x7z9k",
  "timestamp": "2024-01-15T10:35:42.123Z"
}

$ curl http://localhost:3000/health

{
  "status": "healthy"
}
```

## GitHub Actions Workflow Output

```
Run CI/CD Pipeline
  
✓ Checkout code
  Fetching the repository
  Checking out ref: refs/heads/main
  
✓ Set up Docker Buildx
  Docker Buildx version: v0.11.2
  
✓ Generate image tag
  Image tag: a3f5c21
  
✓ Configure AWS credentials
  Configuring AWS credentials
  
✓ Login to Amazon ECR
  Logging in to Amazon ECR
  Login Succeeded
  
✓ Build and push to ECR
  Building Docker image
  [+] Building 45.2s (10/10) FINISHED
  Pushing image to ECR
  a3f5c21: digest: sha256:1a2b3c4d... size: 1234
  
✓ Update Kubernetes manifest
  Updating k8s/deployment.yaml
  image: 123456789.dkr.ecr.us-east-1.amazonaws.com/demo-app:a3f5c21
  
✓ Commit and push manifest changes
  [main b7c8d9e] chore: update image tag to a3f5c21 [skip ci]
   1 file changed, 1 insertion(+), 1 deletion(-)
  Pushing to github.com/YOUR_USERNAME/argocd-tutorial.git
  
Workflow completed successfully in 2m 34s
```

## ArgoCD Detecting Drift

```bash
$ kubectl scale deployment demo-app -n demo-app --replicas=5
deployment.apps/demo-app scaled

$ argocd app get demo-app

Name:               argocd/demo-app
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          demo-app
URL:                https://localhost:8080/applications/demo-app
Repo:               https://github.com/YOUR_USERNAME/argocd-tutorial.git
Target:             main
Path:               k8s
SyncWindow:         Sync Allowed
Sync Policy:        Automated (Prune, SelfHeal)
Sync Status:        OutOfSync from main (b7c8d9e)
Health Status:      Healthy

GROUP  KIND        NAMESPACE  NAME      STATUS     HEALTH   HOOK  MESSAGE
apps   Deployment  demo-app   demo-app  OutOfSync  Healthy        deployment.apps/demo-app configured

# After a few seconds (selfHeal enabled):

$ kubectl get pods -n demo-app
NAME                        READY   STATUS        RESTARTS   AGE
demo-app-7d8f9c6b5-k2m4n   1/1     Running       0          5m
demo-app-7d8f9c6b5-p7q9r   1/1     Running       0          5m
demo-app-7d8f9c6b5-x7z9k   1/1     Running       0          5m
demo-app-7d8f9c6b5-a1b2c   1/1     Terminating   0          10s
demo-app-7d8f9c6b5-d3e4f   1/1     Terminating   0          10s

# ArgoCD reverted back to 3 replicas (as defined in Git)
```

## ArgoCD Application History

```bash
$ argocd app history demo-app

ID  DATE                           REVISION
0   2024-01-15 09:00:00 +0000 UTC  a1b2c3d (Initial deployment)
1   2024-01-15 10:30:00 +0000 UTC  b7c8d9e (Update image tag to a3f5c21)
2   2024-01-15 11:15:00 +0000 UTC  e4f5g6h (Update welcome message)
3   2024-01-15 12:00:00 +0000 UTC  i7j8k9l (Add health check improvements)
```

## ArgoCD Rollback

```bash
$ argocd app rollback demo-app 1

Rollback application 'demo-app' to revision '1' (b7c8d9e)?
This will deploy the application to the previous state.
Proceed? (y/n): y

TIMESTAMP                  GROUP        KIND         NAMESPACE  NAME      STATUS    HEALTH        HOOK  MESSAGE
2024-01-15T12:05:00+00:00  apps         Deployment   demo-app   demo-app  Synced    Progressing         deployment.apps/demo-app configured
2024-01-15T12:05:15+00:00  apps         Deployment   demo-app   demo-app  Synced    Healthy             deployment.apps/demo-app configured

Application 'demo-app' rolled back to revision '1'
```

## Kubernetes Events

```bash
$ kubectl get events -n demo-app --sort-by='.lastTimestamp' | tail -10

LAST SEEN   TYPE     REASON              OBJECT                           MESSAGE
2m15s       Normal   Scheduled           pod/demo-app-7d8f9c6b5-x7z9k    Successfully assigned demo-app/demo-app-7d8f9c6b5-x7z9k to node-1
2m14s       Normal   Pulling             pod/demo-app-7d8f9c6b5-x7z9k    Pulling image "123456789.dkr.ecr.us-east-1.amazonaws.com/demo-app:a3f5c21"
2m10s       Normal   Pulled              pod/demo-app-7d8f9c6b5-x7z9k    Successfully pulled image
2m10s       Normal   Created             pod/demo-app-7d8f9c6b5-x7z9k    Created container demo-app
2m10s       Normal   Started             pod/demo-app-7d8f9c6b5-x7z9k    Started container demo-app
2m15s       Normal   SuccessfulCreate    replicaset/demo-app-7d8f9c6b5   Created pod: demo-app-7d8f9c6b5-x7z9k
2m15s       Normal   ScalingReplicaSet   deployment/demo-app             Scaled up replica set demo-app-7d8f9c6b5 to 3
```

## Application Logs

```bash
$ kubectl logs -n demo-app -l app=demo-app --tail=20

Server running on port 3000
Version: v1.0.0
GET / 200 15.234 ms - 156
GET /health 200 2.145 ms - 21
GET / 200 12.456 ms - 156
GET / 200 11.789 ms - 156
```

## ArgoCD CLI Login

```bash
$ argocd login localhost:8080

WARNING: server certificate had error: x509: certificate signed by unknown authority. Proceed insecurely (y/n)? y
Username: admin
Password: 
'admin:login' logged in successfully
Context 'localhost:8080' updated
```

## Complete Workflow Timeline

```
T+0:00  Developer commits code change
        └─ git push origin feature/update-message

T+0:05  GitHub Actions triggered
        ├─ Build Docker image
        ├─ Tag: a3f5c21
        └─ Push to ECR

T+0:45  PR created and reviewed
        └─ Merge to main

T+1:00  GitHub Actions (main branch)
        ├─ Build and push image
        ├─ Update k8s/deployment.yaml
        └─ Commit and push

T+1:30  ArgoCD polls repository
        ├─ Detects new commit
        └─ Status: OutOfSync

T+1:31  ArgoCD syncs cluster
        ├─ Apply new deployment
        ├─ Rolling update starts
        └─ Old pods terminate

T+1:45  Deployment complete
        ├─ All pods running
        ├─ Health checks passing
        └─ Status: Synced, Healthy

T+2:00  Verification
        └─ curl http://localhost:3000
            ✓ New version deployed
```
