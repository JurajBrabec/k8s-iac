# Lesson 15 — Production IaC and cloud operating model

**Time:** 3 hours. **Level:** advanced design and review. **Prerequisite:** Lessons 2 and 9; Terraform CLI and the cloud examples. **No cloud credentials or deployment are required or permitted in this exercise.**

## Objectives and concepts

Move from the local, single-user Terraform state used by this lab toward a team-safe infrastructure workflow. Cover remote state security, locking, backup, access boundaries, environment separation, drift, policy checks, plan review and cloud operating responsibilities. Static validation is not an authenticated plan, and a plan is not authorization to apply.

## Exercise

1. Inspect the Proxmox and cloud Terraform examples. Record provider/version constraints, inputs, outputs, state boundaries and what sensitive data could enter state. Run only local checks (`fmt`, `init -backend=false`, `validate`) as in the core course. Do not authenticate to Azure/AWS/Proxmox or run a cloud `plan` or `apply` for this lesson.

2. Design a production backend for a chosen provider. Specify encryption at rest and in transit, locking/concurrency behavior, versioning/recovery, least-privilege access, audit logging, bootstrap ownership and secret handling. Verify backend locking and recovery capabilities against the selected backend's current documentation; do not assume all backends behave alike. State must be treated as sensitive even when Terraform outputs are marked sensitive.

3. Draw separate development, staging and production state/workspace boundaries. Explain which inputs and modules are shared, how environment-specific values are supplied, how destructive changes are guarded, and how a state migration would be tested and backed up before touching any live state. Do not add credentials or real account identifiers to this repository.

4. Design a CI plan/apply gate: formatting, validation, security/policy checks, saved-plan review, approval by an authorized person, and apply of only the reviewed plan. Include protection for plan/state artifacts, token lifetime, branch rules, drift detection and a documented break-glass process. Identify which checks need cloud authentication and which do not.

5. Complete a cloud readiness matrix for AKS and EKS: account/subscription ownership, network/subnets, identity and workload identity, private API access, node and control-plane responsibility, policy, ingress/DNS/TLS, registry, storage, observability, quotas, support/version lifecycle and cleanup. Use only provider documentation and design; do not provision resources.

6. Estimate a monthly cost model for each design with assumptions and ranges: control plane, compute, disks, load balancers, egress/NAT, logs/metrics, backup and support. Identify owner, budget threshold, alert recipient and cleanup control. Price estimates are time-sensitive; record source and estimate date.

7. Write a short production-readiness review in `notes/lesson-15.md`. Include assumptions, risks, owners, costs, test plan, rollback/recovery path and explicit statements about what static validation has not proven.

## Acceptance

- Backend/state design addresses locking, recovery, access control, encryption and sensitive state.
- CI plan/apply and environment promotion include an approval boundary and prevent applying an unreviewed plan.
- AKS/EKS designs cover identity, network, operations and lifecycle; estimates state assumptions and date.
- No real cloud plan, credential, account identifier or infrastructure change was used as evidence.

**Hints:** Terraform state is not merely a cache; it may contain provider data and secrets. Separate state boundaries reduce blast radius but add operational overhead. Rehearse any migration with a disposable copy and a documented recovery path.
