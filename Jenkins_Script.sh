#!/bin/bash
set -ex  # Enable debugging and exit on errors

# Set Terraform Variables from Jenkins Build Parameters
export TF_VAR_region=${REGION:-"us-east-1"}
export TF_VAR_vpc_id=${VPC_ID:-""}  # Ensure VPC_ID is set
export TF_VAR_cluster_name=${CLUSTER_NAME:-"mock_cluster_name"}

if [[ -z "$VPC_ID" ]]; then
    echo "ERROR: VPC_ID is not set! Please provide a valid VPC ID."
    exit 1
fi

# Navigate to Terraform Directory
cd ${WORKSPACE}/Terraform

# Ensure backend.tf has the correct cluster name
sed -i "s/mock_cluster_name/$CLUSTER_NAME/g" backend.tf

# Verify Backend Update
if ! grep -q "$CLUSTER_NAME" backend.tf; then
  echo "Error: backend.tf not updated!"
  exit 1
fi

if [[ "$ACTION" != "apply" && "$ACTION" != "destroy" ]]; then
    echo "ERROR: Invalid Terraform action! Use 'apply' or 'destroy'."
    exit 1
fi

# Run Terraform Commands with Health Checks
terraform init -reconfigure || { echo "Terraform Init Failed"; exit 1; }
terraform validate || { echo "Terraform Validation Failed"; exit 1; }
terraform plan || { echo "Terraform Plan Failed"; exit 1; }
terraform $ACTION --auto-approve || { echo "Terraform $ACTION Failed"; exit 1; }

if [ "$ACTION" == "apply" ]; then
    aws sts get-caller-identity || { echo "AWS authentication failed!"; exit 1; }
    # Login to the EKS Cluster
    aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION || { echo "EKS Config Update Failed"; exit 1; }

    # Verify Cluster Health
    kubectl get nodes || { echo "EKS Cluster is not healthy!"; exit 1; }

    # Add Helm Repos
    helm repo add bitnami https://charts.bitnami.com/bitnami || { echo "Failed to add Bitnami repo"; exit 1; }
    helm repo add eks https://aws.github.io/eks-charts || { echo "Failed to add EKS repo"; exit 1; }
    helm repo update || { echo "Helm Repo Update Failed"; exit 1; }

    # Install Nginx Only If Not Already Installed
    if ! helm list -q | grep -wq "nginx"; then
        helm upgrade --install nginx bitnami/nginx || { echo "Nginx Installation Failed"; exit 1; }
    else
        echo "Nginx already installed"
    fi

    # Install AWS Load Balancer Controller Only If Not Already Installed
    if ! helm list -q | grep -wq "lb-controller"; then
        helm upgrade --install lb-controller eks/aws-load-balancer-controller --set clusterName=$CLUSTER_NAME || { echo "AWS Load Balancer Controller Installation Failed"; exit 1; }
    else
        echo "AWS Load Balancer Controller already installed"
    fi

    # Verify Kubernetes Pod Health
    if ! kubectl get pods -A; then
        echo "Kubernetes Pods are not running correctly!"
        exit 1
    fi

else
    echo "No installation needed"
fi

