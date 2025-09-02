# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-eks-cluster-role"
    Environment = var.environment
    Terraform   = "true"
  }
}

# Attached required policies to EKS Cluster Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# IAM Role for Node Group
resource "aws_iam_role" "eks_node_role" {
  name = "${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-eks-node-role"
    Environment = var.environment
    Terraform   = "true"
  }
}

# Attached required policies to Node Group Role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_read_only_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_EBS_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# KMS Encryption
resource "aws_kms_key" "eks_kms_key" {
  description             = "KMS key for EKS secrets encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.environment}-eks-kms-key"
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_kms_alias" "eks_secrets_key_alias" {
  name          = "alias/${var.environment}/eks-kms-key"
  target_key_id = aws_kms_key.eks_kms_key.id
}

# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.environment}-eks-cluster-sg"
  description = "EKS cluster control plane security group with full access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all inbound traffic"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.environment}-eks-cluster-sg"
  }
}

# EKS Cluster
resource "aws_eks_cluster" "dev_cluster" {
  name     = "${var.environment}-edc-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids             = [var.private_subnet_1, var.private_subnet_2, var.private_subnet_3]
    endpoint_public_access = true
    security_group_ids     = [aws_security_group.eks_cluster_sg.id]
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks_kms_key.arn
    }
    resources = ["secrets"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_attachment,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller_attachment,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSServicePolicy
  ]

  tags = {
    Name        = "${var.environment}-eks-cluster"
    Environment = var.environment
    Terraform   = "true"
  }
}

# Launch Template for EKS Nodes
resource "aws_launch_template" "eks_launch_template" {
  name = "${var.environment}-eks-node-launch-template"

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    http_endpoint               = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 50
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-eks-node"
      Environment = var.environment
      Terraform   = "true"
    }
  }
}

# EKS Node Group
resource "aws_eks_node_group" "eks_node_group_new" {
  cluster_name    = aws_eks_cluster.dev_cluster.name
  node_group_name = "${var.environment}-eks-node-group-xlarge"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [var.private_subnet_1, var.private_subnet_2, var.private_subnet_3]

  launch_template {
    id      = aws_launch_template.eks_launch_template.id
    version = "$Latest"
  }

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }

  update_config {
    max_unavailable_percentage = 25
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy_attachment,
    aws_iam_role_policy_attachment.eks_cni_policy_attachment,
    aws_iam_role_policy_attachment.eks_container_registry_read_only_attachment,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_EBS_Policy
  ]

  tags = {
    Name        = "${var.environment}-eks-node-group-xlarge"
    Environment = var.environment
    Terraform   = "true"
  }
}