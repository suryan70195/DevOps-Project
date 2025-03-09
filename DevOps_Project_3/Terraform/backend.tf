

terraform {
  backend "s3" {
    bucket = "s3buckethelm-terraform-statefile"
    key = "eks/bhuvan_cluster_name/statefile"
    region = "us-east-1"
  }
} 
