# Lesson 10 — Troubleshooting and recovery capstone

**Time:** 3 hours. **Level:** advanced. **Prerequisite:** Lessons 7–8; dedicated lab cluster and Git branch.

## Objectives and concepts

Diagnose from symptoms and evidence, not guesses. Follow the request path: DNS → ingress → Service → EndpointSlice → ready Pods → container. Check Git and reconciliation before changing managed resources. Recovery includes validation and a written explanation, not merely making the symptom disappear.

## Exercise A — Endpoint failure

1. Record the healthy baseline:
   ```bash
   kubectl config current-context
   kubectl -n argocd get application lab-app
   kubectl -n lab get deploy,svc,pods,ingress
   kubectl -n lab get endpointslices -l kubernetes.io/service-name=lab-app
   curl -fsS http://<APP_FQDN>/
   ```
2. **Controlled fault:** In `charts/lab-app/values.yaml`, change `serviceSelector: lab-app` to `serviceSelector: wrong-app`; commit and push. Wait until Argo CD shows `Synced`. This intentionally breaks the lab application's Service, not the cluster or Rancher.
3. Diagnose without immediately undoing the change. Inspect ingress and Service, EndpointSlices, pod labels, events and logs. Which layer is healthy? Which selector or label does not match? Record the evidence and root cause in `notes/lesson-10.md`.
   ```bash
   kubectl -n lab describe svc lab-app
   kubectl -n lab get pods --show-labels
   kubectl -n lab get endpointslices -l kubernetes.io/service-name=lab-app
   kubectl -n lab get events --sort-by=.lastTimestamp
   kubectl -n argocd get application lab-app -o yaml
   ```
   The exact external status (e.g. 503 or 404) depends on the ingress controller. The provided under-replication alert is not expected to fire for a selector mismatch.
4. Correct the selector to `lab-app` in Git, commit and push. Wait for `Synced` and `Healthy`, inspect ready endpoints, and verify HTTP 200. Add the fix commit and verification to the incident note. Discuss how an availability alert or black-box probe would detect this fault.

## Exercise B — Backups and recovery

5. On the server, inspect the RKE2 snapshot schedule and list snapshots using the [RKE2 backup and restore documentation](https://docs.rke2.io/datastore/backup_restore):
   ```bash
   sudo rke2 etcd-snapshot ls
   sudo ls -l /var/lib/rancher/rke2/server/db/snapshots
   ```
   Record where snapshots and the server token are stored and how they would be protected and copied off-node. A snapshot on the same VM is not an independent backup. Treat both snapshot and token as sensitive.
6. If the instructor provides a **separate disposable** recovery environment, follow the version-matched upstream restore procedure there, including required token and stopping/restarting services, then verify the restored data and application. Otherwise review the procedure and explicitly mark the exercise **runbook-reviewed, restore not performed**. Do not execute restore or reset commands on the course cluster.

## Exercise C — Authorized cleanup

7. Preserve evidence first. Only with instructor authorization, verify context, review the impact and remove the lab application and resources. Deleting a PVC may delete its data; confirm retention requirements before doing so. Stop any port-forwards. Review the VM destroy plan from the original directory before applying it:
   ```bash
   cd terraform/proxmox
   terraform workspace show
   terraform plan -destroy -out=destroy.tfplan
   terraform show destroy.tfplan
   # Only after explicit authorization and confirmation that every target is a lab VM or the lab-owned image:
   terraform apply destroy.tfplan
   ```
   Destroying the VMs also destroys their node-local data, and Terraform deletes the managed downloaded image; do not apply if any resource outside the assigned lab is listed. Instructor then revokes credentials and cleans up the dedicated Git repository, DNS and other lab-only resources as appropriate.

## Acceptance

- Incident note includes symptom, evidence, root cause, Git fix and successful HTTP/endpoints verification.
- Argo CD reports `Synced`/`Healthy`; the application has two ready replicas and responds successfully.
- Backup and restore status is honestly recorded; cleanup is reviewed and executed only if authorized.

**Hints:** If Argo does not sync, check `repo-server` and the tracked branch. A ready Deployment alone does not prove a Service has endpoints. Use `kubectl describe` for conditions and events; compare labels literally.
