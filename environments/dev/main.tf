# Development Environment Configuration

# Include global Terraform configuration
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider configuration for dev environment
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

# Local values for this environment
locals {
  environment = "dev"
  name_prefix = "${var.project_name}-${local.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  name               = local.name_prefix
  environment        = local.environment
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id

  # Allow access from company IP ranges
  allowed_cidr_blocks = var.allowed_cidr_blocks

  tags = local.common_tags
}

# RDS Module (only for dev/staging)
module "database" {
  source = "../../modules/rds"

  name        = local.name_prefix
  environment = local.environment

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  engine         = var.database_config.engine
  engine_version = var.database_config.engine_version
  instance_class = var.database_config.instance_class
  storage_size   = var.database_config.storage_size

  database_name = var.database_config.database_name
  username      = var.database_config.username
  password      = var.database_config.password

  allowed_security_groups = [module.security_groups.app_security_group_id]

  # Dev-specific settings
  deletion_protection     = false
  skip_final_snapshot    = true
  backup_retention_period = 1

  tags = local.common_tags
}

# EKS Module (optional for dev)
module "eks" {
  count = var.enable_eks ? 1 : 0
  
  source = "../../modules/eks"

  name        = local.name_prefix
  environment = local.environment

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  control_plane_subnet_ids = module.vpc.public_subnet_ids

  node_groups = var.eks_node_groups

  tags = local.common_tags
}
