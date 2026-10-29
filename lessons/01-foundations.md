# Lesson 1 — Linux, Git and DevOps foundations

**Time:** 3 hours. **Level:** foundation/review. **Prerequisite:** instructor setup and workstation access.

## Objectives and concepts

Verify the environment, use Git for controlled changes, and distinguish imperative commands from declarative desired state. DevOps integrates development and operations through small changes, automation, feedback, shared responsibility and repeatable recovery. IaC encodes infrastructure; GitOps reconciles declared state from a reviewed Git revision.

## Exercise

1. Clone the instructor-provided course repository. Work in the repository root and check identity/branch:
   ```bash
   git status
   git remote -v
   git switch -c training
   uname -a
   free -h
   df -h
   ip route
   ```
2. Verify internet DNS and HTTPS, Proxmox access, and tool versions:
   ```bash
   getent hosts github.com
   curl -I https://github.com
   terraform version
   helm version
   kubectl version --client
   ssh -V
   ```
   Check the assigned Proxmox endpoint with a browser or `curl` using the trusted lab CA. Do not send API tokens to untrusted endpoints.
3. Inspect a workstation service and its journal, for example `systemctl status ssh` and `journalctl -u ssh -n 30`. Service names vary by distribution; use an existing service if necessary.
4. Create `notes/lesson-01.md` with the environment summary, current branch and two risks of manual provisioning. Never include addresses that policy prohibits publishing, credentials or command history. Commit the file and push your branch:
   ```bash
   mkdir -p notes
   ${EDITOR:-vi} notes/lesson-01.md
   git add notes/lesson-01.md
   git commit -m "Document lab readiness"
   git push -u origin training
   ```
5. Explain the difference between state, desired state and observed state. Identify a review/approval point before infrastructure changes.

## Acceptance

- Tools report versions; DNS, Git and Proxmox endpoint are reachable.
- The branch and environment note exist in the remote repository; no credentials are committed.
- You can explain an idempotent operation and why changing a VM manually creates drift.

**Hints:** Use `ip route get <address>` for routing and `journalctl --since '10 minutes ago'` for recent failures. Check system clock and proxy settings if TLS fails. Keep this branch for Lessons 2–10.
