# Lesson 5 — Helm packaging and releases

**Time:** 3 hours. **Level:** intermediate. **Prerequisite:** Lesson 4; application FQDN is set in `charts/lab-app/values.yaml`.

## Objectives and concepts

Understand a chart, release, templates and values. Helm renders templates into Kubernetes objects and stores release history in the cluster. Chart values and release metadata are not a safe place for plaintext production secrets.

## Exercise

1. Inspect `Chart.yaml`, `values.yaml`, templates and the Python application. Identify how the Service selects Pods and how a ConfigMap code change restarts the Deployment.
2. Lint and render before making a change:
   ```bash
   helm lint charts/lab-app
   helm template lab-app charts/lab-app -n lab > /tmp/lab-app-rendered.yaml
   less /tmp/lab-app-rendered.yaml
   ```
3. Transfer ownership from the plain manifests. This briefly interrupts the application; only delete the known objects in the lab namespace, not the namespace or PVC:
   ```bash
   kubectl -n lab delete -f /tmp/lab-app-rendered.yaml
   helm install lab-app charts/lab-app -n lab --wait --timeout 5m
   helm list -n lab
   kubectl -n lab rollout status deploy/lab-app --timeout=180s
   curl -fsS http://<APP_FQDN>/
   ```
4. Change `message` in `values.yaml`, then upgrade and observe the response:
   ```bash
   helm upgrade lab-app charts/lab-app -n lab --wait --timeout 5m
   helm history lab-app -n lab
   curl -fsS http://<APP_FQDN>/
   ```
5. Roll back to revision 1 and verify the original message. Then revert the uncommitted `message` edit manually so the Git values match the rolled-back release. Keep your correct FQDN.
   ```bash
   helm rollback lab-app 1 -n lab --wait
   helm history lab-app -n lab
   curl -fsS http://<APP_FQDN>/
   ```
6. Commit any intended FQDN configuration and push the training branch. Before Lesson 7, record that Argo CD will own the application resources; it does not operate a Helm release when rendering a chart.

## Acceptance

- `helm lint` succeeds; install, upgrade and rollback are visible in release history.
- The response changes on upgrade and returns to the original message on rollback.
- Explain why the values file must again match the desired Git state before GitOps handoff.

**Hints:** `helm get values lab-app -n lab` and `helm get manifest lab-app -n lab` show release state. If ownership conflicts occur, confirm the prior plain objects were removed and no other release manages them.
