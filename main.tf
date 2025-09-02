module "vpc" {
  source                = "./modules/vpc"
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  public_subnet_1_cidr  = var.public_subnet_1_cidr
  public_subnet_2_cidr  = var.public_subnet_2_cidr
  public_subnet_3_cidr  = var.public_subnet_3_cidr
  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr
  private_subnet_3_cidr = var.private_subnet_3_cidr
}

module "eks" {
  source           = "./modules/eks"
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  k8s_version      = var.k8s_version
  instance_types   = var.instance_types
  private_subnet_1 = module.vpc.private_subnet_1
  private_subnet_2 = module.vpc.private_subnet_2
  private_subnet_3 = module.vpc.private_subnet_3
  depends_on       = [module.vpc]
}

module "add-ons" {
  source       = "./modules/add-ons"
  cluster_name = module.eks.cluster_name
  depends_on   = [module.eks]
}

module "oidc" {
  source                        = "./modules/oidc"
  environment                   = var.environment
  cluster_name                  = module.eks.cluster_name
  oidc_eks_cluster_provider_url = module.eks.oidc_eks_cluster_provider_url
  depends_on                    = [module.eks]
}

module "alb" {
  source                        = "./modules/alb"
  region                        = var.region
  environment                   = var.environment
  vpc_id                        = module.vpc.vpc_id
  oidc_eks_cluster_provider_url = module.eks.oidc_eks_cluster_provider_url
  cluster_name                  = module.eks.cluster_name
  private_subnet_1              = module.vpc.private_subnet_1
  private_subnet_2              = module.vpc.private_subnet_2
  private_subnet_3              = module.vpc.private_subnet_3
  depends_on                    = [module.oidc, module.eks]
}

module "rds" {
  source           = "./modules/rds"
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  private_subnet_1 = module.vpc.private_subnet_1
  private_subnet_2 = module.vpc.private_subnet_2
  private_subnet_3 = module.vpc.private_subnet_3
  depends_on       = [module.vpc]
}

# module "edcdb" {
#   source           = "./modules/edc-db"
#   environment      = var.environment
#   vpc_id           = module.vpc.vpc_id
#   private_subnet_1 = module.vpc.private_subnet_1
#   private_subnet_2 = module.vpc.private_subnet_2
#   private_subnet_3 = module.vpc.private_subnet_3
#   depends_on       = [module.vpc]
# }

module "bastion" {
  source = "./modules/bastion"
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  public_subnet_1 = module.vpc.public_subnet_1
}


module "deployment_pipeline" {
  source      = "./modules/step-function"
  environment = var.environment
  region      = var.region
  github_token = var.github_token
  depends_on = [module.eks] 
}
