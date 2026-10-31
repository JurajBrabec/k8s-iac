# Lesson 13 — Kubernetes operations and lifecycle

**Time:** 3 hours. **Level:** advanced. **Prerequisite:** Lessons 3, 4 and 7; a dedicated, disposable cluster with at least two workers. Do not run maintenance exercises on shared or production clusters.

## Objectives and concepts

Operate workloads through planned maintenance, disruption and version change. Understand scheduling, readiness, PodDisruptionBudgets (PDBs), node capacity and version compatibility. A PDB limits voluntary disruptions; it does not protect against node failure, application bugs or a forceful deletion. The course's one-server RKE2 topology is not highly available, so actual control-plane upgrades are runbook-reviewed only.

## Exercise A — Safe worker maintenance

1. Record the current context, nodes, pod placement, available capacity and Argo CD state. Confirm the selected worker is a lab node and that no persistent lab data depends on it. Do not continue if a preflight check is uncertain.

2. Create a PDB for the lab app with `minAvailable: 1`, then confirm two app replicas are ready and distributed such that a voluntary eviction can proceed. For example:
   ```bash
   kubectl -n lab apply -f - <<'EOF'
   apiVersion: policy/v1
   kind: PodDisruptionBudget
   metadata:
     name: lab-app
   spec:
     minAvailable: 1
     selector:
       matchLabels:
         app: lab-app
   EOF
   kubectl -n lab get pods -l app=lab-app -o wide
   kubectl -n lab get pdb lab-app
   ```
   If the scheduler placed both replicas on one worker, correct placement using an instructor-reviewed scheduling constraint or choose a safe maintenance window; do not bypass the PDB.

3. Cordon one worker, drain it using the documented non-forcing options, and observe the PDB and application availability. Substitute the verified disposable worker name:
   ```bash
   kubectl cordon <LAB_WORKER>
   kubectl drain <LAB_WORKER> --ignore-daemonsets --timeout=10m
   kubectl -n lab get pods -l app=lab-app -o wide
   kubectl -n lab get pdb lab-app
   ```
   Do not use `--disable-eviction`, `--force` or a PDB-bypass procedure. Keep the exercise scoped to the disposable worker and account for DaemonSets and any emptyDir data explicitly. If the drain is blocked, stop and investigate rather than forcing it.

4. Verify the app remains reachable, the evicted pod is healthy elsewhere, and Argo CD remains reconciled. Restore schedulability and verify the node returns to `Ready`, then remove the temporary PDB:
   ```bash
   kubectl uncordon <LAB_WORKER>
   kubectl get node <LAB_WORKER>
   kubectl -n lab delete pdb lab-app
   ```
   Record the operation, impact, checks and any blocked eviction in `notes/lesson-13.md`.

## Exercise B — Lifecycle and upgrade plan

5. Using the instructor-approved RKE2/Rancher support matrix and the installed versions, prepare a staged upgrade plan for a **separate HA design**. Include compatibility checks, backups, maintenance order, node drain limits, monitoring, success criteria, rollback/restore decision points and communication. Identify the single-server outage risk in this lab.

6. Review a version-matched upgrade procedure, but do not change RKE2, Rancher, Kubernetes or cluster add-on versions on the course cluster. Explain why an in-place rollback may not be equivalent to restoring the datastore and why add-ons need their own compatibility checks.

7. As a design exercise, propose HPA inputs, resource requests/limits, topology spread, quotas and capacity alerts for the app. Identify which metrics, schedulers and failure-domain assumptions each control depends on. Do not install an autoscaler without an instructor-approved capacity environment.

## Acceptance

- Worker maintenance completes without bypassing the PDB; the workload remains available and the node returns to `Ready`.
- The written upgrade plan is version-matched, includes backup/restore and has explicit stop/rollback criteria.
- The participant explains PDB limits, the lab's control-plane single point of failure, and how scheduling/capacity constraints affect resilience.

**Hints:** Check `kubectl get pdb -A`, `kubectl describe node <worker>`, pod placement and events before draining. If eviction is blocked, stop and diagnose the budget/capacity rather than forcing it. Node-local storage and `emptyDir` require special care.
