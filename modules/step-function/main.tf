#################################
# IAM for Lambda
#################################
resource "aws_iam_role" "lambda_role" {
  name = "${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

#################################
# Scoped Lambda Logs Policy
#################################
resource "aws_iam_policy" "lambda_logs_policy" {
  name = "${var.environment}-lambda-logs-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "logs:CreateLogGroup",
        Resource = "arn:aws:logs:eu-central-1:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "arn:aws:logs:eu-central-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/eks-create-namespace-trigger:*",
          "arn:aws:logs:eu-central-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/eks-trigger-vault-deployment:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logs_policy.arn
}

#################################
# Scoped Lambda → CodeBuild Policy
#################################
resource "aws_iam_policy" "lambda_codebuild_policy" {
  name = "${var.environment}-lambda-codebuild"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ],
        Resource = [
          "arn:aws:codebuild:eu-central-1:${data.aws_caller_identity.current.account_id}:project/eks-admin-ops",
          "arn:aws:codebuild:eu-central-1:${data.aws_caller_identity.current.account_id}:project/eks-deploy-vault"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_codebuild_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_codebuild_policy.arn
}



#################################
# IAM for CodeBuild
#################################
resource "aws_iam_role" "codebuild_role" {
  name = "${var.environment}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })
}

# Policy for CodeBuild basic logging, S3 artifacts, and reports
resource "aws_iam_policy" "codebuild_base_policy" {
  name = "CodeBuildBasePolicy-eks-deploy-vault-eu-central-1"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Resource = [
          "arn:aws:logs:eu-central-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/eks-admin-ops",
          "arn:aws:logs:eu-central-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/eks-admin-ops:*",
          "arn:aws:logs:eu-central-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/eks-deploy-vault",
          "arn:aws:logs:eu-central-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/eks-deploy-vault:*"
        ],
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
      },
      {
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::codepipeline-eu-central-1-*"
        ],
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ],
        Resource = [
          "arn:aws:codebuild:eu-central-1:${data.aws_caller_identity.current.account_id}:report-group/eks-deploy-vault-*",
          "arn:aws:codebuild:eu-central-1:${data.aws_caller_identity.current.account_id}:report-group/eks-admin-ops-*"
        ]
      }
    ]
  })
}

# Policy for EKS DescribeCluster and STS GetCallerIdentity
resource "aws_iam_policy" "eks_cluster_access_policy" {
  name = "dev-edc-cluster-access-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowDescribeCluster",
        Effect   = "Allow",
        Action   = "eks:DescribeCluster",
        Resource = "arn:aws:eks:eu-central-1:${data.aws_caller_identity.current.account_id}:cluster/dev-edc-cluster"
      },
      {
        Sid      = "AllowGetCallerIdentity",
        Effect   = "Allow",
        Action   = "sts:GetCallerIdentity",
        Resource = "*"
      }
    ]
  })
}

# Attach both custom policies to CodeBuild role
resource "aws_iam_role_policy_attachment" "codebuild_base_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_base_policy.arn
}

resource "aws_iam_role_policy_attachment" "eks_cluster_access_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.eks_cluster_access_policy.arn
}

# Needed to resolve account_id in ARNs
data "aws_caller_identity" "current" {}

#################################
# CodeBuild Projects
#################################
resource "aws_codebuild_project" "eks_admin_ops" {
  name         = "eks-admin-ops"
  service_role = aws_iam_role.codebuild_role.arn

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspecs/eks-admin-ops.yml")
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }
}

resource "aws_codebuild_project" "eks_deploy_vault" {
  name         = "eks-deploy-vault"
  service_role = aws_iam_role.codebuild_role.arn

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspecs/eks-deploy-vault.yml")
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }
}


#################################
# Lambda Packaging
#################################
data "archive_file" "eks_create_namespace_trigger" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src/eks_create_namespace_trigger"
  output_path = "${path.module}/lambda_src/eks_create_namespace_trigger.zip"
}

data "archive_file" "eks_trigger_vault_deployment" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src/eks_trigger_vault_deployment"
  output_path = "${path.module}/lambda_src/eks_trigger_vault_deployment.zip"
}


#################################
# Lambda Functions
#################################
resource "aws_lambda_function" "eks_create_namespace_trigger" {
  function_name = "eks-create-namespace-trigger"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.eks_create_namespace_trigger.output_path
  source_code_hash = data.archive_file.eks_create_namespace_trigger.output_base64sha256

  environment {
    variables = {
      CODEBUILD_PROJECT_NAME = aws_codebuild_project.eks_admin_ops.name
    }
  }
}

resource "aws_lambda_function" "eks_trigger_vault_deployment" {
  function_name = "eks-trigger-vault-deployment"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.eks_trigger_vault_deployment.output_path
  source_code_hash = data.archive_file.eks_trigger_vault_deployment.output_base64sha256

  environment {
    variables = {
      CODEBUILD_PROJECT_NAME = aws_codebuild_project.eks_deploy_vault.name
    }
  }
}

#################################
# Step Function
#################################
resource "aws_iam_role" "sfn_role" {
  name = "${var.environment}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "sfn_lambda_invoke" {
  name = "${var.environment}-sfn-lambda-invoke"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["lambda:InvokeFunction"],
        Resource = [
          "arn:aws:lambda:eu-central-1:${data.aws_caller_identity.current.account_id}:function:eks-trigger-vault-deployment:*",
          "arn:aws:lambda:eu-central-1:${data.aws_caller_identity.current.account_id}:function:eks-create-namespace-trigger:*",
          "arn:aws:lambda:eu-central-1:${data.aws_caller_identity.current.account_id}:function:trigger-tractusx-deploy:*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["lambda:InvokeFunction"],
        Resource = [
          "arn:aws:lambda:eu-central-1:${data.aws_caller_identity.current.account_id}:function:eks-trigger-vault-deployment",
          "arn:aws:lambda:eu-central-1:${data.aws_caller_identity.current.account_id}:function:eks-create-namespace-trigger",
          "arn:aws:lambda:eu-central-1:${data.aws_caller_identity.current.account_id}:function:trigger-tractusx-deploy"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "sfn_xray_policy" {
  name = "${var.environment}-sfn-xray-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ],
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sfn_lambda_attach" {
  role       = aws_iam_role.sfn_role.name
  policy_arn = aws_iam_policy.sfn_lambda_invoke.arn
}

resource "aws_iam_role_policy_attachment" "sfn_xray_attach" {
  role       = aws_iam_role.sfn_role.name
  policy_arn = aws_iam_policy.sfn_xray_policy.arn
}

resource "aws_sfn_state_machine" "edc_deployment" {
  name     = "edc-deployment"
  role_arn = aws_iam_role.sfn_role.arn

  definition = <<EOF
{
  "Comment": "Deploy Namespace and Vault using CodeBuild triggered by Lambda",
  "StartAt": "CreateNamespace",
  "States": {
    "CreateNamespace": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "${aws_lambda_function.eks_create_namespace_trigger.arn}",
        "Payload": {}
      },
      "Next": "DeployVault"
    },
    "DeployVault": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "${aws_lambda_function.eks_trigger_vault_deployment.arn}",
        "Payload": {}
      },
      "End": true
    }
  }
}
EOF
}
