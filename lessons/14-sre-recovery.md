# Lesson 14 — SRE, observability and disaster recovery

**Time:** 3 hours. **Level:** advanced. **Prerequisite:** Lessons 8 and 10; monitoring is healthy. An actual restore requires an instructor-provided, separate disposable recovery environment.

## Objectives and concepts

Turn telemetry into service-level objectives, actionable alerts and tested recovery. Distinguish Kubernetes readiness from end-user availability. Define service-level indicators (SLIs), objectives (SLOs), an error budget and recovery point/time objectives (RPO/RTO). A dashboard is not an alerting strategy, and a backup that has never been restored is an unverified recovery path.

## Exercise A — Service objective and incident

1. Define an availability SLI for successful HTTP responses at the ingress and a latency SLI appropriate to the app. State the measurement window, eligible traffic, exclusions and target. For a short lab window, treat the result as a learning sample rather than a statistically meaningful production SLO.

2. Use the existing request metrics to calculate an error ratio and design an alert with a sensible window and minimum traffic condition. For example, in Prometheus evaluate:
   ```promql
   sum(rate(lab_http_requests_total{status="500"}[5m]))
   /
   clamp_min(sum(rate(lab_http_requests_total[5m])), 0.001)
   ```
   Generate both successful and deliberate failing requests using the app's `/` and `/fail` endpoints. Confirm the metric reflects the app, then compare it with a workstation-originated synthetic check of the public app route (HTTP status and an expected response body). Explain why in-cluster probes alone can miss DNS, ingress or external routing failures.

3. In a disposable Git branch, reproduce the Lesson 10 Service-selector fault or another instructor-approved application fault. Record the timeline, user impact, detection signal, evidence, mitigation, Git-based recovery and follow-up action. Avoid changing cluster-wide infrastructure. Confirm the alert can distinguish workload readiness from actual service availability.

4. Review Alertmanager routing and notification ownership. Configure an external receiver only if the instructor supplies a sandbox endpoint. Otherwise document the receiver, escalation path, silence policy and test procedure that would be required; do not send test alerts to real paging systems.

## Exercise B — Backup and restore evidence

5. Define RPO and RTO for (a) cluster control-plane state, (b) application configuration in Git, and (c) persistent application data. Identify the backup location, encryption/access controls, retention, off-site copy and restore owner for each. The lab's local-path storage is not a resilient application-data backup.

6. On the current lab, inspect and record RKE2 snapshot schedule/location and token protection using Lesson 10's safe read-only checks. Do not expose snapshot contents, tokens, kubeconfig or private data. Build a restore checklist with exact version, prerequisites, stop/restore/start sequence and validation steps.

7. If a separate disposable environment is provided, perform a version-matched restore there and verify cluster objects, GitOps reconciliation and the application against the stated RPO/RTO. Otherwise record **runbook-reviewed; restore not performed**. Do not run restore/reset commands against the course cluster.

## Acceptance

- The SLI/SLO has a defined measurement method and limitations; the participant demonstrates an app-level alert and an external synthetic check or documents the missing receiver.
- The incident record includes timeline, impact, evidence, recovery and follow-up without secrets.
- Backup evidence distinguishes inspection, runbook review and an actually completed isolated restore; RPO/RTO are stated and tested where a recovery environment exists.

**Hints:** Use the Lesson 8 metrics and Lesson 10 fault, but do not treat pod readiness as an availability SLI. Check the Prometheus query's sample count and traffic volume before drawing conclusions.
