
terraform {
  backend "s3" {
    bucket = "chandu-terraform-statefile"
    key = "eks/chandu_cluster_name/statefile"
    region = "us-east-1"
  }
} 
