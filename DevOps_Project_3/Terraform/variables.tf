variable "region" {
  description = "AWS region where resources will be deployed"
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}


variable "workstation_external_ip" {
  type    = string
  default = "0.0.0.0"
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

variable "eks_ami_id" {
  description = "Amazon Linux 2 AMI for EKS nodes"
  default     = "ami-0ec98c2db7d0a924c"
}

