# Architecture Diagrams

Visual representations of the ArgoCD GitOps workflow.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Developer Workflow                          │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ git push
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │     app/     │  │     k8s/     │  │   argocd/    │             │
│  │  (code)      │  │ (manifests)  │  │   (config)   │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────────────────────────┘
         │                                          ▲
         │ trigger                                  │ poll/webhook
         ▼                                          │
┌─────────────────────────┐              ┌─────────────────────────┐
│   GitHub Actions CI     │              │       ArgoCD            │
│  ┌──────────────────┐   │              │  ┌──────────────────┐   │
│  │ Build Image      │   │              │  │ Application      │   │
│  │ Push to Registry │   │              │  │ Controller       │   │
│  │ Update Manifest  │   │              │  └──────────────────┘   │
│  │ Commit & Push    │───┼──────────────┤  ┌──────────────────┐   │
│  └──────────────────┘   │              │  │ Repo Server      │   │
└─────────────────────────┘              │  └──────────────────┘   │
         │                                │  ┌──────────────────┐   │
         │                                │  │ API Server       │   │
         ▼                                │  └──────────────────┘   │
┌─────────────────────────┐              └─────────────────────────┘
│  Container Registry     │                           │
│  ┌──────────────────┐   │                           │ kubectl apply
│  │  AWS ECR         │   │                           ▼
│  │  or              │   │              ┌─────────────────────────┐
│  │  Docker Hub      │   │              │   Kubernetes Cluster    │
│  └──────────────────┘   │              │  ┌──────────────────┐   │
└─────────────────────────┘              │  │   Namespace      │   │
                                          │  │   demo-app       │   │
                                          │  │  ┌────────────┐  │   │
                                          │  │  │ Deployment │  │   │
                                          │  │  │ Service    │  │   │
                                          │  │  │ Ingress    │  │   │
                                          │  │  └────────────┘  │   │
                                          │  └──────────────────┘   │
                                          └─────────────────────────┘
```

## GitOps Workflow Sequence

```
Developer                 Git                  CI/CD              Registry           ArgoCD            Kubernetes
    │                      │                     │                   │                  │                   │
    │  1. Code Change      │                     │                   │                  │                   │
    ├─────────────────────>│                     │                   │                  │                   │
    │                      │                     │                   │                  │                   │
    │                      │  2. Trigger CI      │                   │                  │                   │
    │                      ├────────────────────>│                   │                  │                   │
    │                      │                     │                   │                  │                   │
    │                      │                     │  3. Build Image   │                  │                   │
    │                      │                     ├──────────────────>│                  │                   │
    │                      │                     │                   │                  │                   │
    │                      │  4. Update Manifest │                   │                  │                   │
    │                      │<────────────────────┤                   │                  │                   │
    │                      │                     │                   │                  │                   │
    │                      │                     │                   │  5. Poll/Webhook │                   │
    │                      │<────────────────────┼───────────────────┼──────────────────┤                   │
    │                      │                     │                   │                  │                   │
    │                      │                     │                   │                  │  6. Compare State │
    │                      │                     │                   │                  ├──────────────────>│
    │                      │                     │                   │                  │                   │
    │                      │                     │                   │                  │  7. Apply Changes │
    │                      │                     │                   │                  ├──────────────────>│
    │                      │                     │                   │                  │                   │
    │                      │                     │                   │  8. Pull Image   │                   │
    │                      │                     │                   │<─────────────────┼───────────────────┤
    │                      │                     │                   │                  │                   │
    │                      │                     │                   │                  │  9. Pods Running  │
    │                      │                     │                   │                  │<──────────────────┤
    │                      │                     │                   │                  │                   │
```

## ArgoCD Reconciliation Loop

```
                    ┌─────────────────────────────────────┐
                    │                                     │
                    │      ArgoCD Reconciliation          │
                    │                                     │
                    └──────────────┬──────────────────────┘
                                   │
                                   │ Every 3 minutes (default)
                                   │
                    ┌──────────────▼──────────────────────┐
                    │                                     │
                    │   1. Fetch from Git Repository      │
                    │      - Clone/Pull latest changes    │
                    │      - Read k8s manifests           │
                    │                                     │
                    └──────────────┬──────────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────────┐
                    │                                     │
                    │   2. Query Kubernetes Cluster       │
                    │      - Get current resource state   │
                    │      - Read all managed resources   │
                    │                                     │
                    └──────────────┬──────────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────────┐
                    │                                     │
                    │   3. Compare States                 │
                    │      - Desired (Git) vs Actual (K8s)│
                    │      - Detect differences           │
                    │                                     │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────┴──────────────────────┐
                    │                                     │
                    ▼                                     ▼
        ┌───────────────────────┐         ┌───────────────────────┐
        │                       │         │                       │
        │   States Match        │         │   States Differ       │
        │   Status: Synced      │         │   Status: OutOfSync   │
        │                       │         │                       │
        └───────────────────────┘         └───────────┬───────────┘
                                                      │
                                                      ▼
                                          ┌───────────────────────┐
                                          │                       │
                                          │  Auto-Sync Enabled?   │
                                          │                       │
                                          └───────┬───────────────┘
                                                  │
                                    ┌─────────────┴─────────────┐
                                    │                           │
                                    ▼                           ▼
                        ┌───────────────────┐     ┌───────────────────┐
                        │                   │     │                   │
                        │   Yes: Apply      │     │   No: Wait for    │
                        │   Changes         │     │   Manual Sync     │
                        │                   │     │                   │
                        └─────────┬─────────┘     └───────────────────┘
                                  │
                                  ▼
                        ┌───────────────────┐
                        │                   │
                        │   4. Sync         │
                        │   - kubectl apply │
                        │   - Update status │
                        │                   │
                        └─────────┬─────────┘
                                  │
                                  ▼
                        ┌───────────────────┐
                        │                   │
                        │   5. Health Check │
                        │   - Verify pods   │
                        │   - Check probes  │
                        │                   │
                        └───────────────────┘
```

## Component Interaction

```
┌────────────────────────────────────────────────────────────────────┐
│                         ArgoCD Components                           │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │                    Application Controller                     │ │
│  │  - Monitors applications                                      │ │
│  │  - Compares desired vs actual state                          │ │
│  │  - Triggers sync operations                                   │ │
│  └────────────────────┬─────────────────────────────────────────┘ │
│                       │                                             │
│                       │ requests                                    │
│                       ▼                                             │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │                      Repo Server                              │ │
│  │  - Clones Git repositories                                    │ │
│  │  - Generates manifests (Helm, Kustomize)                      │ │
│  │  - Caches repository data                                     │ │
│  └────────────────────┬─────────────────────────────────────────┘ │
│                       │                                             │
│                       │ serves manifests                            │
│                       ▼                                             │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │                      API Server                               │ │
│  │  - REST API for UI and CLI                                    │ │
│  │  - Authentication and authorization                           │ │
│  │  - Webhook receiver                                           │ │
│  └────────────────────┬─────────────────────────────────────────┘ │
│                       │                                             │
└───────────────────────┼─────────────────────────────────────────────┘
                        │
                        │ kubectl commands
                        ▼
        ┌───────────────────────────────┐
        │    Kubernetes API Server      │
        └───────────────────────────────┘
```

## Drift Detection and Self-Heal

```
Initial State: Synced
┌─────────────────┐         ┌─────────────────┐
│   Git Repo      │         │   Kubernetes    │
│   replicas: 3   │ ═══════ │   replicas: 3   │
└─────────────────┘         └─────────────────┘

Manual Change Applied
┌─────────────────┐         ┌─────────────────┐
│   Git Repo      │         │   Kubernetes    │
│   replicas: 3   │ ≠≠≠≠≠≠≠ │   replicas: 5   │
└─────────────────┘         └─────────────────┘
                                     │
                                     │ kubectl scale
                                     │ (manual change)
                                     ▼
                            Status: OutOfSync

ArgoCD Detects Drift
                    ┌─────────────────────┐
                    │   ArgoCD detects    │
                    │   difference        │
                    └──────────┬──────────┘
                               │
                ┌──────────────┴──────────────┐
                │                             │
                ▼                             ▼
    ┌───────────────────┐         ┌───────────────────┐
    │  selfHeal: true   │         │  selfHeal: false  │
    │                   │         │                   │
    │  Auto-revert      │         │  Manual action    │
    │  to Git state     │         │  required         │
    └─────────┬─────────┘         └───────────────────┘
              │
              ▼
    ┌───────────────────┐
    │   Kubernetes      │
    │   replicas: 3     │
    │   (reverted)      │
    └───────────────────┘

Final State: Synced
┌─────────────────┐         ┌─────────────────┐
│   Git Repo      │         │   Kubernetes    │
│   replicas: 3   │ ═══════ │   replicas: 3   │
└─────────────────┘         └─────────────────┘
```

## Multi-Environment Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                      Git Repository                             │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │   develop    │  │   staging    │  │     main     │        │
│  │   branch     │  │   branch     │  │   branch     │        │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘        │
└─────────┼──────────────────┼──────────────────┼────────────────┘
          │                  │                  │
          │ monitors         │ monitors         │ monitors
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│  ArgoCD App     │ │  ArgoCD App     │ │  ArgoCD App     │
│  (dev)          │ │  (staging)      │ │  (production)   │
└────────┬────────┘ └────────┬────────┘ └────────┬────────┘
         │                   │                   │
         │ syncs             │ syncs             │ syncs
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│  Namespace      │ │  Namespace      │ │  Namespace      │
│  demo-app-dev   │ │  demo-app-stg   │ │  demo-app-prod  │
│                 │ │                 │ │                 │
│  replicas: 1    │ │  replicas: 2    │ │  replicas: 5    │
│  resources: low │ │  resources: med │ │  resources: high│
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

## Image Update Flow

```
1. Code Commit
   Developer ──> Git Repository
                      │
                      │ triggers
                      ▼
2. CI Pipeline
   ┌─────────────────────────────┐
   │  GitHub Actions             │
   │  ┌───────────────────────┐  │
   │  │ Checkout code         │  │
   │  │ Build Docker image    │  │
   │  │ Tag: git-sha-a3f5c21  │  │
   │  │ Push to registry      │  │
   │  └───────────┬───────────┘  │
   └──────────────┼──────────────┘
                  │
                  ▼
3. Manifest Update
   ┌─────────────────────────────┐
   │  Update k8s/deployment.yaml │
   │  image: registry/app:a3f5c21│
   │  Commit and push            │
   └──────────────┬──────────────┘
                  │
                  ▼
4. ArgoCD Detection
   ┌─────────────────────────────┐
   │  Poll repository            │
   │  Detect new commit          │
   │  Status: OutOfSync          │
   └──────────────┬──────────────┘
                  │
                  ▼
5. Sync Operation
   ┌─────────────────────────────┐
   │  Apply new deployment       │
   │  Rolling update             │
   │  - Create new ReplicaSet    │
   │  - Start new pods           │
   │  - Terminate old pods       │
   └──────────────┬──────────────┘
                  │
                  ▼
6. Verification
   ┌─────────────────────────────┐
   │  Health checks pass         │
   │  Status: Synced, Healthy    │
   │  New version running        │
   └─────────────────────────────┘
```

## Security Flow

```
┌────────────────────────────────────────────────────────────────┐
│                      Security Layers                            │
│                                                                 │
│  1. Git Repository                                              │
│     ├─ Branch protection                                        │
│     ├─ Required reviews                                         │
│     └─ Signed commits                                           │
│                                                                 │
│  2. CI/CD Pipeline                                              │
│     ├─ Secret management (GitHub Secrets)                       │
│     ├─ Image scanning                                           │
│     └─ Vulnerability checks                                     │
│                                                                 │
│  3. Container Registry                                          │
│     ├─ Private repositories                                     │
│     ├─ Image signing                                            │
│     └─ Access control (IAM/RBAC)                                │
│                                                                 │
│  4. ArgoCD                                                      │
│     ├─ SSO integration                                          │
│     ├─ RBAC policies                                            │
│     └─ Audit logging                                            │
│                                                                 │
│  5. Kubernetes                                                  │
│     ├─ Network policies                                         │
│     ├─ Pod security policies                                    │
│     ├─ Resource quotas                                          │
│     └─ Image pull secrets                                       │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

## Rollback Scenario

```
Timeline:
─────────────────────────────────────────────────────────────────

T-0: Version v1.0 (Healthy)
     Git: abc123 ──> ArgoCD ──> K8s: v1.0 ✓

T+5: Deploy v2.0
     Git: def456 ──> ArgoCD ──> K8s: v2.0 (deploying...)

T+10: v2.0 Deployed but has bug
      Git: def456 ──> ArgoCD ──> K8s: v2.0 ✗

T+12: Rollback initiated
      ┌─────────────────────────────────┐
      │  Option 1: ArgoCD Rollback      │
      │  argocd app rollback demo-app 1 │
      └─────────────────────────────────┘
                    │
                    ▼
      ┌─────────────────────────────────┐
      │  Option 2: Git Revert           │
      │  git revert HEAD                │
      │  git push origin main           │
      └─────────────────────────────────┘

T+15: v1.0 Restored
      Git: abc123 ──> ArgoCD ──> K8s: v1.0 ✓
```

These diagrams illustrate the complete ArgoCD GitOps workflow from development to production.
