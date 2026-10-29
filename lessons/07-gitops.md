# Lesson 7 — GitOps with Argo CD

**Time:** 3 hours. **Level:** advanced. **Prerequisite:** Lesson 5, a publicly readable Git remote with the `training` branch, and network access from the cluster.

## Objectives and concepts

Argo CD reads desired manifests from Git and reconciles the cluster. A `Synced` application matches the selected Git revision; `Healthy` describes resource health. Git review, permissions and branch protection are important controls, not automatic guarantees of GitOps.

## Exercise

1. Commit and push your chart with the correct FQDN to the `training` branch. Verify the remote can be fetched anonymously by HTTPS; otherwise configure Argo CD repository credentials separately using its documentation. Choose an instructor-approved Argo CD version; this example is pinned to `v3.5.6` and must be checked for compatibility:
   ```bash
   git status
   git push origin training
   kubectl create namespace argocd
   kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.6/manifests/install.yaml
   kubectl -n argocd rollout status deploy/argocd-server --timeout=10m
   ```
   `--force-conflicts` is appropriate for this fresh dedicated install and can take field ownership; do not use it blindly on shared resources.
2. Hand off ownership by uninstalling the **lab** Helm release. This briefly interrupts the app, but retains the separate storage exercise:
   ```bash
   helm uninstall lab-app -n lab
   ```
3. Create an Argo CD Application with your actual HTTPS Git URL. The `training` branch is deliberate; change the revision if the instructor uses another branch. It deploys to the same cluster and `lab` namespace:
   ```bash
   export GIT_REPO_URL='https://github.com/<OWNER>/<REPOSITORY>.git'
   cat <<EOF | kubectl apply -f -
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: lab-app
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: ${GIT_REPO_URL}
       targetRevision: training
       path: charts/lab-app
       helm:
         releaseName: lab-app
     destination:
       server: https://kubernetes.default.svc
       namespace: lab
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
   EOF
   kubectl -n argocd get application lab-app -w
   ```
   Stop the watch with Ctrl-C when `Synced`/`Healthy`. The Application uses the powerful default project for a disposable cluster; production should restrict repositories, destinations and RBAC.
4. In a separate terminal, access the UI locally using `kubectl -n argocd port-forward svc/argocd-server 8080:443`. Browse `https://localhost:8080`. Initial credentials and self-signed TLS are described in [Argo CD getting started](https://argo-cd.readthedocs.io/en/stable/getting_started/); change the initial password. Do not expose this port forward beyond localhost.
5. Change `replicaCount` in `values.yaml` from 2 to 3; commit and push. Observe the Git revision and three ready pods. Restore it to 2 with a new commit and push. Automatic reconciliation can take a few minutes.
6. Demonstrate drift: `kubectl -n lab scale deploy/lab-app --replicas=1`, then watch Argo CD restore the Git-defined two replicas. Direct changes are diagnostic only. Do not let Helm and Argo CD concurrently own these resources.

## Acceptance

- Application is `Synced` and `Healthy` at the intended Git revision, and HTTP returns 200.
- A committed change and a direct drift are independently reconciled; two replicas are restored.
- Explain why Git credentials, project scope and automatic pruning need tighter controls in production.

**Hints:** Inspect `kubectl -n argocd describe application lab-app`, repo-server logs and Git branch visibility. A public Git server being reachable from your laptop does not prove that the cluster can reach it.
