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
  description = "Three unique VM IDs and static addresses in CIDR notation."
  type = map(object({
    id      = number
    address = string
  }))
  validation {
    condition     = length(var.nodes) == 3 && length(distinct([for n in values(var.nodes) : n.id])) == 3
    error_message = "Provide exactly three nodes with distinct VM IDs."
  }
}
