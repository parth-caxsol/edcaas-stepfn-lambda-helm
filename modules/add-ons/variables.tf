variable "cluster_name" {}
variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))
  description = "List of EKS addons to install with their names and versions."
  default = [
    {
      name    = "vpc-cni"
      version = "v1.19.5-eksbuild.1"
    },
    {
      name    = "coredns"
      version = "v1.11.4-eksbuild.2"
    },
    {
      name    = "kube-proxy"
      version = "v1.32.3-eksbuild.7"
    },
    {
      name    = "aws-ebs-csi-driver"
      version = "v1.39.0-eksbuild.1"
    },
    {
      name    = "aws-efs-csi-driver"
      version = "v2.1.6-eksbuild.1"
    },
    {
      name    = "eks-pod-identity-agent"
      version = "v1.3.5-eksbuild.2"
    }
  ]
}