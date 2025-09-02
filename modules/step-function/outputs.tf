#################################
# Lambda Outputs
#################################
output "create_namespace_lambda_arn" {
  description = "ARN of the CreateNamespace Lambda function"
  value       = aws_lambda_function.eks_create_namespace_trigger.arn
}

output "deploy_vault_lambda_arn" {
  description = "ARN of the DeployVault Lambda function"
  value       = aws_lambda_function.eks_trigger_vault_deployment.arn
}

#################################
# Step Function Output
#################################
output "step_function_arn" {
  description = "ARN of the Step Function"
  value       = aws_sfn_state_machine.edc_deployment.arn
}

#################################
# CodeBuild Outputs
#################################
output "eks_admin_ops_codebuild_name" {
  description = "Name of the eks-admin-ops CodeBuild project"
  value       = aws_codebuild_project.eks_admin_ops.name
}

output "eks_deploy_vault_codebuild_name" {
  description = "Name of the eks-deploy-vault CodeBuild project"
  value       = aws_codebuild_project.eks_deploy_vault.name
}
