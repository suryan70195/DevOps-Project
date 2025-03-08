terraform {
  backend "s3" {
    bucket = "chandu-terraform-statefile"
    key    = "eks/${var.cluster_name}/statefile"  # 🔹 Dynamically store state per cluster
    region = "us-east-1"
  }
}

