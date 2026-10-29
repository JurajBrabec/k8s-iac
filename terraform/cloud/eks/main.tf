terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.0.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "eu-west-1"
}
variable "subnet_ids" {
  type        = list(string)
  description = "At least two appropriately configured subnets in different AZs."
}
variable "cluster_role_arn" {
  type        = string
  description = "Existing EKS cluster IAM role ARN with required permissions."
}
variable "node_role_arn" {
  type        = string
  description = "Existing node IAM role ARN with required permissions."
}

resource "aws_eks_cluster" "lab" {
  name     = "eks-k8s-iac-example"
  role_arn = var.cluster_role_arn
  vpc_config {
    subnet_ids = var.subnet_ids
  }
}

resource "aws_eks_node_group" "lab" {
  cluster_name    = aws_eks_cluster.lab.name
  node_group_name = "workers"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  instance_types  = ["t3.medium"]
  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }
}
