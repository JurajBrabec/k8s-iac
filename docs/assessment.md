# Assessment and instructor guide

Record the participant's evidence without recording tokens, kubeconfigs, private keys or passwords. The five-day core course retains its original rubric: each of Lessons 1–9 earns seven points (4 for working outcome, 2 for verification/evidence and 1 for explanation of tradeoffs); Lesson 10 earns 30 points (10 for structured diagnosis, 10 for identifying and fixing the root cause through Git, and 10 for verification, recovery and a clear incident report). Suggested core pass: 75/100, including at least 15/30 on the capstone. Assess optional Lessons 11–16 using the evidence checklist below; they do not change the core score.

Expected reasoning: Terraform state records managed resources and can contain sensitive data; a plan is not an apply. RKE2 port 9345 registers nodes and 6443 serves the API. A Service selector must match pod labels; a ready pod may exist despite a broken Service. A local-path PVC survives a pod restart but not necessarily a node failure. Helm rollback restores a revision, whereas Argo CD reconciles Git state. Rancher Manager is a management platform, not the RKE2 distribution. Prometheus is metrics-oriented; logs and traces answer different questions. Azure/AWS schema validation does not test cloud credentials or runtime.

For Lesson 10, the supplied fault changes the Service selector in Git to a value no pod matches. Expect empty Service endpoints, failed HTTP requests, the workload-ready alert remaining healthy but a service availability symptom. The participant must restore the correct selector in Git. For Lesson 8, the separate controlled replica reduction triggers the `LabDeploymentUnderReplicated` alert. Do not conflate an endpoint failure with an under-replication alert.

An actual etcd restore is optional and must be conducted only on an isolated disposable cluster. A snapshot listing or a runbook review is not evidence that a restore worked.

## Optional advanced-track evidence

Assess each selected module as **demonstrated**, **design-reviewed**, or **not completed**. Do not award demonstrated status for a plan, screenshot or runbook that was not exercised. Preserve evidence such as sanitized CI results, policy denials, reconciliation status, test results, and reviewed runbooks; never retain credentials, private keys, signed tokens or sensitive state.

- **Lesson 11:** required PR checks reject a failing change; a tested artifact is immutable and deployed by a Git change; promotion and rollback evidence identifies exact revisions.
- **Lesson 12:** a restrictive workload policy rejects a deliberately non-compliant workload; an image/dependency scan and software bill of materials are reviewed; exceptions have an owner and expiry.
- **Lesson 13:** a node maintenance exercise respects a disruption budget and returns capacity; the participant presents a version-matched upgrade and rollback plan without upgrading the shared course cluster.
- **Lesson 14:** an availability objective, indicator and actionable alert are defined; an incident is diagnosed with evidence; backup/restore claims distinguish a rehearsal from a completed isolated restore and record RPO/RTO.
- **Lesson 15:** a production state, access and plan/apply design is reviewed; cloud prerequisites, costs, risks and cleanup are documented; no real cloud deployment is implied by static validation.
- **Lesson 16:** a developer onboarding path has scoped permissions and guardrails; a service/catalog entry and support/ownership model are produced; cost allocation and a budget response are documented.
