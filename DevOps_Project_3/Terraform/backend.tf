

terraform {
  backend "s3" {
    bucket = "bhuvan-terraform-statefile"
    key = "eks/scr_cluster_name/statefile"
    region = "us-east-1"
  }
} 
