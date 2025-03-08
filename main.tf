resource "aws_eks_cluster" "myeks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = data.aws_subnets.subnet_id.ids
    endpoint_private_access = false
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.EKS_SG.id]
  }
}

resource "aws_eks_node_group" "mynode" {
  cluster_name    = aws_eks_cluster.myeks.name
  node_group_name = "${var.cluster_name}-node"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnets.subnet_id.ids
  instance_types  = [var.node_instance_type]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }
}
