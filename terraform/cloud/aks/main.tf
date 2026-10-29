terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.50.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

variable "subscription_id" {
  type        = string
  description = "Placeholder for local validation; a real subscription is needed to deploy."
}
variable "location" {
  type    = string
  default = "westeurope"
}

resource "azurerm_resource_group" "lab" {
  name     = "rg-k8s-iac-example"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "lab" {
  name                = "aks-k8s-iac-example"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  dns_prefix          = "k8siacexample"

  default_node_pool {
    name       = "system"
    node_count = 2
    vm_size    = "Standard_D2s_v5"
  }

  identity {
    type = "SystemAssigned"
  }
}
