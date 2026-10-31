# Lesson 16 — Platform engineering and FinOps

**Time:** 3 hours. **Level:** advanced design and lab. **Prerequisite:** Lessons 7, 11, 12 and 15; a disposable cluster and Git branch. Cluster-admin actions must remain inside the assigned lab.

## Objectives and concepts

Treat the platform as an internal product for developer teams: provide a paved path, self-service within guardrails, clear ownership and support, and feedback-driven improvement. A namespace or portal by itself is not a platform. Include cost visibility and capacity limits while recognizing that Kubernetes quotas do not directly meter or charge usage.

## Exercise A — Tenant onboarding path

1. Choose a fictional service team and define its onboarding contract: owner/on-call contact, repository, data classification, SLO, support tier, requested capacity, network dependencies, secrets mechanism and decommission date. Do not use personal or production data.

2. In a disposable namespace, implement a small tenant baseline: restricted Pod Security Admission, ResourceQuota, LimitRange, a namespace-scoped service account/RBAC role, and a NetworkPolicy if the lab CNI enforces it. Create a test workload and verify both an allowed action and a denied privileged/unscoped action. Document which controls are enforced by Kubernetes and which are process-only.

3. Define a golden path for a service using the existing chart and GitOps workflow: repository structure, required CI checks, image provenance, standard health probes/resources, ownership metadata, deployment promotion, rollback and operational dashboard. The golden path should make the safe route easier without preventing justified, reviewed exceptions.

4. Review Argo CD project and RBAC scope. Design a team-specific project limited to approved repositories, destinations and namespaces; identify who can sync, edit configuration and administer the platform. Do not grant the tenant Argo CD admin or cluster-admin. If the disposable installation cannot safely support the exercise, produce a reviewed configuration rather than applying a broad project.

## Exercise B — Platform product and cost model

5. Create a service-catalog entry (for example `notes/service-catalog-entry.md`) with service purpose, owner, repository, runtime, dependencies, data class, SLO, dashboard, alerts, runbooks, backup class, support channel and lifecycle status. State who maintains each platform component and how a developer requests help or proposes a paved-road change.

6. Make a lightweight cost/capacity model for the service: requested and observed CPU/memory, replicas, storage, network egress, shared platform overhead and expected growth. Define useful allocation labels and explain how costs would be attributed in a cloud environment. Set a hypothetical budget/capacity threshold, an owner, an alert action and a process for reviewing an exception. Do not imply that labels, requests or ResourceQuota alone provide accurate billing.

7. Ask a peer to follow the onboarding steps without verbal help. Record where they got stuck, improve one step, and define a feedback loop for future platform improvements. Clean up the temporary namespace only after preserving non-sensitive evidence.

## Acceptance

- A tenant can deploy a compliant test workload within scoped access and capacity limits; an unauthorized action is denied.
- The golden path and catalog entry identify ownership, SLO, security, operations and decommissioning responsibilities.
- The participant distinguishes platform guardrails from application-team ownership and Kubernetes quotas from chargeback.
- A peer-review improvement and a cost/capacity action with an accountable owner are recorded.

**Hints:** Prefer a small number of understandable defaults over a large catalog of options. Make the exception path explicit and auditable. Avoid building a portal before the underlying workflow and ownership model are clear.
