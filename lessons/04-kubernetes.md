# Lesson 4 — Kubernetes workloads, networking and storage

**Time:** 3 hours. **Level:** intermediate. **Prerequisite:** Lesson 3; `KUBECONFIG` points to the lab.

## Objectives and concepts

Understand Pods, Deployments, Services, readiness, ingress, PVCs and RBAC. A Deployment controls replicas; a Service discovers matching ready endpoints; an ingress controller implements external HTTP routing. Storage lifetime is separate from pod lifetime.

## Exercise

1. Verify context and create the namespace. Change `ingress.host` in `charts/lab-app/values.yaml` to the assigned application FQDN. Render the chart into plain Kubernetes YAML for this lesson, then apply it; Helm does not own it yet:
   ```bash
   kubectl config current-context
   kubectl create namespace lab
   helm template lab-app charts/lab-app -n lab > /tmp/lab-app-rendered.yaml
   kubectl apply -n lab -f /tmp/lab-app-rendered.yaml
   kubectl -n lab rollout status deploy/lab-app --timeout=180s
   kubectl -n lab get pods,svc,ingress
   ```
2. Read the generated Deployment and Service. Identify selectors, resource requests, container security context and probes. Check endpoints and application HTTP:
   ```bash
   kubectl -n lab get endpointslices -l kubernetes.io/service-name=lab-app
   curl -fsS http://<APP_FQDN>/
   kubectl -n lab run dns-test --rm -i --restart=Never --image=busybox:1.36 -- nslookup lab-app.lab.svc.cluster.local
   ```
3. Delete one selected pod and watch the Deployment replace it:
   ```bash
   kubectl -n lab get pods -l app=lab-app
   kubectl -n lab delete pod <ONE_APP_POD>
   kubectl -n lab rollout status deploy/lab-app --timeout=180s
   ```
4. For this isolated lab install local-path-provisioner if the instructor has not supplied an equivalent `local-path` StorageClass. First review the pinned manifest, then apply it:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.37/deploy/local-path-storage.yaml -o /tmp/local-path-storage.yaml
   less /tmp/local-path-storage.yaml
   kubectl apply -f /tmp/local-path-storage.yaml
   kubectl -n local-path-storage rollout status deploy/local-path-provisioner --timeout=180s
   kubectl get storageclass
   ```
   This provisioner stores data on one node and is not resilient storage.
5. Apply `manifests/storage.yaml`. The PVC may remain `Pending` until its pod is scheduled because the StorageClass uses `WaitForFirstConsumer`. Write a marker, delete and recreate the pod, and read it again:
   ```bash
   kubectl apply -f manifests/storage.yaml
   kubectl -n lab wait --for=condition=Ready pod/storage-test --timeout=180s
   kubectl -n lab exec storage-test -- sh -c 'echo persistent-marker > /data/test'
   kubectl -n lab delete pod storage-test --wait=true
   kubectl apply -f manifests/storage.yaml
   kubectl -n lab wait --for=condition=Ready pod/storage-test --timeout=180s
   kubectl -n lab exec storage-test -- cat /data/test
   ```
6. Apply `manifests/rbac.yaml`, then impersonate the service account (the cluster-admin caller must have impersonation permission):
   ```bash
   kubectl apply -f manifests/rbac.yaml
   kubectl auth can-i list pods -n lab --as=system:serviceaccount:lab:lab-reader
   kubectl auth can-i delete pods -n lab --as=system:serviceaccount:lab:lab-reader
   ```
   Expected: `yes`, then `no` (the denied command can return a nonzero exit status). Commit your safe hostname change.

## Acceptance

- Two ready replicas, successful DNS resolution and HTTP 200 through ingress.
- A deleted application pod is replaced; the marker survives storage-pod recreation.
- RBAC returns yes for list and no for delete. Explain why this does not demonstrate node-failure recovery.

**Hints:** Inspect `kubectl -n lab describe pod <pod>`, Service selectors and EndpointSlices. If ingress fails, verify class, controller, DNS and the route from the workstation. Leave resources in place for Lesson 5.
