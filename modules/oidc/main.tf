data "tls_certificate" "oidc_certificate" {
  url = var.oidc_eks_cluster_provider_url
}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc_certificate.certificates[0].sha1_fingerprint]
  url             = var.oidc_eks_cluster_provider_url

  tags = {
    Name        = "${var.cluster_name}-oidc-provider"
    Cluster     = var.cluster_name
    Environment = var.environment
  }
}