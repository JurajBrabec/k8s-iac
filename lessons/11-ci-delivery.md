# Lesson 11 — CI, container delivery and GitOps promotion

**Time:** 3 hours. **Level:** advanced. **Prerequisite:** Lessons 5 and 7; a disposable GitHub repository, a CI runner, and instructor-approved container tooling. A private container registry is optional; do not use a production registry.

## Objectives and concepts

Separate continuous integration (fast, repeatable validation) from delivery (publishing an immutable artifact) and deployment (a reviewed GitOps change). A passing pipeline does not prove a production rollout is safe. CI must use least-privilege permissions, avoid secrets on untrusted pull requests, and identify exactly what source and artifact were tested.

The current sample chart runs Python from a ConfigMap and defaults to the generic `python:3.13-alpine` image. It is intentionally not an image build pipeline. This lab converts the app to a versioned image so participants can practice artifact delivery without changing the existing core-course prerequisites.

## Exercise

1. Create a short-lived feature branch and inspect the existing local tests and chart. Decide which checks are safe to run on an untrusted pull request. Required checks for this repository should include:
   - `python3 -m unittest discover -s tests`;
   - `helm lint charts/lab-app` and a `helm template` render;
   - `terraform fmt -recursive -check`;
   - `terraform init -backend=false` and `terraform validate` for the Proxmox, AKS and EKS examples.

   Do not run `terraform plan` against real infrastructure in CI. Validation needs no cloud credentials. Pin third-party CI actions to reviewed immutable commit SHAs, grant only the workflow permissions it needs, set a concurrency group, and use no secrets for pull-request validation.

2. Add a minimal `Dockerfile` for `charts/lab-app/files/server.py`. Use a reviewed, pinned Python base image (version and digest); copy only the application file; run as a non-root user; expose the app's documented port; and set the container command. Do not copy credentials, repository history or test artifacts into the image. Build and smoke-test locally:
   ```bash
   docker build -t lab-app:lesson-11 charts/lab-app
   docker run --rm -d --name lab-app-test -p 18080:8080 lab-app:lesson-11
   curl -fsS http://127.0.0.1:18080/healthz
   docker stop lab-app-test
   ```
   Confirm the container works without mounting source code. Update the chart Deployment to use the image-contained application rather than mounting the code ConfigMap; remove only the now-unused code checksum/mount/template. Run `helm lint` and `helm template` again.

3. Configure the CI workflow to run the checks from step 1 on pull requests and pushes. Make those checks required for merging. Introduce a deliberate failing test on a temporary branch, confirm the required check blocks it, then remove the failure and confirm a green result. Record workflow permissions and which events can access secrets.

4. On the trusted default branch only, build and publish the image to the disposable registry. Use the source commit SHA as a unique tag and record the registry digest; do not publish `latest` as the deployment reference. Use the CI provider's short-lived identity or narrowly scoped package token. Keep publishing credentials unavailable to forked/untrusted pull requests.

5. Promote the image by committing its immutable digest (or a unique tag plus recorded digest) to the chart values in Git. Let Argo CD deploy it, then verify the exact image reference, ready replicas and HTTP response. Revert the Git change to practice rollback; do not mutate the Deployment directly. Record source commit, image digest, chart revision and deployed Git revision in `notes/lesson-11.md`.

## Acceptance

- A required PR check blocks a failing test and passes after the fix.
- The app runs from a non-root, versioned image and the rendered chart no longer relies on a source-code ConfigMap mount.
- CI publishes only from an approved event, uses least privilege, and identifies the image by immutable digest.
- GitOps deploys and rolls back by Git revision; the evidence ties source, image and deployed revision together.

**Hints:** Use a disposable repository and registry. Confirm the runner architecture matches the cluster nodes. If the registry is private, configure a namespace-scoped pull credential without committing it. A green build is not an image vulnerability assessment; Lesson 12 adds scanning and provenance.
