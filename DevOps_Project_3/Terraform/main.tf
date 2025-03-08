# Get the external IP address of the workstation
data "http" "workstation-external-ip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  workstation-external-cidr = coalesce("${chomp(data.http.workstation-external-ip.response_body)}/32", "${var.workstation_external_ip}/32")
}


# Fetch public subnets in the VPC
data "aws_subnets" "subnet_id" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["pub*"]
  }
}

# Output subnet IDs
output "ids" {
  value = data.aws_subnets.subnet_id.ids
}

# Create Security Group for EKS
resource "aws_security_group" "EKS_SG" {
  name        = "${var.cluster_name}-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.workstation-external-cidr]
  }

  egress {
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
resource "aws_iam_role" "cluster_role" {
  name = "${var.cluster_name}-eks-cluster-cluster_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attach EKS Cluster Policy
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

# Create EKS Cluster
variable "eks_version" {
  default = "1.27"
}

resource "aws_eks_cluster" "myeks" {
  name     = var.cluster_name
  role_arn = "arn:aws:iam::954976297955:role/EKS-Cluster-Role"
  version  = "1.27"

  vpc_config {  # This should be inside aws_eks_cluster
    subnet_ids              = data.aws_subnets.subnet_id.ids
    endpoint_private_access = false
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.EKS_SG.id]
  }
}


# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-eks-node-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attach Required Policies for EKS Worker Nodes
resource "aws_iam_role_policy_attachment" "eks_node_role-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_role-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_role-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# Create Launch Template for EKS Node Group with the correct AMI
data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/1.27/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "eks_lt" {
  name          = "eks-launch-template"
  image_id      = data.aws_ssm_parameter.eks_ami.value  # Fetches the latest Amazon Linux 2 AMI
  instance_type = var.node_instance_type

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-node"
    }
  }
}


# Create EKS Node Group
resource "aws_eks_node_group" "mynode_node" {
  cluster_name    = aws_eks_cluster.myeks.name
  node_group_name = "${var.cluster_name}-node"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnets.subnet_id.ids
  instance_types  = [var.node_instance_type]

  ami_type = "AL2_x86_64"  # Amazon Linux 2 for x86_64 architecture

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  # Attach Launch Template with correct AMI
  launch_template {
    id      = aws_launch_template.eks_lt.id
    version = "latest"
  }
}

