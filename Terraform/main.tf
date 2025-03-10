terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Fetch External IP of Workstation
data "http" "workstation-external-ip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  workstation_external_cidr = "${chomp(data.http.workstation-external-ip.response_body)}/32"
}

# Define Subnets Manually (Exclude us-east-1e)
locals {
  selected_subnets = [
    "subnet-0f5bb343af9cdd447",  # us-east-1b 
    "subnet-068a6fd375f265e2d",  # us-east-1a 
    "subnet-003edcdbf20b75d6b",  # us-east-1f 
    "subnet-0869ccf0b089dd509",  # us-east-1d 
    "subnet-082800bf7e3e0c211"   # us-east-1c 
  ]
}

# Output Selected Subnets
output "subnet_ids" {
  value = local.selected_subnets
}

# Security Group for EKS Cluster
resource "aws_security_group" "eks_sg" {
  name        = "${var.cluster_name}-sg"
  description = "Security group for ${var.cluster_name} EKS cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow inbound traffic from workstation"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.workstation_external_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-sg"
  }
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Cluster Definition
resource "aws_eks_cluster" "myeks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.27"

  vpc_config {
    subnet_ids              = local.selected_subnets
    endpoint_private_access = false
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_sg.id]
  }
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.myeks.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = local.selected_subnets

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = ["t3.medium"]
}
