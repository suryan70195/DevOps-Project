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
🔹 providers.tf (AWS Provider Configuration)
hcl
Copy
Edit
provider "aws" {
  region = var.region
}
📌 Terraform will automatically fetch AWS credentials using the default profile or IAM role.

🔹 variables.tf (Terraform Variables)
hcl
Copy
Edit
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
  description = "Instance type for EKS worker nodes"
  type        = string
  default     = "c5.xlarge"
}
📌 Jenkins will pass region, vpc_id, and cluster_name as parameters.

🔹 Jenkins_Script.sh (Jenkins Execution Script)
bash
Copy
Edit
#!/bin/bash
set -ex

# Set Terraform Variables from Jenkins Build Parameters
export TF_VAR_region=$REGION
export TF_VAR_vpc_id=$VPC_ID
export TF_VAR_cluster_name=$CLUSTER_NAME

# Navigate to Terraform Directory
cd ${WORKSPACE}/DevOps_Project_3/Terraform

# Replace `scr_cluster_name` with the actual cluster name
sed -i "s/scr_cluster_name/$CLUSTER_NAME/g" backend.tf

# Verify Backend Update
cat backend.tf | grep "$CLUSTER_NAME" || { echo "Error: backend.tf not updated!"; exit 1; }

# Run Terraform Commands
terraform init -reconfigure
terraform plan
terraform $ACTION --auto-approve

if [ "$ACTION" == "apply" ]; then
    # Login to the EKS Cluster
    aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION
    kubectl get pods -A

    # Add Helm Repos
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add eks https://aws.github.io/eks-charts

    # Install Nginx Only If Not Already Installed
    if ! helm list -q | grep -q "nginx"; then
        helm upgrade --install nginx bitnami/nginx
    else
        echo "Nginx already installed"
    fi

    # Install AWS Load Balancer Controller Only If Not Already Installed
    if ! helm list -q | grep -q "lb-controller"; then
        helm upgrade --install lb-controller eks/aws-load-balancer-controller --set clusterName=$CLUSTER_NAME
    else
        echo "AWS Load Balancer Controller already installed"
    fi
else
    echo "No installation needed"
fi
