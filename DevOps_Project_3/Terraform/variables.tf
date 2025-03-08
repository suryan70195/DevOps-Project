variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = ""
  validation {
    condition     = length(var.region) > 0
    error_message = "Region must not be empty. Example: us-east-1."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where EKS will be deployed"
  type        = string
  default     = ""
  validation {
    condition     = length(var.vpc_id) > 0
    error_message = "VPC ID must not be empty. Example: vpc-12345678."
  }
}   

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "Cluster name must not be empty."
  }
}


variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "c5.xlarge"

  validation {
    condition     = contains(["t3.medium", "t3.large", "c5.xlarge", "m5.large"], var.node_instance_type)
    error_message = "Instance type must be one of: t3.medium, t3.large, c5.xlarge, m5.large."
  }
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication"
  type        = string
  default     = "default"
}

variable "assume_role_arn" {
  description = "IAM role ARN to assume for cross-account access"
  type        = string
  default     = ""
}
