variable "region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be created"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "node_instance_type" {
  default = "t3.medium"  # Ensure it's a compatible instance
}
