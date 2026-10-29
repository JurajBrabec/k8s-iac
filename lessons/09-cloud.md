# Lesson 9 — Managed Kubernetes: Azure AKS and Amazon EKS

**Time:** 3 hours. **Level:** advanced design. **Prerequisite:** Lessons 2–8; internet for provider downloads. **No cloud credentials or accounts are needed.**

## Objectives and concepts

Compare self-managed RKE2 with managed control planes. Azure manages the AKS control plane; Amazon EKS manages the EKS control plane. Customers still configure and operate applications, identities, network policy and much of the surrounding environment. Managed service options change the division of responsibility.

## Exercise

1. Inspect both self-contained example directories under `terraform/cloud/`. The AKS sample creates a resource group and cluster; the EKS sample references **existing** subnet IDs and IAM role ARNs and creates a cluster and managed node group. Neither is production-ready. No real credentials or IDs are required for static validation.
2. From the repository root, initialize providers without a remote backend and validate each configuration:
   ```bash
   terraform -chdir=terraform/cloud/aks init -backend=false
   terraform -chdir=terraform/cloud/aks fmt -check
   terraform -chdir=terraform/cloud/aks validate
   terraform -chdir=terraform/cloud/eks init -backend=false
   terraform -chdir=terraform/cloud/eks fmt -check
   terraform -chdir=terraform/cloud/eks validate
   ```
   Do **not** run `plan`, `apply`, `az login` or AWS authentication for this exercise. `validate` checks syntax and provider schemas, not whether the infrastructure can be created.
3. Draw an AKS and an EKS design for the lab app. For each, identify: control-plane responsibility; node/compute choice; virtual network and private subnets; ingress and external load balancer; DNS and TLS; storage; workload identity; Kubernetes RBAC; image registry; monitoring; and GitOps.
4. Create `notes/lesson-09.md` with a comparison, five anticipated cost categories, and a deployment/rollback/cleanup sequence. Include security and quota prerequisites. For EKS, explain which existing subnet and IAM inputs are missing from the example. For AKS, note that subscription access, networking and policies are not verified.
5. Peer review the design against the instructor's [assessment guide](../docs/assessment.md), or self-review against the list above. Commit the note without secrets or real account identifiers.

## Acceptance

- Both configurations pass `fmt -check` and `validate`; evidence shows no cloud plan or deployment.
- The design addresses all listed components and identifies cloud-specific identities and cost categories.
- Explain at least three things static validation cannot prove: credentials/permissions, quotas/service availability, and runtime connectivity or security.

**Hints:** `init` downloads providers and can fail if registry access is blocked. EKS node roles require appropriate policies and node networking; this example accepts existing roles rather than pretending they are configured. Real deployments incur costs for cluster services, compute, disks, load balancers, networking and logging. Review current vendor pricing and cleanup requirements before using a cloud account.
