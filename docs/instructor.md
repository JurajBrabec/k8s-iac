# Instructor preparation and safety

## Environment and inputs

Provision a separate Linux workstation with Bash, Git, SSH, curl, jq, Terraform >= 1.6, a pinned/rehearsed Ansible Core version (>= 2.13 for `systemd_service`), Helm 3, kubectl (within Kubernetes version skew), openssl, a browser and Python 3. Commands are Linux/Bash, not PowerShell. It needs internet and network access to the Proxmox API and all lab VMs. It must remain available between lessons. Prepare a public Git repository writable by the participant and readable by the cluster; a private repository requires separately configuring Argo CD credentials. Do not put lab credentials in Git.

Provide a Proxmox VE 9 lab node, an isolated bridge/VLAN with internet egress, storage for two to four VM disks, unique free VM IDs and reserved static IPv4 addresses with gateway and DNS for one server plus one to three workers. Defaults are **4 vCPU, 8 GiB RAM and 40 GB boot disk per VM** (three VMs by default: 12 vCPU, 24 GiB RAM and 120 GB nominal disk), plus host/workstation overhead. At the maximum worker count, provision capacity for four VMs (16 vCPU, 32 GiB RAM, 160 GB nominal disk). Minimum per-VM settings are 1 vCPU, 4 GiB RAM and 20 GB disk; these reduce host load but may not run the full Rancher and monitoring lessons reliably. SSD storage is recommended for etcd. No VM template is required: Terraform downloads a pinned official Ubuntu 24.04 amd64 cloud image to Proxmox, checks its SHA-256 digest and imports it into a new disk per VM. Cloud-init configures networking and the `ubuntu` user's SSH key. Verify the digest against Ubuntu's signed published checksums before use, and regularly review/update the pinned image and digest together.

The Proxmox host, not just the workstation or VMs, must resolve and reach `cloud-images.ubuntu.com` over HTTPS. Configure a **file-based** image datastore (often `local`) with `Import` content enabled at Datacenter > Storage; VM disks and cloud-init can use a separate datastore such as `local-lvm`. Proxmox configuration, network, storage and ACLs remain prerequisites even on a clean installation. The image is a Terraform-managed resource and is deleted during an authorized destroy; do not point it at a shared file. No existing unmanaged file with the same lab-specific filename will be overwritten.

Give the participant an API token with tested privileges to create, start, read, modify and delete the three lab VMs, use the VM storage and bridge, and download the image. The provider documents `Datastore.AllocateTemplate`, `Sys.Audit` and `Sys.Modify` for the download API; node-level `Sys.Modify` is broader than VM-only privileges. Assess the risk and grant these only on the dedicated lab host/storage, or have an administrator perform the download separately and adapt Terraform ownership. Proxmox ACLs and token privilege separation both apply. Verify access before the course; do not solve permission issues by granting unrestricted production access. TLS verification is on by default; install the Proxmox CA in the workstation trust store. The example allows an explicit lab-only insecure override.

Prepare an environment sheet with: Proxmox URL, node, VM datastore, image datastore, bridge, CPU model, VM sizing, worker count, VM IDs, server/worker addresses and prefix, gateway, DNS server, SSH public key path, Git HTTPS clone/push URLs, and Rancher/app FQDNs. Define a VM ID and unique static address for the server and each of up to three workers in `nodes`; `worker_count` selects how many of the lexicographically sorted worker names are active. DNS for both names should resolve to a reachable ingress endpoint. Use a private lab zone and restrict access; alternatively configure workstation hosts entries. Do not use real domains or expose management services to the public internet.

## Versions and network

Before delivery, choose and record exact, mutually compatible RKE2, Rancher and Kubernetes versions using the current Rancher support matrix. Export `RKE2_VERSION` on each node for installation. Choose an ingress controller supported by that Rancher release, install it, set a default IngressClass, and make its HTTP/HTTPS listeners reachable from the workstation. RKE2 ingress defaults differ by release; ingress-nginx is end-of-life. The labs do **not** assume a particular default controller. Verify Rancher TLS and ingress before teaching.

Choose and record exact compatible versions for Rancher Helm chart, cert-manager if needed, kube-prometheus-stack, local-path-provisioner and Argo CD. Example released versions for Argo CD and local-path-provisioner appear in lessons; instructor must verify compatibility and update as a coordinated set. Terraform provider versions are declared in code. Pin container images/chart versions and review supply-chain security before delivery. The network must allow DNS, package/image/chart downloads and Git. Allow node-to-node traffic required by the chosen CNI and RKE2; see the RKE2 requirements. In particular 6443/TCP is the API and 9345/TCP is RKE2 registration. Never expose overlay ports publicly.

For the default Lesson 6 (`lessons/06-rancher.md`), select and rehearse a cert-manager chart version compatible with the chosen Rancher release. This lesson uses Rancher-generated self-signed certificates (`ingress.tls.source=rancher`), so no externally supplied TLS certificate, private key, or CA bundle is needed. Warn participants that their browser may report the generated CA as untrusted; explain how to trust the CA in a controlled lab and never to bypass validation in production. The custom-secret variant (`lessons/06-rancher-tls.md`) does not require cert-manager.

For the custom TLS variant, generate a certificate and private key for the Rancher FQDN, plus the signing CA certificate, and install the CA certificate on the browser workstation. Run these commands in Bash; they store all files under `$HOME/certs`, outside the repository. The CA private key must remain protected and must never be committed. The server certificate must include a DNS SAN matching the Rancher FQDN. The lesson uses `ingress.tls.source=secret`; no cert-manager is needed for this path.

```sh
umask 077
mkdir -p "$HOME/certs"
chmod 700 "$HOME/certs"
export RANCHER_FQDN='rancher.lab.example'

# Create a local CA
openssl genrsa -out "$HOME/certs/ca.key" 3072
openssl req -x509 -new -key "$HOME/certs/ca.key" -sha256 -days 365 \
  -out "$HOME/certs/ca.crt" -subj "/CN=Lab-CA" \
  -addext 'basicConstraints=critical,CA:TRUE' \
  -addext 'keyUsage=critical,keyCertSign,cRLSign' \
  -addext 'subjectKeyIdentifier=hash'

# Create server key and CSR
openssl genrsa -out "$HOME/certs/tls.key" 2048
openssl req -new -key "$HOME/certs/tls.key" \
  -out "$HOME/certs/tls.csr" -subj "/CN=${RANCHER_FQDN}"

# Add the hostname SAN and server-certificate extensions
cat > "$HOME/certs/server.ext" <<EOF
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:${RANCHER_FQDN}
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
EOF

# Sign the server certificate with your local CA
openssl x509 -req -in "$HOME/certs/tls.csr" \
  -CA "$HOME/certs/ca.crt" -CAkey "$HOME/certs/ca.key" -CAcreateserial \
  -out "$HOME/certs/tls.crt" -days 365 -sha256 \
  -extfile "$HOME/certs/server.ext"
```

## Rehearsal and setup

1. Copy the repository into a writable Git remote, confirm no secrets, and clone it on the workstation. Configure the image storage, addresses, credentials and DNS described above.
2. Fill in `terraform/proxmox/terraform.tfvars` from the example. Place token only in `PROXMOX_VE_API_TOKEN` environment variable. Verify all IDs are free and addresses do not overlap host, pod or service networks.
3. Execute Lessons 1–10 sequentially on disposable infrastructure. Record actual versions, permissions, time and resource consumption. Verify a fresh clone can fetch the GitOps branch and that `app.lab.example` resolves to the ingress.
4. Confirm the selected StorageClass works. Lesson 4 offers pinned local-path-provisioner as an isolated-lab fallback. It stores data on one node and cannot survive that node's loss; delete policy may erase data. Never use as a production resilience demonstration.
5. Seed the participant's Git repository with the course kit. Ensure the tracked branch used by Argo CD is writable by the participant and can be fetched by Argo CD. Confirm the fault exercise and alert transitions. Prepare a disposable separate environment for optional restore practice.

## Optional advanced-track preparation

Lessons 11–16 are an extension and are not prerequisites for the five-day core course. Before teaching them:

- Provide a disposable GitHub repository with pull-request checks and branch protection available. Review CI action pinning and permissions; do not make secrets available to untrusted pull-request code.
- If teaching image publishing, provide a disposable registry/repository and a narrowly scoped package-publish identity. Confirm the lab cluster can pull the image. Never use a production registry or long-lived personal token.
- Pin and rehearse the container builder, vulnerability scanner and SBOM tooling. Decide whether image signing/provenance can be demonstrated or is a design-only outcome.
- Reserve a dedicated disposable cluster with at least two workers for the Lesson 13 drain exercise. Confirm workload placement, PDB behavior, CNI NetworkPolicy support and node-local data implications first. Do not use shared infrastructure.
- Provide a separate version-matched recovery environment before asking participants to perform an actual restore. Otherwise mark the exercise runbook-reviewed only.
- Do not issue Azure/AWS credentials for Lesson 15. It is a design and static-review exercise; no cloud plan or deployment is part of the track.

Rehearse the extension end to end and record tool versions, runner/registry permissions, expected costs and cleanup. Delete only lesson-owned registry artifacts and namespaces, revoke temporary identities, and preserve no credentials in evidence.

## Cleanup

Lessons 1–9 retain state for subsequent exercises. Lesson 10 includes scoped cleanup. Before any destructive command verify the Kubernetes context, namespace, Terraform workspace, resource IDs, and review `terraform plan -destroy`. Save any required evidence/backups first. Deleting a PVC may delete its backing data. Remove secrets and lab CA keys securely and revoke API tokens after the course. Never run cleanup on shared/production resources.
