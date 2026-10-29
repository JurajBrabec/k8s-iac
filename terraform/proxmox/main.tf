terraform {
  required_version = ">= 1.6.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "= 0.119.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.endpoint
  insecure = var.insecure
  # Authenticate through PROXMOX_VE_API_TOKEN, not a file in Git.
}

resource "proxmox_download_file" "ubuntu" {
  content_type       = "import"
  datastore_id       = var.image_datastore
  node_name          = var.proxmox_node
  file_name          = "k8s-iac-ubuntu-noble-20261017.qcow2"
  url                = "https://cloud-images.ubuntu.com/noble/20261017/noble-server-cloudimg-amd64.img"
  checksum           = "04e8f2461a16a44e78a370284471f29616cdd9baf1893df25807b71f985b6c94"
  checksum_algorithm = "sha256"
  overwrite          = false
}

resource "proxmox_virtual_environment_vm" "node" {
  for_each    = var.nodes
  name        = each.key
  node_name   = var.proxmox_node
  vm_id       = each.value.id
  description = "Disposable Kubernetes IaC training VM"
  tags        = ["k8s-lab", "terraform"]
  boot_order  = ["scsi0"]

  agent {
    enabled = false
  }

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 8192
  }

  disk {
    datastore_id = var.datastore
    import_from  = proxmox_download_file.ubuntu.id
    interface    = "scsi0"
    size         = 40
  }

  operating_system {
    type = "l26"
  }

  network_device {
    bridge = var.bridge
  }

  initialization {
    datastore_id = var.datastore
    dns {
      servers = [var.dns_server]
    }
    ip_config {
      ipv4 {
        address = each.value.address
        gateway = var.gateway
      }
    }
    user_account {
      username = "ubuntu"
      keys     = [trimspace(file(var.ssh_public_key_path))]
    }
  }
}

output "node_addresses" {
  description = "Configured static CIDR addresses; reachability is checked separately."
  value       = { for name, node in var.nodes : name => node.address }
}
