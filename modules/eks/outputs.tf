output "cluster_name" {
  value = aws_eks_cluster.dev_cluster.name
}

output "oidc_eks_cluster_provider_url" {
  value = aws_eks_cluster.dev_cluster.identity[0].oidc[0].issuer
}

output "eks_cluster_certificate_authority" {
  value = aws_eks_cluster.dev_cluster.certificate_authority[0].data
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.dev_cluster.endpoint
}