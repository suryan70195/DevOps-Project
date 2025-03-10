

terraform {
  backend "s3" {
    bucket = "s3bucket-terraform-helm-statefile"
    key = "eks/mock_cluster_name/statefile"
    region = "us-east-1"
  }
} 
