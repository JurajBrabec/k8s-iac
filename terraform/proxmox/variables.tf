variable "endpoint" {
  type        = string
  description = "Proxmox HTTPS API URL, e.g. https://pve.example:8006/"
}
variable "insecure" {
  type        = bool
  description = "Skip TLS validation only in a controlled lab."
  default     = false
}
variable "proxmox_node" {
  type = string
}
variable "datastore" {
  type = string
}
variable "cpu_type" {
  type        = string
  description = "QEMU CPU model exposed to the guest. qemu64 is a compatibility baseline; use a newer model only if the Proxmox host supports its features."
  default     = "qemu64"
}
variable "cpu_cores" {
  type        = number
  description = "Number of vCPU cores assigned to each VM (1-4)."
  default     = 4
  validation {
    condition     = var.cpu_cores >= 1 && var.cpu_cores <= 4 && floor(var.cpu_cores) == var.cpu_cores
    error_message = "cpu_cores must be a whole number from 1 through 4."
  }
}
variable "memory_gib" {
  type        = number
  description = "VM memory in GiB (4-8)."
  default     = 8
  validation {
    condition     = var.memory_gib >= 4 && var.memory_gib <= 8 && floor(var.memory_gib) == var.memory_gib
    error_message = "memory_gib must be a whole number from 4 through 8."
  }
}
variable "disk_gb" {
  type        = number
  description = "VM boot disk size in decimal GB as presented by Proxmox (20-40)."
  default     = 40
  validation {
    condition     = var.disk_gb >= 20 && var.disk_gb <= 40 && floor(var.disk_gb) == var.disk_gb
    error_message = "disk_gb must be a whole number from 20 through 40."
  }
}
variable "worker_count" {
  type        = number
  description = "Number of worker VMs to provision (1-3), in addition to the server VM."
  default     = 2
  validation {
    condition     = var.worker_count >= 1 && var.worker_count <= 3 && floor(var.worker_count) == var.worker_count
    error_message = "worker_count must be a whole number from 1 through 3."
  }
}
variable "image_datastore" {
  type        = string
  description = "File-based Proxmox datastore with Import content enabled for the downloaded cloud image."
}
variable "bridge" {
  type = string
}
variable "gateway" {
  type = string
}
variable "dns_server" {
  type = string
}
variable "ssh_public_key_path" {
  type = string
}
variable "nodes" {
  description = "VM IDs and static addresses for lab-server and one to three lab-worker entries. All worker entries must be defined even if worker_count selects fewer of them."
  type = map(object({
    id      = number
    address = string
  }))
  validation {
    condition = (
      length(var.nodes) >= 2 &&
      length(var.nodes) <= 4 &&
      contains(keys(var.nodes), "lab-server") &&
      length(distinct([for n in values(var.nodes) : n.id])) == length(var.nodes) &&
      alltrue([for name in keys(var.nodes) : name == "lab-server" || startswith(name, "lab-worker")])
    )
    error_message = "Provide lab-server and one to three lab-worker entries, with unique VM IDs."
  }
}
