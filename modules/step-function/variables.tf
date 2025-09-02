variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "edc"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, stage, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "github_token" {
  description = "GitHub token for accessing private repositories"
  type        = string
  sensitive   = true
}
