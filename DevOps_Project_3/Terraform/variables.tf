variable "region" {
  description = "AWS region where resources will be deployed"
  default     = ""
}

variable "workstation_external_ip" {
  type    = string
  default = "0.0.0.0/0"
}


variable "cluster_name" {
  description = "Name of the EKS cluster"
  default     = ""
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  default     = "c5.xlarge"
}
