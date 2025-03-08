data "http" "workstation-external-ip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.response_body)}/32"
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
  }
}

output "subnet_ids" {
  value = data.aws_subnets.selected.ids
}

resource "aws_security_group" "EKS_SG" {
  name        = "${var.cluster_name}-sg"
  description = "${var.cluster_name}-sg"
  vpc_id      = var.vpc_id

  ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [local.workstation-external-cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-sg"
  }
}

resource "aws_eks_cluster" "myeks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster_role.arn
  version  = "1.24"

  vpc_config {
    subnet_ids              = data.aws_subnets.selected.ids
    endpoint_private_access = false
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.EKS_SG.id]
  }
}

resource "aws_eks_node_group" "mynode_node" {
  cluster_name    = aws_eks_cluster.myeks.name
  node_group_name = "${var.cluster_name}-node"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids = [
    "subnet-0f5bb343af9cdd447", # us-east-1b
    "subnet-068a6fd375f265e2d", # us-east-1a
    "subnet-003edcdbf20b75d6b", # us-east-1f
    "subnet-0869ccf0b089dd509", # us-east-1d
    "subnet-082800bf7e3e0c211"  # us-east-1c
  ]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = [var.node_instance_type]
}

