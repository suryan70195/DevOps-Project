variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  type = string
}

variable "cluster_name" {
  type    = string
  default = "eks-cluster-dev"
}
