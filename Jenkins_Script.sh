#!/bin/bash
set -ex

export TF_VAR_region=$REGION
export TF_VAR_vpc_id=$VPC_ID
export TF_VAR_cluster_name=$CLUSTER_NAME

cd ${WORKSPACE}/DevOps_Project_3/Terraform

terraform init
terraform apply --auto-approve

aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"
kubectl get pods -A

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add eks https://aws.github.io/eks-charts

helm upgrade --install nginx bitnami/nginx

if ! helm list -q | grep -q "^lb-controller$"; then
  helm upgrade --install lb-controller eks/aws-load-balancer-controller --set clusterName="$CLUSTER_NAME"
else
  echo "AWS Load Balancer Controller is already installed"
fi

