output "eks_cluster_id" {
  value = aws_eks_cluster.myeks.id
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.myeks.endpoint
}

output "eks_cluster_version" {
  value = aws_eks_cluster.myeks.version
}
