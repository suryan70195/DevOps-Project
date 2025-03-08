variable "region" {
  description = "AWS region where resources will be deployed"
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

variable "eks_version" {
  description = "Version of EKS cluster"
  default     = "1.27"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "my-eks-cluster"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  default     = "c5.xlarge"
}

