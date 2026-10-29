# Lesson 2 — Terraform and Proxmox

**Time:** 3 hours. **Level:** foundation to intermediate. **Prerequisite:** Lesson 1 and a configured, otherwise clean Proxmox host; no VM template is required.

## Objectives and concepts

Use a provider, variables, resources, state, plan and outputs to create three VMs. A saved plan is a reviewable execution decision, not a substitute for checking ownership. Local state is acceptable only for this single-user, disposable lab; production teams need a secured remote backend with locking, access control and backup.

## Exercise

1. Inspect `terraform/proxmox/main.tf`, `variables.tf` and the example values. The VM map is the desired configuration. Terraform downloads one pinned Ubuntu cloud image to the import-enabled file datastore, checks its checksum and imports it as the boot disk of each new VM; cloud-init configures SSH and networking. Confirm the [instructor prerequisites](../docs/instructor.md), image digest and unused VM IDs.
2. Copy the example and edit all environment-specific values; `.tfvars` is ignored by Git. Set `ssh_public_key_path` to an existing public key on the machine running Terraform; `~/.ssh/id_ed25519.pub` and absolute paths are supported. Verify the file with `test -f ~/.ssh/id_ed25519.pub` or substitute your own path. If you have no key pair, run `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519` and choose a passphrase; do not overwrite an existing key. Use only the `.pub` file here, and keep the private key secure. Authenticate using the instructor-issued token without putting it into shell history:
   ```bash
   cd terraform/proxmox
   cp terraform.tfvars.example terraform.tfvars
   ${EDITOR:-vi} terraform.tfvars
   read -rs -p 'Proxmox API token: ' PROXMOX_VE_API_TOKEN; echo
   export PROXMOX_VE_API_TOKEN
   terraform init
   terraform fmt -check
   terraform validate
   terraform plan -out=lab.tfplan
   ```
   The token format is `user@realm!tokenid=secret`. Use a trusted CA; set `insecure=true` only when explicitly authorized in an isolated lab.
3. Review the saved plan: it should create exactly three assigned VMs and one lab-owned image download, without affecting anything outside the lab. If not, stop. Apply the reviewed plan:
   ```bash
   terraform apply lab.tfplan
   terraform output node_addresses
   terraform plan
   ```
4. Wait for cloud-init and SSH to each VM as `ubuntu`, using the actual addresses. Run `hostname`, `ip -br addr`, `cloud-init status --wait`, `sudo -n true` and `df -h` on each. Check unique hostnames and internet connectivity.
5. Change only the `description` of the VMs in `main.tf`, review the plan, apply it, then run `terraform plan` again. Record how drift would appear if a VM were changed outside Terraform. Commit the safe code change, not the state, plan or variables.

## Acceptance

- Exactly three assigned VMs exist, boot and accept SSH; configured addresses and unique hostnames match.
- A subsequent plan reports no changes, and a reviewed, non-destructive change was applied.
- Explain why state and plan files require protection even if outputs are marked sensitive.

**Hints:** A missing public key must be fixed on the machine running Terraform, not inside a VM. A 403 usually means missing user *or token* ACLs; an image download error can mean missing node-level privileges, no Proxmox host internet access, or Import content not enabled on the image datastore. Verify the downloaded image's checksum and guest cloud-init logs. VM disk growth requires the guest/cloud-init to resize its filesystem. Do not destroy resources until Lesson 10.
