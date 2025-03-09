#!/bin/bash
set -ex

# Set Terraform Variables from Jenkins Build Parameters
export TF_VAR_region=$REGION
export TF_VAR_vpc_id=$VPC_ID
export TF_VAR_cluster_name=$CLUSTER_NAME

# Navigate to Terraform Directory
cd ${WORKSPACE}/DevOps_Project_3/Terraform

# Replace `scr_cluster_name` with the actual cluster name
sed -i "s/bhuvan_cluster_name/$CLUSTER_NAME/g" backend.tf

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
