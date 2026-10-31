# Lesson 12 — Security guardrails and software supply chain

**Time:** 3 hours. **Level:** advanced. **Prerequisite:** Lessons 4, 7 and 11; a disposable namespace and the image built in Lesson 11, or an instructor-provided image. Use instructor-pinned scanner versions.

## Objectives and concepts

Apply defense in depth across source, build, artifact, identity and cluster admission. A scan is a point-in-time signal, not proof of safety. Policy should be testable, exceptions should be visible and time-bounded, and credentials should be short-lived and narrowly scoped. The core lab already uses a non-root user, a read-only filesystem, dropped capabilities, resource requests/limits and disabled service-account token automount; this lesson practices enforcing and verifying controls.

## Exercise

1. Create a disposable namespace and enable Kubernetes Pod Security Admission's `restricted` profile:
   ```bash
   kubectl create namespace lesson-12
   kubectl label namespace lesson-12 \
     pod-security.kubernetes.io/enforce=restricted \
     pod-security.kubernetes.io/audit=restricted \
     pod-security.kubernetes.io/warn=restricted
   ```
   Deploy the lesson app in that namespace. Then submit this temporary Pod and verify admission rejects it. Do not weaken the namespace policy to make the test pass:
   ```bash
   kubectl -n lesson-12 apply -f - <<'EOF'
   apiVersion: v1
   kind: Pod
   metadata:
     name: rejected-privileged-test
   spec:
     containers:
       - name: test
         image: busybox:1.36
         command: ["sh", "-c", "sleep 3600"]
         securityContext:
           privileged: true
   EOF
   ```
   The command is expected to fail with an admission denial; no Pod should be created.

2. Add a `ResourceQuota` and `LimitRange` to the namespace. For example, save this as `notes/lesson-12-quota.yaml`, review it, and apply it:
   ```yaml
   apiVersion: v1
   kind: ResourceQuota
   metadata:
     name: tenant-budget
     namespace: lesson-12
   spec:
     hard:
       pods: "10"
       requests.cpu: "1"
       requests.memory: 1Gi
       limits.cpu: "2"
       limits.memory: 2Gi
   ---
   apiVersion: v1
   kind: LimitRange
   metadata:
     name: container-defaults
     namespace: lesson-12
   spec:
     limits:
       - type: Container
         defaultRequest:
           cpu: 50m
           memory: 64Mi
         default:
           cpu: 250m
           memory: 128Mi
   ```
   ```bash
   kubectl apply -f notes/lesson-12-quota.yaml
   kubectl -n lesson-12 describe resourcequota tenant-budget
   ```
   Attempt to create a workload that exceeds a limit and record the admission response. Explain how quota can protect shared capacity but does not replace capacity planning or billing controls.

3. Use an instructor-approved, pinned scanner to scan the application image and source dependencies. Generate an SBOM in a standard format (CycloneDX or SPDX). Record tool/version, image digest, scan date, severity summary and a triage decision. Do not suppress findings silently; document any accepted exception, owner, compensating control and expiry. Do not claim the image is clean merely because the scanner found no known CVEs.

4. Review the CI workflow from Lesson 11. Confirm that:
   - pull requests from forks cannot access publish credentials;
   - the build identity has only the repository/package permissions it needs;
   - build actions and base images are pinned and reviewed;
   - artifacts are tagged immutably, and the deployed digest can be traced to source;
   - secrets are not printed in logs or stored in Git.

   Design the verification step for signed images/provenance using an instructor-approved signing system. In a disposable registry, verify a signed test artifact or document an explicit `design-reviewed` outcome if signing infrastructure is unavailable. Never create or export long-lived signing keys for the exercise.

5. Review the app's RBAC, service-account token behavior and ingress exposure. Add a namespace-scoped NetworkPolicy that limits app ingress to the intended in-namespace path and test it only if the selected CNI enforces NetworkPolicy. Record the CNI limitation if policies are not enforced. Delete the temporary namespace and confirm only lesson-owned resources were removed.

## Acceptance

- Restricted Pod Security Admission rejects a privileged test Pod while the compliant app remains deployable.
- Quota/limit behavior is demonstrated and scan/SBOM evidence names the immutable image digest.
- Workflow credentials and image trust controls are reviewed; exceptions have an owner and expiry.
- The participant distinguishes an enforced policy from an audit/warn-only policy and notes whether the CNI enforces NetworkPolicy.

**Hints:** Start with a fresh namespace so inherited policy does not obscure results. Do not test policy by weakening a shared namespace. A signature proves who signed a digest under a trust policy; it does not prove the software is benign.
