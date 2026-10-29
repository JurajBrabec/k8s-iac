# Kubernetes — Infrastructure as Code

An English-language, five-day practical course for one experienced engineer. The participant provisions a Proxmox-based RKE2 cluster, deploys and manages an application, then applies GitOps, observability and troubleshooting practices. Azure AKS and Amazon EKS are covered without deploying cloud resources.

**Start here:** [Instructor setup and safety](docs/instructor.md), then [Lesson 1](lessons/01-foundations.md). All shell commands assume Bash on the Linux workstation, from the repository root unless a lesson says otherwise. The workstation is separate from the lab VMs. Replace every `<PLACEHOLDER>` with the assigned value before running a command; angle brackets are not literal shell syntax. Shell variables such as `KUBECONFIG` need to be set in each new terminal.

| Day | Lesson | Approx. lab time |
|---|---|---:|
| 1 | [1. Linux, Git and DevOps](lessons/01-foundations.md) | 3 h |
| 1 | [2. Terraform and Proxmox](lessons/02-terraform.md) | 3 h |
| 2 | [3. Bootstrap RKE2 with Ansible](lessons/03-rke2.md) | 3 h |
| 2 | [4. Kubernetes workloads](lessons/04-kubernetes.md) | 3 h |
| 3 | [5. Helm](lessons/05-helm.md) | 3 h |
| 3 | [6. Rancher Manager](lessons/06-rancher.md) | 3 h |
| 4 | [7. GitOps and Argo CD](lessons/07-gitops.md) | 3 h |
| 4 | [8. Prometheus and Grafana](lessons/08-observability.md) | 3 h |
| 5 | [9. AKS and EKS](lessons/09-cloud.md) | 3 h |
| 5 | [10. Troubleshooting and recovery](lessons/10-troubleshooting.md) | 3 h |

Each lesson includes objectives, steps, measurable acceptance criteria and hints. Allow additional time for instruction, breaks, downloads and provisioning. [Assessment and answer guide](docs/assessment.md) provides the instructor rubric. [References](docs/references.md) links to upstream documentation.

The infrastructure workflow deliberately separates tools: **Terraform** provisions Proxmox VMs, **Ansible** installs and configures RKE2 over SSH, and **Argo CD** later reconciles Kubernetes application manifests from Git. SSH is Ansible's transport, not a requirement to manually administer each node.

## Lab boundaries

The default design uses one server, two workers, node-local storage and a single Rancher instance. The Terraform lab can select one to three workers and adjust per-VM CPU, memory and boot-disk size within documented bounds. These choices reduce cost and complexity but are **not production HA**, security or disaster-recovery recommendations. Never point the exercises at an existing production cluster, Proxmox pool, Git repository, DNS zone or cloud account. The instructor must establish a tested, compatible version matrix and perform a rehearsal; this repository cannot guarantee compatibility with an arbitrary infrastructure.

Local validation and Helm rendering do not prove that the real Proxmox cluster or Kubernetes workloads work. No cloud account is used; cloud `validate` is not a cloud deployment or authenticated plan.

## Local checks

Without a cluster, run `python3 -m unittest discover -s tests`, `helm lint charts/lab-app`, `helm template lab-app charts/lab-app -n lab`, and `terraform fmt -recursive -check`. Each Terraform directory can also be initialized with `terraform init -backend=false` and checked with `terraform validate`; this downloads the pinned providers but does not deploy resources. Validate the full course on the intended lab environment before delivery.
